# Eternal Realms - Snapshot Data Dictionary

This dictionary describes the Postgres snapshot of the Eternal Realms early access realm: every
schema, table, and column, and the body of every event type. Game rules are in the rulebook;
where a column holds a rule value (distances, drop chances, cooldowns), the rulebook explains how
the game uses it.

39 event types: 
 - 5 session and character, 
 - 10 movement, 
 - 2 party, 
 - 11 combat, 
 - 5 loot and inventory, 
 - 6 economy. 
  
 >[!note] Discrepant Schema 
 >Only `pvp_damage_dealt` and `pvp_damage_received` have two schema
versions - See patch notes on the provided Rulebook for more details.

## 1. Database overview

Database `eternal_realms`, three schemas:

| Schema   | Content                                                                                           | Keys                                                                                              |
| -------- | ------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `intake` | Every game event received from the realm's shards between 2026-08-10 and 2026-09-10, as delivered | `event_id` primary key only. Links to other tables live inside the JSON body and are not enforced |
| `game`   | Game state at the moment the snapshot was taken (end of 2026-09-10)                               | Primary and foreign keys enforced                                                                 |
| `ref`    | Reference data: world, classes, abilities, items, creatures, loot, versions, server shards        | Primary and foreign keys enforced                                                                 |

All timestamps are `timestamptz`. The realm runs on UTC.

## 2. Reference data (`ref`)

### ref.servers
The shards that run the realm. Each shard hosts a fixed set of zones.

| Column | Type | Description |
|---|---|---|
| server_id | text PK | Shard ID, as written in `intake.events.server_id` |
| ip | inet | Shard address |
| local_timezone | text | Timezone configured on the shard host (IANA name) |
| realm_timezone | text | Timezone of the realm (IANA name) |
| status | text | `online` or `offline` at snapshot time |
| last_state_change_at | timestamptz | When `status` last changed |

### ref.zones
| Column | Type | Description |
|---|---|---|
| zone_id | text PK | Zone ID |
| name | text | Display name |
| zone_type | text | `hub`, `starting`, `contested`, `dungeon` |
| faction | text | Owning faction; null when open to both |
| min_level, max_level | int | Recommended level range; null for hubs |
| server_id | text FK | Shard hosting the zone |

### ref.sub_zones
| Column | Type | Description |
|---|---|---|
| sub_zone_id | text PK | Sub-zone ID |
| zone_id | text FK | Parent zone |
| name | text | Display name |

### ref.zone_adjacency
Walking corridors between zones. Each connected pair appears twice, once per direction.

| Column | Type | Description |
|---|---|---|
| zone_a_id | text PK, FK | Zone walked from |
| zone_b_id | text PK, FK | Adjacent zone walked to |
| min_distance_m | int | Minimum walking distance in meters between entering `zone_a_id` and entering `zone_b_id` |

### ref.transports
Fixed routes. Each route appears once per direction.

| Column | Type | Description |
|---|---|---|
| transport_id | text PK | Route ID |
| name | text | Display name |
| kind | text | `boat`, `zeppelin`, `teleporter` |
| from_zone_id, to_zone_id | text FK | Departure and arrival zones |
| from_sub_zone_id, to_sub_zone_id | text FK | Departure and arrival sub-zones |
| travel_time_s | int | Fixed travel time in seconds |
| faction | text | Faction allowed to use it; null when open to both |
| available_from_version | text FK | First game version in which the route exists |

### ref.merchants
| Column | Type | Description |
|---|---|---|
| merchant_id | text PK | Merchant ID |
| name | text | Display name |
| zone_id | text FK | Zone |
| sub_zone_id | text FK | Sub-zone |

### ref.game_versions
| Column | Type | Description |
|---|---|---|
| version | text PK | Version, for example `2.0` |
| released_at | timestamptz | When the version went live |

### ref.classes
| Column | Type | Description |
|---|---|---|
| class_id | text PK | Class ID |
| name | text | Display name |
| armor_type | text | `cloth`, `leather`, `mail`, `plate` |
| crit_chance | numeric | Critical hit chance, 0 to 1 |

### ref.class_weapon_types
| Column | Type | Description |
|---|---|---|
| class_id | text PK, FK | Class |
| weapon_type | text PK | Weapon type the class can wield |

### ref.abilities
| Column | Type | Description |
|---|---|---|
| ability_id | text PK | Ability ID |
| class_id | text FK | Class that has it |
| name | text | Display name |
| attack_type | text | `spell` or `weapon` |
| base_damage | int | Damage at level 1 |
| damage_per_level | int | Damage added per character level |
| cooldown_s | int | The ability's own cooldown in seconds; null when only the global cooldown applies |

### ref.item_templates
The kind of item. Individual items are item instances.

