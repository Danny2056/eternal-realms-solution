# Cheat Investigation Log

A running record of every game system we checked, what the rulebook says, what the data shows, and our verdict.
It is written so that someone with no technical background can follow the reasoning. Everything here was
checked on the **cleaned** data (see [data-quality-findings.md](data-quality-findings.md)), after removing
duplicates and fixing the clock.

**How to read the verdicts**

* **Clean**: the rule holds for every player. Any exceptions are rare, spread across many players, and explained
  by lost or damaged messages, not by cheating.
* **Cheat**: a player broke a rule in a way that lost messages cannot explain, with evidence back to the events.
* **Anomaly**: the game itself behaves in a way the rulebook does not allow, for everyone. Not cheating, but
  something the studio should look at.

Status: investigation complete. The checks run automatically as a rule engine (`transform/models/04_cheats`);
results are in `cheats.cheat_violations` and `reports/output/c01_cheat_report.csv`.

## Rule engine results

| Rule | Name | Severity | Violations | Characters |
|---|---|---|---:|---:|
| R01 | Burst damage | high | 70 | 5 |
| R02 | Item duplication | high | 3 | 1 |
| R03 | Equip stacking | medium | 247 | 5 |
| R04 | Speed hack | medium | 1 | 1 |
| R05 | Gear above level | low | 1 | 1 |
| R06 | Hit above maximum damage | high | 0 | 0 |
| R07 | Ability reused during cooldown | high | 0 | 0 |
| R08 | Amulet reused during cooldown | high | 0 | 0 |
| R09 | Soulbound item moved | high | 0 | 0 |
| R10 | Illegal trade | high | 0 | 0 |
| R11 | Transport misuse | medium | 0 | 0 |
| R12 | Combat in a capital hub | high | 0 | 0 |
| R13 | Wrong XP award | high | 0 | 0 |

Confirmed cheaters (a high-severity rule, or 3+ different rules): chr_1786 (101 violations, 5 rules),
chr_1785 (77), chr_1782, chr_1783 and chr_1784 (48 each). No other character has any violation.

---

## Headline

**One group of five accounts cheated, and only them.** They combined five exploits into a plan: level up
together, duplicate a sword, stack equipment, then use "burst damage" to kill the hardest boss in the game in
13 seconds (normal players need at least 3 minutes) and to kill 18 other players with a single burst each.
Every other player and every other game system we checked follows the rules.

---

## Summary of checks

| # | Game system | Rulebook says | Verdict |
|---|---|---|---|
| 1 | Amulet of the Planes | 60 min cooldown, 10 s channel, always to own capital | Clean |
| 2 | XP awards | Each creature gives a fixed XP | Clean |
| 3 | Levels | Level matches XP thresholds | Clean |
| 4 | Damage per hit | Fixed formula, never above the maximum | Clean |
| 5 | Critical hits | Fixed chance per class, bosses never crit | Clean |
| 6 | Ability use rate | One ability every 1.5 s, plus each ability's own cooldown | Clean when counting abilities used |
| 7 | **Hits per instant** | Every hit comes from one ability use, at most one every 1.5 s | **Cheat (burst damage)** |
| 8 | Abilities per class | A class can only use its own abilities | Clean |
| 9 | Gold from kills | Fixed amounts from the loot table | Clean |
| 10 | Merchant prices | Fixed sell price per item | Clean |
| 11 | Gold balances | Every change of gold is explained by an event | Clean |
| 12 | Loot drop rates | Published drop chances | Clean |
| 13 | Loot rights | Only the assigned party member can loot | Clean |
| 14 | Rewards after escaping or dying | No XP, gold or loot | Clean |
| 15 | **Walking speed** | 7 m/s, minimum distance between zones | **Cheat (1 speed hack)** |
| 16 | Transports | Fixed travel times, faction rules, Waygate only from 2.1 | Clean |
| 17 | Logins | Log in where you logged out | Clean |
| 18 | Where combat happens | Never in capital hubs; PVP only between factions | Clean |
| 19 | Parties | Max 5 players, one faction | Clean |
| 20 | Trades | Same faction, same zone, both sides match | Clean |
| 21 | Soulbound items | Once equipped, never traded or auctioned | Clean |
| 22 | Items appearing from nowhere | Every item comes from a drop | Clean |
| 23 | Game state vs events | Final gold, XP and level match the event history | Clean |
| 24 | **One item, one owner** | An item belongs to exactly one character at a time | **Cheat (item duplication)** |
| 25 | **Equipping** | Equipping replaces what is in the slot | **Cheat (equip stacking)** |
| 26 | **Level requirement** | Cannot equip gear above your level | **Cheat (1 case)** |
| 27 | Creature damage when a player dies | Creature damage is fixed by its stats | **Anomaly** |
| 28 | Bots (24/7 play) | Not in the rulebook, checked as good practice | Clean: longest session 23 h, no round-the-clock play |

