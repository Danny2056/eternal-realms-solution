# ADR 0002: Ingestion is a full, reconciled extract to Parquet, partitioned by received date

**Status:** accepted

## Context
The snapshot is fixed and read-only. Events can be duplicated, lost and mis-timestamped (see data-quality
findings), so the raw layer must be an exact, auditable copy.

## Decision
* Extract every base table of the `ref`, `game` and `intake` schemas in full, through a read-only connection,
  streamed in 100,000-row batches (`ingestion/extract.py`).
* Land data **as delivered**: no deduplication, no type fixes, JSON bodies kept as text.
* Partition events by the date of `received_at` (the intake's own clock), not `event_ts` (the shard clocks,
  which proved unreliable).
* After each table, count rows in the source and in the written files; write `_manifest.json` and fail the run
  on any mismatch.

## Alternatives considered
* **Incremental load on `event_id`:** the natural choice in production (see AWS design), unnecessary for a
  one-off snapshot.
* **Cleaning during ingestion:** loses the original values and breaks the evidence trail.
* **DuckDB's Postgres extension:** simpler code, but downloads a plugin at runtime, which failed in a locked-down
  network during development. `psycopg` + `pyarrow` install with pip and have no runtime downloads.

## Consequences
* Result: 9,650,208 events and all reference/state tables landed and reconciled in about 5.5 minutes.
* Any cleaning rule can be re-run or reversed without touching the source.