| Column | Type | Description |
|---|---|---|
| item_template_id | text PK | Template ID |
| name | text | Display name |
| item_kind | text | `gear` or `amulet` |
| slot | text | `helmet`, `chest`, `pants`, `weapon`; null for the amulet |
| rarity | text | `common`, `uncommon`, `rare`, `epic`, `legendary` |
| item_level | int | Item level, used for gear score |
| level_requirement | int | Minimum character level to equip |
| sell_price | int | Gold paid by merchants |
| weapon_type | text | Weapons only |
| armor_type | text | Armor only |
| introduced_in_version | text FK | First game version in which the item exists |

### ref.item_template_classes
| Column | Type | Description |
|---|---|---|
| item_template_id | text PK, FK | Template |
| class_id | text PK, FK | Class allowed to equip it |

### ref.creatures
| Column | Type | Description |
|---|---|---|
| creature_id | text PK | Creature ID |
| name | text | Display name |
| level | int | Creature level |
| creature_type | text | Beast, Humanoid, Undead, and so on |
| rank | text | `normal`, `elite`, `boss` |
| health | int | Total health |
| base_damage | int | Damage per creature attack before the modifier |
| damage_modifier | numeric | Multiplier by rank |
| xp_reward | int | XP granted on kill |
| zone_id | text FK | Zone where it spawns |

### ref.loot_table_entries
| Column | Type | Description |
|---|---|---|
| loot_entry_id | text PK | Entry ID |
| creature_id | text FK | Creature |
| entry_type | text | `item` or `gold` |
| item_template_id | text FK | Item that can drop; null for gold |
| gold_amount | int | Gold granted; null for items |
| drop_chance | numeric | Exact chance per kill, 0 to 1 |
| valid_from_version | text FK | First version the entry applies to |
| valid_to_version | text FK | Last version the entry applies to; null when current |

### ref.xp_levels
| Column | Type | Description |
|---|---|---|
| level | int PK | Character level |
| xp_required | bigint | Total XP needed to reach this level |

### ref.gear_score_caps
| Column | Type | Description |
|---|---|---|
| bracket_min_level | int PK | First level of the bracket |
| bracket_max_level | int | Last level of the bracket |
| max_gear_score | int | Highest gear score allowed in the bracket |

## 3. Game state (`game`)

State at snapshot time. Only items that exist at that moment are in `item_instances`: items
dropped but never looted, and items sold to merchants, appear only in events.

### game.accounts
| Column | Type | Description |
|---|---|---|
| account_id | text PK | Account ID |
| created_at | timestamptz | Account creation |

### game.characters
| Column | Type | Description |
|---|---|---|
| character_id | text PK | Character ID |
| account_id | text FK | Owning account |
| name | text | Character name |
| faction | text | `argent_concord` or `the_wildbound` |
| class_id | text FK | Class |
| level | int | Current level |
| xp | bigint | Current total XP |
| gold | bigint | Current gold |
| zone_id, sub_zone_id | text FK | Current or last location |
| created_at | timestamptz | Character creation |
| last_login_at, last_logout_at | timestamptz | Last session boundaries |

### game.item_instances
| Column | Type | Description |
|---|---|---|
| item_instance_id | text PK | Unique ID of this physical item for its whole life |
| item_template_id | text FK | What the item is |
| holder_type | text | `character` or `auction_house` (escrow while listed) |
| character_id | text FK | Holder; null while in escrow |
| is_equipped | bool | Equipped by the holder |
| is_soulbound | bool | Bound to the holder (set on first equip) |
| cooldown_until | timestamptz | Amulet only: when it can be used again |
| created_at | timestamptz | When the item entered the world |

### game.auctions
Open auctions only.

| Column | Type | Description |
|---|---|---|
| auction_id | text PK | Auction ID |
| item_instance_id | text FK | Item in escrow |
| seller_character_id | text FK | Seller |
| faction | text | Auction house faction |
| buyout_price | bigint | Buyout price in gold |
| created_at, expires_at | timestamptz | Listing time and expiry (48 h later) |

### game.parties
Every party that existed in the window.

| Column | Type | Description |
|---|---|---|
| party_id | text PK | Party ID |
| formed_at | timestamptz | First member joined |
| disbanded_at | timestamptz | Last member left; null while active |

### game.party_members
Every membership in the window. A character can join the same party more than once.

| Column | Type | Description |
|---|---|---|
| party_id | text PK, FK | Party |
| character_id | text PK, FK | Member |
| joined_at | timestamptz PK | When this membership started |
| left_at | timestamptz | When it ended; null while still a member |

## 4. Events (`intake.events`)

One row per event delivery received from the shards.

### 4.1 Envelope columns

