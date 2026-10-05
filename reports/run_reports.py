"""
Runs every report query in reports/sql against the warehouse and saves each result as a CSV in
reports/output, to demonstrate that the data model supports every report in the brief.

Usage:  python reports/run_reports.py
"""
from pathlib import Path
import duckdb

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
OUT = HERE / "output"


def main():
    OUT.mkdir(exist_ok=True)
    con = duckdb.connect(str(ROOT / "data" / "warehouse" / "eternal_realms.duckdb"), read_only=True)
    con.execute("SET TimeZone = 'UTC'")
    for f in sorted((HERE / "sql").glob("*.sql")):
        sql = f.read_text(encoding="utf-8").strip().rstrip(";")
        target = (OUT / f"{f.stem}.csv").as_posix()
        con.execute(f"COPY ({sql}\n) TO '{target}' (HEADER, DELIMITER ',')")
        rows = con.execute(f"SELECT count(*) FROM read_csv('{target}')").fetchone()[0]
        print(f"{f.stem:<32} {rows:>7,} rows -> reports/output/{f.stem}.csv")


if __name__ == "__main__":
    main()
