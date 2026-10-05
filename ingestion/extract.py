"""
Ingestion: Postgres snapshot -> Parquet raw layer (bronze).

- Reads every base table in the ref, game and intake schemas over a read-only transaction
  (server-side cursor, streamed in batches, so memory stays flat on the 5 GB events table).
- intake.events is partitioned by the date of received_at (the intake's own UTC clock), NOT
  event_ts, because shard clocks are not trusted until they are validated in staging.
- Data lands exactly as delivered: no dedup, no fixes. jsonb bodies are kept as raw JSON text.
  Cleanup happens in staging.
- Writes data/raw/_manifest.json with source vs landed row counts for reconciliation and
  exits non-zero if any table does not reconcile.

Usage:  python ingestion/extract.py   (env: PGHOST PGPORT PGUSER PGPASSWORD PGDATABASE)
"""
import json
import os
import shutil
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

import psycopg
import pyarrow as pa
import pyarrow.parquet as pq
from psycopg.types.string import TextLoader

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
SCHEMAS = ["ref", "game", "intake"]
BATCH = 100_000
PARTITIONED = {("intake", "events"): "received_at"}

# Postgres type -> Arrow type. Anything not listed is landed as text (lossless, typed in staging).
PG_TO_ARROW = {
    "text": pa.string(), "character varying": pa.string(), "character": pa.string(),
    "integer": pa.int32(), "smallint": pa.int16(), "bigint": pa.int64(),
    "numeric": pa.decimal128(38, 10), "double precision": pa.float64(), "real": pa.float32(),
    "boolean": pa.bool_(), "date": pa.date32(),
    "timestamp with time zone": pa.timestamp("us", tz="UTC"),
    "timestamp without time zone": pa.timestamp("us"),
    "jsonb": pa.string(), "json": pa.string(), "uuid": pa.string(), "inet": pa.string(),
}


def connect():
    conn = psycopg.connect(
        host=os.getenv("PGHOST", "localhost"), port=os.getenv("PGPORT", "5432"),
        user=os.getenv("PGUSER", "candidate"), password=os.getenv("PGPASSWORD", "candidate"),
        dbname=os.getenv("PGDATABASE", "eternal_realms"),
    )
    conn.read_only = True
    # Keep JSON, inet etc. as raw text: we land what was delivered, parsing happens downstream.
    for t in ("json", "jsonb", "inet", "cidr", "uuid"):
        conn.adapters.register_loader(t, TextLoader)
    conn.execute("SET TIME ZONE 'UTC'")
    return conn


def table_columns(conn, schema, table):
    rows = conn.execute(
        """SELECT column_name, data_type FROM information_schema.columns
           WHERE table_schema = %s AND table_name = %s ORDER BY ordinal_position""",
        (schema, table)).fetchall()
    cols, fields = [], []
    for name, dtype in rows:
        cols.append(f'"{name}"' if dtype in PG_TO_ARROW else f'"{name}"::text')
        fields.append(pa.field(name, PG_TO_ARROW.get(dtype, pa.string())))
    return cols, pa.schema(fields)


def to_batch(rows, schema):
    arrays = []
    for i, field in enumerate(schema):
        values = [r[i] for r in rows]
        if pa.types.is_string(field.type):
            values = [None if v is None else str(v) for v in values]
        arrays.append(pa.array(values, type=field.type))
    return pa.RecordBatch.from_arrays(arrays, schema=schema)


def extract_table(conn, schema, table):
    cols, arrow_schema = table_columns(conn, schema, table)
    part_col = PARTITIONED.get((schema, table))
    order = ' ORDER BY "event_id"' if part_col else ""
    sql = f'SELECT {", ".join(cols)} FROM "{schema}"."{table}"{order}'

    if part_col:
        target = RAW / schema / table
        if target.exists():
            shutil.rmtree(target)
        target.mkdir(parents=True)
        part_idx = arrow_schema.get_field_index(part_col)
    else:
        target = RAW / schema / f"{table}.parquet"
        target.parent.mkdir(parents=True, exist_ok=True)

    writers = {}

    def writer_for(key):
        if key not in writers:
            if part_col:
                d = target / f"received_date={key}"
                d.mkdir(parents=True, exist_ok=True)
                path = d / "part-0.parquet"
            else:
                path = target
            writers[key] = pq.ParquetWriter(path, arrow_schema, compression="zstd")
        return writers[key]

    read = 0
    with conn.cursor(name=f"cur_{schema}_{table}") as cur:
        cur.itersize = BATCH
        cur.execute(sql)
        while rows := cur.fetchmany(BATCH):
            if part_col:
                groups = {}
                for r in rows:
                    ts = r[part_idx]
                    key = ts.astimezone(timezone.utc).date().isoformat() if ts else "unknown"
                    groups.setdefault(key, []).append(r)
                for key, grp in groups.items():
                    writer_for(key).write_batch(to_batch(grp, arrow_schema))
            else:
                writer_for("all").write_batch(to_batch(rows, arrow_schema))
            read += len(rows)
            if part_col:
                print(f"    ... {read:,} rows", flush=True)

    if not part_col and not writers:  # empty table: still land a file carrying the schema
        writer_for("all")
    for w in writers.values():
        w.close()

    # Count from the files actually written, so reconciliation checks what is on disk.
    files = list(target.rglob("*.parquet")) if part_col else [target]
    return sum(pq.ParquetFile(f).metadata.num_rows for f in files)


def main():
    RAW.mkdir(parents=True, exist_ok=True)
    manifest = {"extracted_at": datetime.now(timezone.utc).isoformat(), "tables": {}}
    with connect() as conn:
        tables = conn.execute(
            """SELECT table_schema, table_name FROM information_schema.tables
               WHERE table_schema = ANY(%s) AND table_type = 'BASE TABLE'
               ORDER BY array_position(%s::text[], table_schema::text), table_name""",
            (SCHEMAS, SCHEMAS)).fetchall()
        if not tables:
            sys.exit("No tables found. Is the container running, and is PGPORT the right port?")

        for schema, table in tables:
            t0 = time.time()
            src_rows = conn.execute(f'SELECT count(*) FROM "{schema}"."{table}"').fetchone()[0]
            landed = extract_table(conn, schema, table)
            ok = landed == src_rows
            secs = round(time.time() - t0, 1)
            manifest["tables"][f"{schema}.{table}"] = {
                "source_rows": src_rows, "landed_rows": landed, "reconciled": ok, "seconds": secs}
            print(f"{'OK      ' if ok else 'MISMATCH'} {schema}.{table:<28} "
                  f"{src_rows:>12,} -> {landed:>12,}  ({secs}s)", flush=True)

    (RAW / "_manifest.json").write_text(json.dumps(manifest, indent=2))
    bad = [k for k, v in manifest["tables"].items() if not v["reconciled"]]
    print("\nAll tables reconciled." if not bad else f"\nRECONCILIATION FAILED: {bad}")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