---

## The cheaters: a coordinated group of five accounts

**In plain English:** five new accounts were created within 12 minutes of each other on the evening of
13 August. Each has exactly one character, all Wildbound. They played every session together as a full
5-person party, all reached the maximum level (70) on 22 August, cheated on 22, 25 and 26 August, and never
played again after 26 August.

| Account | Character | Class | Created (UTC) | Reached level 70 | Last seen |
|---|---|---|---|---|---|
| acc_1013 | chr_1782 | Warrior | 13 Aug 20:50 | 22 Aug 14:16 | 26 Aug 21:16 |
| acc_1015 | chr_1784 | Mage | 13 Aug 20:54 | 22 Aug 14:40 | 26 Aug 21:16 |
| acc_1014 | chr_1783 | Paladin | 13 Aug 20:55 | 22 Aug 14:40 | 26 Aug 21:15 |
| acc_1016 | chr_1785 | Rogue | 13 Aug 20:56 | 22 Aug 14:40 | 26 Aug 22:15 |
| acc_1017 | chr_1786 | Warlock | 13 Aug 21:02 | 22 Aug 15:06 | 26 Aug 22:14 |

How unusual this is: of the 210 characters created during the month, 41 (about 20%) reached level 70. All five
of these did, together, in 9 days. Levelling as a party is allowed; it is what they did at level 70 that is not.

### Cheat 1: burst damage (the main exploit)

**In plain English:** in the game, every hit comes from using an ability, and a character can use at most one
ability every 1.5 seconds. These five characters landed **20 hits in the same instant**, over and over. One
burst does about 8,000 to 12,000 damage. A level-70 character has at most about 4,200 health, so one burst kills
any player outright, and the five together melted the final boss in 13 seconds.

**Evidence:** across all 1.3 million damage records in the month, there are exactly **70 moments** where one
character landed more than one hit at the same instant, always exactly 20 hits, and **all 70 belong to these
five characters**. No other player has a single one.

| Date | Who | Target | Bursts |
|---|---|---|---:|
| 22 Aug 18:10 | chr_1786 | Player chr_1118 (Ashen Vale) | 1 |
| 25 Aug 22:03 | all five | **Archon Vexmoor**, final boss of Voidforge Sanctum | 26 |
| 26 Aug 21:12 | all five | **Archon Vexmoor** again | 26 |
| 26 Aug 21:20-21:48 | chr_1785, chr_1786 | 17 players in Scorched Steppes, Ashen Vale and Netherreach | 17 |

Archon Vexmoor has 226,570 health. Over the month, other groups killed him 766 times; their fastest kill took
**176 seconds** and the typical kill **295 seconds**. This group's two kills took **13 seconds** each.

**What they gained:** 7 epic items from the two boss kills, including two items that only exist from patch 2.1
(*Starless Hauberk*, *Netherbound Polearm*), and the second kill came 11.5 hours after 2.1 increased Archon
Vexmoor's drop chances.

**Vulnerable mechanic:** the server does not enforce the global cooldown on damage. It checks how often abilities
are *used*, but it accepts any number of *hits* at once.

### Cheat 2: item duplication through trading

