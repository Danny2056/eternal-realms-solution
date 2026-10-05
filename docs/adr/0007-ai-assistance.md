# ADR 0007: How AI assistance was used

**Status:** accepted

## Context
The brief expects AI assistance and asks for it to be documented.

## Decision
An AI assistant (Claude) was used as a pair-programming teammate for:
* reading the brief, rulebook and data dictionary and turning rules into checks;
* writing and testing the ingestion script, the SQL models and the report queries;
* profiling the data and investigating anomalies interactively;
* drafting the documentation, including the plain-English explanations.

Every finding was checked against the data before being written down (counts re-queried, edge cases such as lost
events ruled out), and the pipeline was run end to end on the author's own laptop.

## Consequences
* Faster iteration within the one-week time box.
* The author remains responsible for every decision and number in the repository.
