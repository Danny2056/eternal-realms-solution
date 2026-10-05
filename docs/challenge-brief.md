# Eternal Realms - Senior Data Engineer Challenge

## Scenario

We have been hired by Duskmire Studios, creators of the Eternal Realms MMORPG. The game is still
in development, but a live early access (beta) version has a player population running the game.
A big milestone on their roadmap is solid cheat detection software. Our task is to provide the
data model the system will use, and to make sure the data is able to detect cheats. They provided
a rule book of the game, the latest patch notes, and a data dictionary of the snapshot provided, so it is
your task to decide what constitutes a cheat and how it is detected.

## What you receive

- The Postgres snapshot in a Docker container (database only; you discover the structure): `ghcr.io/hexnevarez/eternal-realms:latest`, run instructions in [Getting the data](#getting-the-data)
- A full data dictionary of the snapshot: [docs/data-dictionary.md](docs/data-dictionary.md)
- The game rulebook and the 2.1 patch notes: [docs/rulebook.md](docs/rulebook.md)

## Getting the data

The snapshot is a ready-to-run Postgres 16 image (about 5 GB). The data is already inside, so it starts in a
few seconds and needs no restore step.

```bash
docker pull ghcr.io/hexnevarez/eternal-realms:latest
docker run -d --name eternal-realms -p 5432:5432 ghcr.io/hexnevarez/eternal-realms:latest
psql -h localhost -U candidate -d eternal_realms      # password: candidate
```

The `candidate` role is read only. The database `eternal_realms` has three schemas (`intake`, `game`, `ref`),
described in the [data dictionary](docs/data-dictionary.md). Plan for about 6 GB of free disk space.

## What we ask

### Platform deliverables

One GitHub repository containing:

- Ingested dataset.
- Ingestion pipeline from the snapshot into your own stack (mandatory).
- Analytical warehouse with a documented dimensional model (explain grain and modeling decisions, issues found, cleanup steps)
- Cheat Investigation: What accounts cheated, what cheats were used, why did you was considered certain activities cheating (lineage back to source events)
- Demonstrate that the reports requested below are supported by the data model (provide queries that generate them).
- Architecture Decision Records (ADRs) for your main choices, including stack and tooling.

## Nice to Have 
- The reports listed above, providing the actual reports is optional using any tool you decide (for example Jupyter or Power BI), you only need to demonstrate that the data model supports the reports as stated above.
- Worst cheater offender timeline - if any - see "Cheat report" below for more details
- AWS architecture: how the local solution runs in production - Diagram Only
- Session logs from AI tools used are welcome but optional

### Cheat report

- A report of cheaters - what players cheated - what cheats were found - what systems/mechanics appear to be vulnerable 
- If found: take the most severe case and give a timeline of how the cheat happened
- A recommendation of which vulnerable game mechanics they should patch next
- Any anomalies you detected in the game play itself: behavior in the data that does not match the
  rulebook or looks wrong for a working game, whether or not it is cheating, with the data that shows it

### Reports the data product must enable

Player:
- Player activity over time: daily active players and sessions, with the weekly pattern
- Total population by class, faction, and level
- Creatures killed by day
- Players killed by day
- Items looted by day, broken down by item rarity
- Heat map of activity per sub-zone
- Players killed by bosses vs players killed by other players
- Player 360: total time played, average XP per day, current gear score and its percentile
  within the peer group
- Damage per second percentile within the peer group
  
> [!important] Peer comparisons: wherever a report compares a character with other players, the peer group is:
the same class within the same 10-level bracket (1 to 10, 11 to 20, ... 61 to 70), across both
factions. Results are phrased the way the game will show them to the player, for example: **"Your
gear is better than 87% of other Warriors between levels 1 and 10."**


Economy:
- Total transactions within a time window
- Number of items sold to merchants, broken down by item rarity
- Gold flow: gold entering the economy (creature drops, merchant sales by item rarity) vs gold
  leaving it (auction house cut), and the net result


## Ground rules

- Time box: one week - Deliver what you were able to complete within that timeline. 
- AI assistance is expected. Documenting how you used it is part of the challenge
- Use any stack and tooling you decide, justifiey why you chouse it in an ADR
- The snapshot database is read only: extract from it into your own stack using the ingestion pipeline you create.

## After you submit

We review the repository, then hold a live session where you present your reports, walk us
through your process, and demo the working solution.
