# ADR 0004: Data quality is fixed in staging, measured, and never hides the original

**Status:** accepted

## Context
Seven kinds of data problems were found (duplicates, lost events, a shard clock 5 hours off, missing fields,
placeholder IDs, corrupted integers, impossible levels). Cheat detection is only credible on clean data, but
every accusation must trace back to what was actually delivered.

## Decision
* All fixes happen in one place, `staging.stg_events`, and every fix keeps the original value next to the
  repaired one (`event_ts_raw`, `<field>_raw`, `delivery_count`, `ts_corrected`, `numeric_repair`).
* The clock correction is stored as data (`staging.stg_clock_corrections`), not hard-coded logic.
* Unrecoverable values become NULL; nothing is guessed.
* Every problem is measured in `dq.dq_summary`, and lost events are listed in `dq.dq_shard_seq_gaps`.

## Consequences
* Reports and cheat rules share one definition of "clean".
* A reviewer can see, for any row, what was changed and why.
* Rules must tolerate NULLs and lost events; they do (see ADR 0005).
