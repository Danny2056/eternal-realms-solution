# Data Quality Findings

Before looking for cheaters we checked whether the data itself can be trusted. We found seven kinds of problems.
Each one is described twice: **in plain English** for anyone, and **technically** with the evidence and the fix.

All numbers are reproduced by the pipeline in the table `dq.dq_summary` (run `python transform/run.py`).

| Check | What went wrong | Rows affected | What we did |
|---|---|---:|---|
| DQ-1 | Same event delivered twice | 47,733 | Kept one copy |
| DQ-2 | Events lost in delivery | 9,615 | Recorded the gaps so they are never mistaken for cheating |
| DQ-3 | One server's clock was 5 hours off | 927,920 | Corrected the time |
| DQ-4 | Events arrived with missing details | 981 empty, ~0.1-1% of fields | Kept as unknown, filled in from related events where possible |
| DQ-5 | Placeholder or non-existent IDs | 3,750 zones, 3,745 characters | Treated as unknown and flagged |
| DQ-6 | Corrupted numbers | 2,414 repaired, 2,325 unrecoverable | Repaired or set to unknown |
| DQ-7 | Level-ups reporting "level 0" | 36 | Treated as unknown |

---

## DQ-1 Duplicate deliveries

**In plain English:** the game servers sometimes sent the same message twice, like a text message that arrives
twice on your phone. If we counted both copies, every report would show more kills, more gold and more loot than
really happened.

**Evidence:** 9,650,208 rows were received but only 9,602,475 distinct game events exist (`server_event_id`).
Every duplicate group has exactly 2 copies and the copies are byte-identical (same sequence number, type, time and
body). 23 groups arrived in two separate delivery batches; the rest within the same batch.

| Shard | Rows | Unique events | Extra rows |
|---|---:|---:|---:|
| shard-01 | 153,630 | 152,909 | 721 |
| shard-02 | 216,540 | 215,516 | 1,024 |
| shard-03 | 1,583,999 | 1,576,194 | 7,805 |
| shard-04 | 7,696,039 | 7,657,856 | 38,183 |

**Fix:** keep one row per `server_event_id` (the first one stored). Because the copies are identical, which copy we
keep changes nothing. The number of copies received is kept in the column `delivery_count`.

**Why it mattered:** before removing duplicates, the amulet looked suspicious (10,001 uses but only 9,986 cooldown
checks). After removing them the numbers balance (9,942 uses, 9,941 checks). The "anomaly" was a delivery problem,
not a cheat.

## DQ-2 Events lost in delivery

**In plain English:** every server numbers its messages 1, 2, 3, ... When a number is skipped, a message was lost on
the way. About 1 in 1,000 messages never arrived. A lost message can make an honest player look like a cheater
(for example "used the amulet" arrives but "checked the cooldown" was lost), so we keep a list of every gap.

**Evidence:**

| Shard | Gaps | Lost events | Largest gap |
|---|---:|---:|---:|
| shard-01 | 141 | 141 | 1 |
| shard-02 | 212 | 212 | 1 |
| shard-03 | 1,539 | 1,541 | 2 |
| shard-04 | 7,709 | 7,721 | 2 |

Gaps are single events (9,587) or pairs (14), spread evenly over the month: random loss, not an outage.

**Fix:** lost events cannot be recovered. Every missing sequence number is stored in `dq.dq_shard_seq_gaps`.
Cheat rules never accuse a player on the strength of one broken event chain; they look for repeated patterns.

## DQ-3 Server clock 5 hours off

**In plain English:** one of the four game servers (shard-04) was restarted on 7 September and came back with its
clock set to Chicago time instead of the game's official UTC time. From then on everything it recorded looked like
it happened 5 hours earlier than it really did. Shard-04 runs the endgame zones (Netherreach and Voidforge
Sanctum), so without the fix every speed, cooldown and session check in the endgame would be wrong.

