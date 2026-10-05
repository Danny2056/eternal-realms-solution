# ADR 0005: Cheat detection is a catalogue of explicit rules with evidence

**Status:** accepted

## Context
The brief asks which accounts cheated, which cheats were used, why the activity counts as cheating, and for
lineage back to the source events. The rulebook is the authority on what is allowed.

## Decision
* Each rulebook constraint that can be checked becomes one SQL model (`cheats.rNN_*`) returning violations in a
  common shape: rule, character, time, plain-English detail, and the `event_id`s that prove it.
* `cheats.cheat_rule_catalog` describes every rule, its rulebook section and severity.
* `cheats.cheat_violations` unions all rules; `cheats.cheat_offenders` summarises per character.
* A character is a **confirmed cheater** when it breaks a high-severity rule or at least 3 different rules. One
  isolated low or medium finding is listed for review only, because a lost event can create one false signal.
* Rules that never fire stay in the catalogue, as proof that the check ran.

## Alternatives considered
* **Anomaly scoring / machine learning:** useful for unknown cheats, but cannot explain *why* to a player or a
  support team, and needs labelled data. Kept as a future step.

## Consequences
* Result: 13 rules, 5 fire, all on the same five characters, 322 violations, each traceable to raw rows
  (`reports/sql/c02_violation_lineage.sql`).
* New cheats are added by adding a rule file; no other code changes.
