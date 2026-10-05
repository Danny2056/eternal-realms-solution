# ADR 0006: Star schema with a slowly changing level dimension

**Status:** accepted

## Context
The reports compare players with their peers (same class, same 10-level bracket). Characters level up during
the month, so "bracket" depends on when an event happened.

## Decision
A star schema in `marts` (6 dimensions, 10 facts; see `docs/data-model.md`) with `dim_character_level` as a type 2
slowly changing dimension (level with `valid_from` / `valid_to`). Facts are joined to it by time; the fight fact
stores `level_at_start`.

## Consequences
* Peer comparisons are correct for any point in time, not only for the current level.
* Each fact's grain is stated in its SQL header and in the data-model document.
