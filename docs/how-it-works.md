# How It Works (plain-English guide)

This page explains every step of the Eternal Realms data pipeline without assuming any technical background.
Each step has a short "what it does", "why it matters" and "how to run it". Technical details live in the
code comments and in the other documents linked below.

```
 Game database (read only)          Our own copy              Cleaned data            Checks and reports
 ┌─────────────────────┐    Step 1   ┌──────────────┐  Step 2  ┌──────────────┐ Steps 3-6 ┌────────────────────┐ Step 7 ┌─────────┐
 │ Postgres snapshot   │ ──────────> │ Raw files    │ ───────> │ Staging      │ ────────> │ Data quality,      │ ─────> │ Reports │
 │ (Docker container)  │  ingestion  │ (Parquet)    │ cleaning │ (DuckDB)     │           │ cheats, star schema│        │ (CSV)   │
 └─────────────────────┘             └──────────────┘          └──────────────┘           └────────────────────┘        └─────────┘
```

## Step 0: Start the game database

**What it does:** runs a copy of the game studio's database on your laptop inside Docker (a program that runs
other programs in a sealed box).

**Why it matters:** the brief gives us the data only as a database snapshot. We are only allowed to read it.

**How to run it:** `docker compose up -d` (full steps in [SETUP.md](../SETUP.md)).

## Step 1: Copy the data into our own files (ingestion)

**What it does:** reads every table from the game database and saves it as files in `data/raw/`. Nothing is
changed or cleaned at this point: the files are an exact copy, like photocopying the original records before
working on them.

**Why it matters:**

* We never modify the studio's database, and we can always go back to the original if a cleaning step is wrong.
* After copying, the script counts the rows on both sides and confirms they match ("All tables reconciled").
  Result: 9,650,208 events and every reference and game table copied with matching counts.
* The events are filed into one folder per day received, which keeps them easy to manage.

**How to run it:** `python ingestion\extract.py` (about 5 minutes).

**Technical notes:** Python with `psycopg` (database reader) and `pyarrow` (Parquet writer); streamed in batches
of 100,000 rows so memory stays low. Code: [ingestion/extract.py](../ingestion/extract.py).

## Step 2: Clean the data (staging)

**What it does:** turns the raw copy into one tidy table of trustworthy events, `staging.stg_events`.

**Why it matters:** the raw data contains seven kinds of problems (duplicates, lost messages, a wrong clock,
missing details, fake IDs, scrambled numbers, impossible levels). If we looked for cheaters in dirty data we
would accuse honest players and miss real cheaters. Each problem and its fix is explained in
[data-quality-findings.md](data-quality-findings.md).

In short, the cleaning step:

1. **Removes duplicate deliveries**: 9,650,208 rows become 9,602,475 real events.
2. **Fixes the wrong clock** on shard-04: 927,920 events moved forward 5 hours.
3. **Unpacks each event's details** (who, where, what item, how much damage) from a packed text field into
   proper columns, so they can be searched and counted.
4. **Repairs scrambled numbers** where possible and marks the rest as unknown.
5. **Keeps the trail back to the source:** every cleaned event still carries its original ID, server, message
   number, delivery file and original timestamp. Any number in any report can be traced back to the exact
   messages it came from.

**How to run it:** `python transform\run.py` builds steps 2 to 6 in one go (about 3 minutes). It rebuilds
everything from scratch each time, so running it twice gives the same result.

**Technical notes:** DuckDB (a fast analytics database stored as one file, `data/warehouse/eternal_realms.duckdb`).
Each cleaning or check step is a plain SQL file in `transform/models/`, run in numbered order.

## Step 3: Check data quality

**What it does:** produces two tables that measure the problems found:

* `dq.dq_summary` lists each problem and how many events it affected (the numbers in the findings document).
* `dq.dq_shard_seq_gaps` lists every lost message, so cheat checks can tell "this chain is broken because of
  cheating" apart from "this chain is broken because a message was lost".

## Step 4: Build reusable building blocks (intermediate)

**What it does:** prepares three helper tables that several later steps need:

* **Level history:** which level every character was at, and when. Needed because players are compared with
  others of the same level *at the time*.
* **Item chain of custody:** every time an item changed hands (looted, traded, auctioned, sold), in order. This
  is how the item duplication was caught.
* **Damage hits with their legal maximum:** every boss and PVP hit next to the largest damage the rulebook allows
  for that character's level.

## Step 5: Look for cheaters (rule engine)

**What it does:** checks every player against 13 rules taken from the rulebook (for example "one ability every
1.5 seconds", "an item belongs to one character at a time", "walking speed is 7 m/s"). Every broken rule is
written to one table, `cheats.cheat_violations`, together with the IDs of the original events that prove it.

**Why it matters:** the brief asks not only *who* cheated but *why* we think so, with a trail back to the source.
Any accusation can be opened and traced to the exact messages the game servers sent
(`reports/sql/c02_violation_lineage.sql`).

**How a player is judged:** one isolated minor finding is not enough, because a lost message can create one
false signal. A player is a *confirmed cheater* after breaking a serious rule, or at least three different rules.

**Result:** 5 of the 13 rules were broken, all by the same five characters (322 violations). The other 8 rules
were never broken by anyone. The full story is in [investigation-log.md](investigation-log.md).

## Step 6: Build the reporting model (marts)

**What it does:** organises the clean data into a *star schema*: tables of things that happened (sessions,
fights, deaths, loot, gold movements) linked to tables that describe characters, zones, items, creatures and
dates. This is the shape reporting tools such as Power BI expect. Details: [data-model.md](data-model.md).

## Step 7: Produce the reports

**What it does:** runs one query per report requested in the brief (daily players, kills, loot, gold flow,
player 360, percentiles, cheat report and so on) and saves each result as a CSV file in `reports/output/`.

**How to run it:** `python reports\run_reports.py` (a few seconds).

## Decisions

Why we chose each tool and approach is recorded in short "Architecture Decision Records" in [adr/](adr/).

## Glossary

| Term | Meaning |
|---|---|
| Event | One thing that happened in the game, such as a kill, a trade or a login |
| Shard | One of the four game servers; each runs certain zones |
| Snapshot | A frozen copy of the database at one moment (end of 10 September 2026) |
| Parquet | A compact file format for tables, widely used for analytics |
| DuckDB | A small, fast database that runs on a laptop and reads Parquet files |
| Staging | The cleaned version of the raw data, before reports are built on it |
| UTC | The world's reference time zone; the game's official clock |
| Lineage | The trail from a number in a report back to the original events |
