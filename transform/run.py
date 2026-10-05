"""
Transform runner: builds the DuckDB warehouse from the raw Parquet layer.

Every model is a plain SQL file in transform/models/<layer>/NN_name.sql that creates one table.
Files run in folder order, then file-name order, so dependencies are expressed by numbering.
The warehouse is rebuilt from scratch on every run (idempotent, about a minute on a laptop).

Usage:  python transform/run.py            (all layers)
        python transform/run.py staging    (only folders whose name contains "staging")
"""
import os
import sys
import time
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
WAREHOUSE = ROOT / "data" / "warehouse" / "eternal_realms.duckdb"
MODELS = Path(__file__).resolve().parent / "models"


def register_sources(con):
    """Expose the raw Parquet files as views in schema raw_* (nothing is copied)."""
    for schema in ("ref", "game"):
        con.execute(f"CREATE SCHEMA IF NOT EXISTS raw_{schema}")
        for f in sorted((RAW / schema).glob("*.parquet")):
            con.execute(f"CREATE OR REPLACE VIEW raw_{schema}.{f.stem} AS "
                        f"SELECT * FROM read_parquet('{f.as_posix()}')")
    con.execute("CREATE SCHEMA IF NOT EXISTS raw_intake")
    con.execute(f"""CREATE OR REPLACE VIEW raw_intake.events AS
        SELECT * EXCLUDE (received_date)
        FROM read_parquet('{(RAW / 'intake' / 'events' / '**' / '*.parquet').as_posix()}', hive_partitioning = true)""")


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else ""
    WAREHOUSE.parent.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(WAREHOUSE))
    con.execute("SET TimeZone = 'UTC'")
    # Keep memory use modest on a laptop: spill large sorts/joins to disk instead of failing,
    # and do not spend memory preserving row order (no model depends on it).
    tmp = WAREHOUSE.parent / "tmp"
    tmp.mkdir(exist_ok=True)
    con.execute(f"SET temp_directory = '{tmp.as_posix()}'")
    con.execute("SET preserve_insertion_order = false")
    # Default 2 GB works on an 8 GB laptop with Docker running; raise it with DUCKDB_MEMORY_LIMIT=4GB for speed.
    con.execute(f"SET memory_limit = '{os.getenv('DUCKDB_MEMORY_LIMIT', '2GB')}'")
    register_sources(con)
    # Shared repair rule for corrupted integers (DQ-6), used by staging models.
    con.execute("""CREATE OR REPLACE MACRO repair_int(v) AS
        CASE WHEN v < 0 THEN -v - 1 WHEN v >= 2147483648 THEN NULL ELSE v END""")

    files = [f for d in sorted(MODELS.iterdir()) if d.is_dir() and only in d.name
             for f in sorted(d.glob("*.sql"))]
    total = time.time()
    for f in files:
        schema = f.parent.name.split("_", 1)[1]          # 01_staging -> staging
        table = f.stem.split("_", 1)[1]                   # 03_stg_events -> stg_events
        sql = f.read_text(encoding="utf-8").strip().rstrip(";")
        t0 = time.time()
        con.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
        con.execute(f"CREATE OR REPLACE TABLE {schema}.{table} AS\n{sql}")
        rows = con.execute(f"SELECT count(*) FROM {schema}.{table}").fetchone()[0]
        print(f"built {schema}.{table:<34} {rows:>12,} rows  ({time.time()-t0:.1f}s)", flush=True)
    print(f"\nDone: {len(files)} models in {time.time()-total:.1f}s -> {WAREHOUSE}")


if __name__ == "__main__":
    main()