**In plain English:** chr_1786 bought one sword at the auction house and then "gave" that same single sword to
each of its four teammates, one after another, within one minute. After the first trade it no longer owned the
sword, so the next three trades should have been impossible. Afterwards all five characters had the same sword
equipped at the same time. The rulebook says an item belongs to exactly one character at any moment.

**Evidence (all on 25 Aug, Thornhold auction house):**

| Time (UTC) | Event | Detail |
|---|---|---|
| 21:39:01 | auction_purchased | chr_1786 buys `itm_0113674`, a *Stormrender Blade* (rare, level-70 sword), for 5,805 gold from chr_0207 |
| 21:39:09 | trade_completed | chr_1786 gives `itm_0113674` to chr_1782 |
| 21:39:24 | trade_completed | chr_1786 gives the **same** `itm_0113674` to chr_1783 |
| 21:39:52 | trade_completed | chr_1786 gives the **same** `itm_0113674` to chr_1784 |
| 21:40:09 | trade_completed | chr_1786 gives the **same** `itm_0113674` to chr_1785 |
| 21:40:54 onwards | item_equipped | all five characters equip `itm_0113674` |

Across all 3,563 item trades in the month, this is the **only** case of a character trading away an item it no
longer held. Lost messages cannot explain it: all four trades are complete on both sides and happen 15 to 30
seconds apart.

**Vulnerable mechanic:** the trade window does not check that the giver still owns the item.

### Cheat 3: equip stacking

**In plain English:** normally, putting on a new weapon takes the old one off. These five characters "put on"
the same weapon dozens of times in a few seconds without ever taking it off, which the game should not allow.
Each stacking session happened just before a burst-damage attack, so it is most likely part of how the burst
was set up.

**Evidence:** only these five characters show more than 2 equips within one second of each other:

| Character | Equips less than 1 s apart | Total equips |
|---|---:|---:|
| chr_1786 | 76 | 90 |
| chr_1785 | 57 | 73 |
| chr_1782 | 38 | 54 |
| chr_1783 | 38 | 52 |
| chr_1784 | 38 | 48 |
| Next highest player | 2 | 15 |

**Vulnerable mechanic:** equipping does not enforce "one item per slot" when the action is repeated quickly.

### Cheat 4: speed hack (one case)

**In plain English:** on 22 August, minutes before its first burst attack, chr_1786 walked from Red Mesa into
Ashen Vale in 52 seconds. The shortest possible walk is 3,038 m, which takes 434 seconds at the game's fixed
walking speed.

**Evidence:** `zone_entered` Red Mesa at 18:08:46, `zone_entered` Ashen Vale at 18:09:38 (both shard-02/03,
no lost messages in between). This is the only too-fast walk by any player in the month.

### Cheat 5: equipping gear above the character's level (one case)

**In plain English:** on 15 August, chr_1786 equipped an *Ember-Etched Saber* that requires level 52 while it
was level 32.

**Evidence:** `item_equipped` at 2026-08-15 19:03:52 UTC; the level history from `level_up` events shows level 32
at that moment. Other under-level equips in the data are one level apart and happen in the same second as a
level-up (a timing artefact). Three larger cases (chr_0702, chr_0902, chr_1777) are caused by a damaged
"level 0" message (DQ-7) and are not cheats.

---

## Worst case: timeline of chr_1786 

chr_1786 took part in every exploit and was the one who duplicated the sword.

