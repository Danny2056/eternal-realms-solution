# Data Model

The warehouse is a **star schema**: a small number of *fact* tables (things that happened, such as fights, loot
and gold movements) surrounded by *dimension* tables (the things they happened to, such as characters, zones,
items and dates). Reports join facts to dimensions.

**In plain English:** a fact table is like a till receipt roll: one line per sale. A dimension table is like the
product catalogue: one line per product, with its name, category and price. To ask "how much did we sell of each
category last week?" you match receipt lines to catalogue lines and add them up.

All tables live in one DuckDB file, `data/warehouse/eternal_realms.duckdb`, in these layers:

| Schema | Layer | Purpose |
|---|---|---|
| `raw_ref`, `raw_game`, `raw_intake` | Raw | Views over the ingested Parquet files, exactly as delivered |
| `staging` | Clean | One trustworthy row per game event (`stg_events`), see [data-quality-findings.md](data-quality-findings.md) |
| `dq` | Data quality | Measurements of every data problem and the list of lost events |
| `intermediate` | Building blocks | Level history, item chain of custody, damage hits with their legal maximum |
| `cheats` | Cheat detection | Rule catalogue, one table per rule, all violations with evidence, offenders |
| `marts` | Star schema | Dimensions and facts used by the reports |

```
                      dim_date
                         │
 dim_character ─── fct_sessions                     dim_zone (sub-zone grain)
      │        ─── fct_encounter_participation ───┬── dim_creature
      │        ─── fct_deaths                     │
      │        ─── fct_xp                         ├── fct_creature_kills
      │        ─── fct_loot ────────────────────── dim_item_template
      │        ─── fct_gold_ledger                │
      │        ─── fct_economy_transactions ──────┘
      │        ─── fct_character_gear
      │        ─── fct_subzone_activity
 dim_character_level (level over time, slowly changing)
```

To load this model into Power BI and see it as a star in Model view, follow
[powerbi-star-schema.md](powerbi-star-schema.md).

## Dimensions

| Table | Grain (one row per) | Notes |
|---|---|---|
| `dim_date` | day in the window (10 Aug to 10 Sep 2026) | day of week, weekend flag, ISO week, patch 2.1 flag |
| `dim_character` | character | account, class, faction, current level / XP / gold, confirmed-cheater flag |
| `dim_character_level` | character and level held | `valid_from` / `valid_to` and the 10-level peer bracket; a slowly changing dimension (type 2) |
| `dim_zone` | sub-zone | with its zone, zone type, faction and level range |
| `dim_item_template` | item template | slot, rarity, item level, level requirement, sell price, allowed classes |
| `dim_creature` | creature | rank, health, damage, XP reward, home zone |

## Facts

| Table | Grain (one row per) | Main measures | Used by |
|---|---|---|---|
| `fct_sessions` | play session (login to logout) | duration | Activity, weekly pattern, time played |
| `fct_encounter_participation` | character in one fight | duration, damage done, damage received, outcome, level at start | DPS percentile, boss analysis |
| `fct_creature_kills` | creature killed | participants, fight duration | Creatures killed by day |
| `fct_deaths` | character death | killer category (player / boss / creature) | Players killed by day, boss vs player |
| `fct_xp` | XP award | XP amount | Average XP per day |
| `fct_loot` | item looted | rarity, item level | Items looted by rarity |
| `fct_gold_ledger` | gold movement for a character | signed amount, flow type (source / sink / transfer) | Gold flow |
| `fct_economy_transactions` | completed transaction | gold amount, type (merchant sale / trade / auction sale) | Transactions in a window, items sold by rarity |
| `fct_character_gear` | character (snapshot) | equipped items, gear score (capped) | Player 360 gear percentile |
| `fct_subzone_activity` | sub-zone and hour | events, active characters | Heat map |

## Key modelling decisions

1. **Level is tracked over time, not just "now".** The peer group in the brief is *class + 10-level bracket*. A
   character that was level 35 last week and is level 62 today must be compared with level 31-40 players for last
   week's fights. `dim_character_level` stores each level with the time it was held, and facts join to it by
   time (an "as-of" join). The fight fact stores `level_at_start` directly so reports do not have to.
2. **One cleaned event table feeds everything.** All facts are built from `staging.stg_events`, so a fix made
   once (duplicates, clock, corrupted numbers) reaches every report. Each fact keeps `event_id` where it has one
   event per row, so its rows trace back to the raw delivery.
3. **Fights are modelled per character, not per fight.** The game logs every fight once per participant, and
   damage is personal. A party fight therefore has one row per member. Fight-level questions (creatures killed)
   use `fct_creature_kills`, which collapses to one row per kill.
4. **Two damage sources, one measure.** Normal and elite fights only have a per-fight damage summary; boss and
   PVP fights are logged hit by hit. Both are reduced to `damage_done` / `damage_received` per character and
   fight, so DPS can be compared across all fight types.
5. **Gold is a signed ledger with a flow type.** Gold *enters* the economy (creature drops, merchant sales),
   *leaves* it (the auction house's 5% cut) or *moves between players* (trades, auction payments). Tagging each
   movement makes "gold in vs gold out" a simple sum and keeps player-to-player transfers from being counted as
   new gold.
6. **Peer comparisons exclude confirmed cheaters.** Otherwise the five cheaters would distort the percentiles of
   honest level-70 players. Percentiles are computed "excluding yourself": *better than X% of the others*.
7. **Gear score comes from the snapshot.** Gear score is "current" in the brief, so it is read from the game state
   (`game.item_instances`) and capped at the bracket maximum, as the rulebook states.
8. **Unknown stays unknown.** Values lost or damaged in delivery are NULL, not guessed. Where a value can be
   recovered with certainty (for example an item's template from its drop event) it is filled in, and the
   recovery is documented in the model's SQL.

## Report coverage

Every report in the brief has a query in `reports/sql/`. `python reports/run_reports.py` runs them all and saves
the results to `reports/output/` as CSV files.

| Report in the brief | Query |
|---|---|
| Daily active players and sessions | `p01_daily_active_players.sql` |
| Weekly pattern | `p02_weekly_pattern.sql` |
| Population by class, faction, level | `p03_population.sql` |
| Creatures killed by day | `p04_creatures_killed_by_day.sql` |
| Players killed by day | `p05_players_killed_by_day.sql` |
| Items looted by day by rarity | `p06_items_looted_by_rarity.sql` |
| Heat map per sub-zone | `p07_subzone_heatmap.sql` |
| Killed by bosses vs by players | `p08_deaths_boss_vs_player.sql` |
| Player 360 with gear percentile | `p09_player_360.sql` |
| DPS percentile in peer group | `p10_dps_percentile.sql` |
| Transactions in a time window | `e01_transactions_in_window.sql` |
| Items sold to merchants by rarity | `e02_items_sold_by_rarity.sql` |
| Gold flow in vs out, net | `e03_gold_flow.sql` |
| Cheaters, rules broken | `c01_cheat_report.sql` |
| Lineage of a violation back to raw events | `c02_violation_lineage.sql` |
