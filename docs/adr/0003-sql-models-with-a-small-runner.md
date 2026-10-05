# ADR 0003: Transformations are plain SQL files run by a small runner

**Status:** accepted

## Context
The warehouse needs layered, documented, reproducible transformations. dbt is the industry standard for this.

## Decision
Each model is one SQL file in `transform/models/<NN_layer>/<NN_name>.sql` that defines one table. A 60-line
runner (`transform/run.py`) executes them in folder and file order and rebuilds the warehouse from scratch.
The folder name gives the schema (`01_staging` -> `staging`).

## Alternatives considered
* **dbt (dbt-duckdb):** gives tests, docs and a lineage graph, but adds a framework, profiles and Jinja to learn
  and explain within a one-week time box.

## Consequences
* Anyone who reads SQL can follow the pipeline; the order is visible in the file names.
* The models are already one-table-per-file `SELECT`s, so moving to dbt later is mechanical (replace table
  names with `ref()`), and is the first recommended step towards production.
* Data tests currently live in the `dq` schema and the reconciliation checks, not in a test framework.