| Column | Type | Description |
|---|---|---|
| event_id | bigint PK | Assigned by the intake when it stores a row. Unique per stored row and increasing in storage order. It identifies a delivery, not a game event |
| server_event_id | text | Assigned by the shard when the game event happens. It identifies the game event. If a shard delivers the same game event more than once, every delivery is stored as its own row with its own `event_id`, all sharing the same `server_event_id` |
| event_type | text | Event type; see 4.3 onward |
| schema_version | int | Version of the body shape for this event type |
| game_version | text | Game version live on the shard when the event happened |
| event_ts | timestamptz | When the event happened, as stamped by the shard's clock |
| received_at | timestamptz | When the intake stored the row, stamped by the intake's clock (UTC) |
| server_id | text | Shard that produced the event (`ref.servers`) |
| shard_seq | bigint | Per-shard counter. Each shard numbers the game events it produces consecutively, starting at 1 and increasing by one per event. A repeated delivery of the same game event repeats its `shard_seq` |
| source_batch_id | text | Delivery batch the row arrived in |
| source_file | text | File within the batch |
| body | jsonb | Event-specific fields; see 4.3 onward |

### 4.2 Body conventions

- Every body carries `character_id` and `zone_id` unless noted. `sub_zone_id` is carried where
  the character's position matters (movement, encounters, loot).
- `schema_version` is 1 for every event type except `pvp_damage_dealt` and
  `pvp_damage_received`, which move to version 2 with patch 2.1.
- Every event that changes a character's gold carries `gold_balance_after`, the character's gold
  right after the event.
- `xp_total` on XP events is the character's total XP right after the event.
- IDs are text with a type prefix: `acc_` account, `chr_` character, `itm_` item instance, `tpl_`
  item template, `enc_` encounter, `pty_` party, `auc_` auction, `trd_` trade, `abl_` ability,
  `crt_` creature, `trn_` transport, `mer_` merchant.

### 4.3 Sessions and characters

| event_type | Body fields | Notes |
|---|---|---|
| `character_created` | account_id, character_id, name, faction, class_id, zone_id, amulet_item_instance_id | Amulet is granted here, no loot event (rulebook 3.2) |
| `session_login` | account_id, character_id, zone_id, sub_zone_id | Logs in where it logged out (rulebook 3.5) |
| `session_logout` | account_id, character_id, zone_id, sub_zone_id | |
| `xp_gained` | character_id, zone_id, encounter_id, creature_id, xp_amount, xp_total | One per party member present (rulebook 2.2) |
| `level_up` | character_id, zone_id, new_level, xp_total | |

### 4.4 Movement

| event_type | Body fields | Notes |
|---|---|---|
| `zone_exited` | character_id, zone_id | Walking only |
| `zone_entered` | character_id, zone_id, sub_zone_id | Walking: same timestamp as the preceding `zone_exited`. Also emitted right after every `location_changed` |
| `sub_zone_entered` | character_id, zone_id, sub_zone_id | |
| `sub_zone_exited` | character_id, zone_id, sub_zone_id | |
| `location_changed` | character_id, from_zone_id, to_zone_id, to_sub_zone_id, cause | Every non-walking relocation. cause: `amulet`, `transport`, `respawn` |
| `amulet_cooldown_checked` | character_id, zone_id, item_instance_id, ready, cooldown_until | Step 1 of rulebook 3.2 |
| `amulet_used` | character_id, zone_id, item_instance_id | Step 2. Channel starts |
| `amulet_cooldown_started` | character_id, zone_id, item_instance_id, cooldown_until | Step 3. Step 4 is `location_changed` (cause `amulet`) 10 s after `amulet_used` |
| `transport_boarded` | character_id, zone_id, transport_id | Step 1 of rulebook 3.3. Step 2 is `location_changed` (cause `transport`) |
| `transport_exited` | character_id, zone_id, transport_id | Step 3. travel_time_s after boarding |

Legit walking from Goldmeadow to Ashen Vale:

```json
{"event_type": "zone_entered", "event_ts": "2026-08-12T14:00:00Z", "body": {"character_id": "chr_0412", "zone_id": "goldmeadow", "sub_zone_id": "goldmeadow_mill"}}
{"event_type": "zone_exited",  "event_ts": "2026-08-12T14:07:31Z", "body": {"character_id": "chr_0412", "zone_id": "goldmeadow"}}
{"event_type": "zone_entered", "event_ts": "2026-08-12T14:07:31Z", "body": {"character_id": "chr_0412", "zone_id": "ashen_vale", "sub_zone_id": "ashen_vale_ridge"}}
```

### 4.5 Parties

| event_type | Body fields | Notes |
|---|---|---|
| `party_joined` | character_id, zone_id, party_id | First join forms the party |
| `party_left` | character_id, zone_id, party_id, reason | reason: `left`, `logout`, `disbanded` |

### 4.6 Combat