**Evidence:** the reference table `ref.servers` lists shard-04 with timezone `America/Chicago` (all others `UTC`)
and a restart at 2026-09-07 03:17:44 UTC. We compared the time each event says it happened with the time it was
received:

| Shard-04 events | Typical delay | Longest delay |
|---|---:|---:|
| Before the restart (up to message #6,736,767) | 0.7 s | 4.9 s |
| After the restart (from message #6,736,768) | **18,000.6 s** (exactly 5 h) | 18,004.9 s |

The switch is clean: the last correct message is #6,736,767 and the first wrong one, one second after the restart,
is #6,736,768. The other three shards stay at about half a second all month.

**Fix:** add 5 hours to the 927,920 affected events. The rule is stored as data in `staging.stg_clock_corrections`
so a reviewer can see it. The original timestamp is kept (`event_ts_raw`) and corrected rows are flagged
(`ts_corrected`). After the fix, shard-04's typical delay is 0.76 s again, like every other shard.

## DQ-4 Missing details in events

**In plain English:** some messages arrived with parts missing, like a delivery note without the sender's name.
981 messages arrived completely empty, and for most event types between 0.1% and 1% of messages are missing one
detail (which character, which zone, which item, and so on).

**Evidence:** the missing fields are spread across every server, both game versions and all event types roughly in
proportion to traffic, which points to random loss in the logging, not to a specific feature or a cheat.

**Fix:** missing values stay "unknown" (NULL) in staging. Where the detail can be safely looked up elsewhere it is
filled in later (for example an item's type can be taken from the event where it dropped). No rule treats a
missing detail as evidence of cheating.

## DQ-5 Placeholder and non-existent IDs

**In plain English:** some messages use a placeholder like "zone_unknown", or refer to characters
(`chr_9xxx`), creatures (`crt_9xxx`) and items (`tpl_9xxx`) that do not exist anywhere in the game.

**Evidence:** 3,750 events say `zone_unknown`; 3,745 events point to character IDs that are not in the character
table; 113 gold payouts and a handful of drops point to creature or item IDs that are not in the reference data.
They are spread thinly, with one or two per fake ID.

**Fix:** `zone_unknown` becomes unknown (NULL). Fake IDs are kept but excluded from player reports and cheat
rules, because there is no real player behind them.

## DQ-6 Corrupted numbers

**In plain English:** some numbers were scrambled in transmission. There were two kinds:

* **Flipped numbers**, for example a merchant price of -1,144 where the real price is 1,143. These come from a
  well-known computer glitch (every bit of the number flipped), and the real value can be recovered exactly.
* **Garbage numbers** over 2.1 billion, for example a single kill worth 2,148,090,652 XP. The real value cannot be
  recovered.

**Evidence:** affected fields are XP awarded, damage, gold payouts, merchant price and auction buyout price, about
0.1-0.25% of each. Proof that the repair is right: after repair, **every** XP award matches the creature's
published XP (297,447 of 297,447) and **every** merchant sale matches the item's published price
(222,722 of 222,722).

**Fix:** flipped values are repaired with the formula `true value = -value - 1` (2,414 events); garbage values are
set to unknown (2,325 events). The original value is kept in `<field>_raw` and the repair is recorded in
`numeric_repair`.

## DQ-7 Level-ups reporting level 0

**In plain English:** 22 level-up messages say the character reached "level 0", which is impossible, and 14 more
do not say the level at all.

**Fix:** treated as unknown. The character's level is still known from the level-ups before and after.

---

## Reference data notes

* Patch 2.1 went live on 2026-08-26 at 09:41 UTC, a Wednesday, as the patch notes say.
* The new Netherreach Waygate (transport `trn_05` / `trn_06`) takes 6 seconds. Walking the same route is 8,344 m,
  about 20 minutes.
* Archon Vexmoor's loot table changed with 2.1: 1 entry ended, 13 new entries started.
* The rulebook contains the 2.1 patch notes twice (a documentation duplicate, no effect on data).