| When (UTC) | What happened |
|---|---|
| 13 Aug 21:02 | Character created, 12 minutes after the first of the five; joins the group's party 11 minutes later |
| 15 Aug 19:03 | Equips a level-52 sword at level 32 (cheat 5) |
| 22 Aug 15:06 | Reaches level 70, the last of the five |
| 22 Aug 18:04 | Buys gear at the Thornhold auction house and equips it 22 times in 6 seconds (cheat 3) |
| 22 Aug 18:09 | Walks Red Mesa to Ashen Vale in 52 s instead of at least 434 s (cheat 4) |
| 22 Aug 18:10 | Kills player chr_1118 with a single 20-hit burst of 11,437 damage (cheat 1), uses the amulet to escape to the capital and logs off 53 seconds after the kill |
| 25 Aug 21:39 | Buys a *Stormrender Blade* and trades the same sword to all four teammates (cheat 2) |
| 25 Aug 21:40 | All five stack-equip the duplicated sword (cheat 3) |
| 25 Aug 22:03 | The five kill Archon Vexmoor in 13 s with 26 bursts; chr_1786 loots *Abyssal Sword II* (epic) |
| 26 Aug 09:41 | Patch 2.1 goes live with better Archon Vexmoor drops |
| 26 Aug 21:12 | The five kill Archon Vexmoor again in 13 s; chr_1786 loots *Oathbreaker, Edge of the Unmade* (epic) |
| 26 Aug 21:30-21:46 | chr_1786 kills 9 players in Ashen Vale, one burst each; chr_1785 kills 8 more |
| 26 Aug 22:14 | Last event. None of the five accounts plays again |

---

## Leads investigated and closed

* **Gold funnelling (closed, not a cheat):** chr_1211 gave 224,665 gold to chr_1669 and received no gold back, but
  received 13 items in return. Many player pairs trade gold for gear like this.
* **Fast levelling (closed, not a cheat):** chr_0617 reached level 70 in 2.7 days, at a high but normal XP rate
  for the time it played.
* **Bots (closed, not found):** the longest single session is 23 hours and no character plays around the clock
  day after day.
* **Endgame concentration (closed, normal):** three Netherreach creatures account for about 460,000 of the
  month's kills, spread evenly across about 1,150 level-70 characters. This is normal endgame grinding.

## Anomalies and product insights (not cheating)

* **Players never die to bosses.** In 8,137 boss fights during the month nobody died, and no boss appears as a
  killer in any death. Some players took up to 39 times their maximum health in damage during a boss fight and
  survived. The rulebook has no healing in combat, so this cannot happen in a working game. All 13,148 deaths
  were caused by other players (85%) or by normal and elite creatures (15%). Likely a server bug in boss damage
  or death handling; it also makes bosses risk-free, which the cheaters did not even need.
* **Runaway gold inflation.** 287.6 million gold entered the economy (creature drops 110.6 M, merchant sales
  177.1 M) and only 0.38 million left it (the auction house cut), so 99.9% of all gold created stays in the game.
  Merchants buy everything and sell nothing, and the auction house is the only gold sink. Prices will inflate as
  the realm ages.
* **Weekly pattern and patch effect.** Saturdays and Sundays have about 50% more active players than weekdays
  (about 680 vs 460). The busiest weekday is the Thursday after patch 2.1 (27 Aug, 685 players), a
  patch-launch spike.

* **Creature damage when a player dies:** in fights the player loses, the creature deals 3 to 4 times more
  damage than its stats allow (median), up to 13 times. In fights the player wins, damage stays within the limit.
  This affects all players equally, so it is a game behaviour issue, not a cheat.
* **Waygate adoption:** after the 6-second Netherreach Waygate arrived in 2.1, use of the Silverspire Ferry and
  the Thornhold Zeppelin fell by about 90%.

---

## Recommendation: which mechanics to patch next

In priority order, by damage done and how easy each exploit was to repeat:

1. **Damage rate limit (burst damage).** The server checks how often abilities are *used* but accepts any number
   of *hits* at the same instant. This let five players kill the final boss in 13 seconds and kill other players
   in one burst. Fix: enforce one hit per ability use and the 1.5 s global cooldown on damage events themselves.
2. **Trade ownership check (item duplication).** The trade window does not confirm the giver still owns the item
   when the trade completes. Fix: check ownership and transfer the item in one atomic step.
3. **Equip slot enforcement (equip stacking).** Repeating "equip" quickly puts an item into an occupied slot
   without removing the old one. Fix: require the unequip in the same transaction and rate-limit equips.
4. **Movement validation (speed hack).** Fix: reject zone transitions faster than the walking speed allows.
5. **Not cheating, but urgent:** boss fights where players cannot die, and an economy with almost no gold sink.