| event_type                 | Body fields                                                                                                          | Notes                                                                                                                                      |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `encounter_started`        | encounter_id, encounter_kind, character_id, zone_id, sub_zone_id, party_id, creature_id, opponent_character_ids      | One per participating character. kind: `pve`, `pvp`. creature_id for PVE, opponent list for PVP                                            |
| `encounter_ended` | encounter_id, encounter_kind, character_id, zone_id, outcome | One per participant. outcome: `victory`, `death`, `escaped`, `enemy_escaped` (rulebook 5.5) |
| `encounter_damage_summary` | encounter_id, character_id, zone_id, damage_done, damage_received                                                    | Normal and elite PVE only. damage_done: list of {ability_id, attack_type, total}. damage_received: list of {source_type, source_id, total} |
| `ability_used`             | encounter_id, character_id, zone_id, ability_id, target_type, target_id                                              | Boss and PVP only. Global cooldown is implicit (rulebook 5.1)                                                                              |
| `ability_cooldown_started` | encounter_id, character_id, zone_id, ability_id, cooldown_until                                                      | Abilities with their own cooldown                                                                                                          |
| `ability_cooldown_ended`   | character_id, zone_id, ability_id                                                                                    |                                                                                                                                            |
| `pve_damage_dealt`         | encounter_id, character_id, zone_id, ability_id, attack_type, target_creature_id, damage                             | Boss fights, hit by hit. Bosses cannot be crit                                                                                             |
| `pve_damage_received`      | encounter_id, character_id, zone_id, source_creature_id, damage                                                      | Boss fights, every 2 s per targeted character                                                                                              |
| `pvp_damage_dealt`         | v1: encounter_id, character_id, zone_id, ability_id, attack_type, target_character_id, damage. v2 adds `is_critical` | One row per hit, attacker's view                                                                                                           |
| `pvp_damage_received`      | v1: encounter_id, character_id, zone_id, ability_id, attack_type, source_character_id, damage. v2 adds `is_critical` | One row per hit, target's view                                                                                                             |
| `character_died`           | encounter_id, character_id, zone_id, sub_zone_id, killer_type, killer_id                                             | Followed by `location_changed` (cause `respawn`) to the faction hub                                                                        |

PVP v1 vs v2 (the only schema transition, at patch 2.1):

```json
{"event_type": "pvp_damage_dealt", "schema_version": 1, "game_version": "2.0", "body": {"encounter_id": "enc_88213", "character_id": "chr_1044", "zone_id": "scorched_steppes", "ability_id": "abl_rogue_02", "attack_type": "weapon", "target_character_id": "chr_0931", "damage": 1864}}
{"event_type": "pvp_damage_dealt", "schema_version": 2, "game_version": "2.1", "body": {"encounter_id": "enc_91560", "character_id": "chr_1044", "zone_id": "scorched_steppes", "ability_id": "abl_rogue_02", "attack_type": "weapon", "target_character_id": "chr_0931", "damage": 3712, "is_critical": true}}
```

### 4.7 Loot and inventory

| event_type | Body fields | Notes |
|---|---|---|
| `item_dropped` | encounter_id, creature_id, zone_id, sub_zone_id, item_instance_id, item_template_id, assigned_character_id | No character_id: the creature drops it. Instance exists from here (rulebook 6) |
| `item_looted` | encounter_id, character_id, zone_id, sub_zone_id, item_instance_id, item_template_id | Only the assigned character |
| `gold_credited` | encounter_id, character_id, zone_id, creature_id, amount, gold_balance_after | One per party member, full amount |
| `item_equipped` | character_id, zone_id, item_instance_id, item_template_id, slot, is_soulbound | is_soulbound true from first equip on (rulebook 4.3) |
| `item_unequipped` | character_id, zone_id, item_instance_id, item_template_id, slot | Precedes `item_equipped` when the slot was occupied |

### 4.8 Economy

| event_type | Body fields | Notes |
|---|---|---|
| `item_sold` | character_id, zone_id, merchant_id, item_instance_id, item_template_id, price, gold_balance_after | Instance leaves the game |
| `trade_completed` | trade_id, character_id, zone_id, counterpart_character_id, items_given, items_received, gold_given, gold_received, gold_balance_after | One per participant, both sharing trade_id (rulebook 7.2) |
| `auction_created` | auction_id, character_id, zone_id, item_instance_id, item_template_id, buyout_price, expires_at | Item moves to escrow |
| `auction_purchased` | auction_id, character_id, zone_id, seller_character_id, item_instance_id, item_template_id, price, gold_balance_after | Buyer's event |
| `auction_sold` | auction_id, character_id, zone_id, buyer_character_id, item_instance_id, item_template_id, price, auction_cut, gold_balance_after | Seller's event. Receives price minus 5 percent |
| `auction_expired` | auction_id, character_id, zone_id, item_instance_id | Item returns to the seller after 48 h |

