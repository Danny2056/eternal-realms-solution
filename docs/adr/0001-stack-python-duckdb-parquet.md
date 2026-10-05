# ADR 0001: Stack is Python, Parquet and DuckDB

**Status:** accepted

## Context
The source is a 5 GB, read-only Postgres snapshot (9.65 million events). The whole solution must run on a
laptop, be demonstrated live, and be built within one week. The brief leaves the stack open.

## Decision
* **Python** for ingestion and orchestration (small scripts, no framework).
* **Parquet** files as the raw layer (`data/raw`).
* **DuckDB** as the analytical warehouse (one file, `data/warehouse/eternal_realms.duckdb`), with transformations
  written in plain SQL.

## Alternatives considered
* **A second Postgres as the warehouse:** familiar, but row-oriented and slower for analytical scans; adds a
  server to run and tune.
* **Spark / Databricks:** built for far larger data; heavy to install and slow to iterate locally.
* **Cloud warehouse (BigQuery, Snowflake, Redshift):** needs accounts, credentials and cost; harder to hand over
  and demo offline.

## Consequences
* Whole pipeline installs with `pip install -r requirements.txt` and rebuilds in about 5 minutes on a laptop.
* Parquet + SQL map directly to production services (S3 + Athena / Redshift / Snowflake), see the AWS design.
* DuckDB is single-writer: fine for a batch pipeline, not for concurrent writers (not needed here).
