"""
Exports the star schema (schema `marts`) and the cheat tables to Parquet files that Power BI can load,
one file per table, in data/powerbi/.

Power BI cannot read a DuckDB file directly, but it reads Parquet natively (Get Data > Parquet).
List columns are turned into comma-separated text and timestamps are written as plain UTC date-times,
because Power BI does not support list columns or time-zone-aware timestamps in Parquet.

Usage:  python reports/export_for_powerbi.py      (run after python transform/run.py)
"""
from pathlib import Path
import duckdb

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "powerbi"
TABLES = [("marts", t) for t in (
    "dim_date", "dim_character", "dim_character_level", "dim_zone", "dim_item_template", "dim_creature",
    "fct_sessions", "fct_encounter_participation", "fct_creature_kills", "fct_deaths", "fct_xp", "fct_loot",
    "fct_gold_ledger", "fct_economy_transactions", "fct_character_gear", "fct_subzone_activity",
)] + [("cheats", "cheat_violations"), ("cheats", "cheat_offenders"), ("cheats", "cheat_rule_results")]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    con = duckdb.connect(str(ROOT / "data" / "warehouse" / "eternal_realms.duckdb"), read_only=True)
    con.execute("SET TimeZone = 'UTC'")
    for schema, table in TABLES:
        cols = con.execute(
            "SELECT column_name, data_type FROM information_schema.columns "
            "WHERE table_schema = ? AND table_name = ? ORDER BY ordinal_position", [schema, table]).fetchall()
        select = []
        for name, dtype in cols:
            if dtype.endswith("[]"):
                select.append(f'array_to_string("{name}", \', \') AS "{name}"')
            elif dtype == "TIMESTAMP WITH TIME ZONE":
                select.append(f'CAST("{name}" AS TIMESTAMP) AS "{name}"')   # UTC wall-clock time
            elif dtype.startswith("DECIMAL"):
                select.append(f'CAST("{name}" AS DOUBLE) AS "{name}"')
            elif dtype in ("HUGEINT", "INT128"):
                select.append(f'CAST("{name}" AS BIGINT) AS "{name}"')
            else:
                select.append(f'"{name}"')
        target = (OUT / f"{table}.parquet").as_posix()
        con.execute(f'COPY (SELECT {", ".join(select)} FROM {schema}.{table}) TO \'{target}\' (FORMAT parquet)')
        rows = con.execute(f"SELECT count(*) FROM read_parquet('{target}')").fetchone()[0]
        print(f"{schema}.{table:<30} {rows:>10,} rows -> data/powerbi/{table}.parquet")
    print(f"\nDone. In Power BI: Get Data > Parquet, or Get Data > Folder on {OUT}")


if __name__ == "__main__":
    main()
