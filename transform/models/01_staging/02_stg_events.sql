-- One row per real game event, with trustworthy UTC timestamps and the JSON body unpacked into columns.
--   DQ-1: duplicate deliveries collapsed to one row per server_event_id (first stored copy kept).
--   DQ-3: shard clock faults corrected from stg_clock_corrections; raw event_ts kept for lineage.
--   DQ-4: fields missing from the body stay NULL here; they are recovered downstream where possible.
--   DQ-5: placeholder zone 'zone_unknown' is turned into NULL (unknown); orphan character ids are kept
--         and flagged downstream (character_known = false).
--   DQ-6: corrupted integers in xp_amount, damage, gold amount, price and buyout_price are repaired:
--         negative value  = bitwise NOT of the true value  -> true value is (-v - 1), fully recoverable
--         value >= 2^31   = high bit set with garbage below -> unrecoverable, set to NULL
--         The original value is kept in <col>_raw and the repair type in numeric_repair.
WITH keep AS (
    -- Decide which delivery to keep using only the two narrow id columns (cheap on memory), then join back.
    SELECT server_event_id, min(event_id) AS event_id, count(*) AS delivery_count
    FROM raw_intake.events
    GROUP BY server_event_id
),
dedup AS (
    SELECT r.*, k.delivery_count,
           CASE WHEN c.server_id IS NOT NULL THEN r.event_ts + c.add_to_event_ts ELSE r.event_ts END AS event_ts_utc,
           c.server_id IS NOT NULL AS ts_corrected,
           CAST(r.body AS JSON) AS j
    FROM raw_intake.events r
    JOIN keep k ON k.event_id = r.event_id
    LEFT JOIN staging.stg_clock_corrections c
           ON r.server_id = c.server_id
          AND r.shard_seq >= c.from_shard_seq
          AND (c.to_shard_seq IS NULL OR r.shard_seq <= c.to_shard_seq)
),
parsed AS (
    SELECT *,
           CAST(j->>'xp_amount'    AS BIGINT) AS r_xp_amount,
           CAST(j->>'damage'       AS BIGINT) AS r_damage,
           CAST(j->>'amount'       AS BIGINT) AS r_gold_amount,
           CAST(j->>'price'        AS BIGINT) AS r_price,
           CAST(j->>'buyout_price' AS BIGINT) AS r_buyout_price
    FROM dedup
)
SELECT
    -- lineage back to the source
    event_id, server_event_id, server_id, shard_seq, source_batch_id, source_file, delivery_count,
    -- event identity and time
    event_type, schema_version, game_version,
    event_ts_utc, event_ts AS event_ts_raw, ts_corrected, received_at,
    (j IS NULL OR json_type(j) <> 'OBJECT') AS body_missing,
    -- who and where
    j->>'account_id'              AS account_id,
    j->>'character_id'            AS character_id,
    nullif(j->>'zone_id', 'zone_unknown') AS zone_id,
    j->>'sub_zone_id'             AS sub_zone_id,
    -- character lifecycle and progression
    j->>'name'                    AS character_name,
    j->>'faction'                 AS faction,
    j->>'class_id'                AS class_id,
    j->>'amulet_item_instance_id' AS amulet_item_instance_id,
    repair_int(r_xp_amount) AS xp_amount, r_xp_amount AS xp_amount_raw,
    CAST(j->>'xp_total'  AS BIGINT) AS xp_total,
    nullif(CAST(j->>'new_level' AS INT), 0) AS new_level,   -- DQ-7: level 0 is impossible, treated as unknown
    -- movement
    nullif(j->>'from_zone_id', 'zone_unknown') AS from_zone_id,
    nullif(j->>'to_zone_id', 'zone_unknown') AS to_zone_id,
    j->>'to_sub_zone_id'          AS to_sub_zone_id,
    j->>'cause'                   AS cause,
    j->>'transport_id'            AS transport_id,
    CAST(j->>'ready' AS BOOLEAN)  AS amulet_ready,
    CAST(j->>'cooldown_until' AS TIMESTAMPTZ) AS cooldown_until_raw,
    -- party
    j->>'party_id'                AS party_id,
    j->>'reason'                  AS reason,
    -- combat
    j->>'encounter_id'            AS encounter_id,
    j->>'encounter_kind'          AS encounter_kind,
    j->>'outcome'                 AS outcome,
    j->>'creature_id'             AS creature_id,
    CAST(j->'opponent_character_ids' AS VARCHAR[]) AS opponent_character_ids,
    j->>'ability_id'              AS ability_id,
    j->>'attack_type'             AS attack_type,
    j->>'target_type'             AS target_type,
    j->>'target_id'               AS target_id,
    j->>'target_creature_id'      AS target_creature_id,
    j->>'target_character_id'     AS target_character_id,
    j->>'source_creature_id'      AS source_creature_id,
    j->>'source_character_id'     AS source_character_id,
    repair_int(r_damage) AS damage, r_damage AS damage_raw,
    CAST(j->>'is_critical' AS BOOLEAN) AS is_critical,
    j->>'killer_type'             AS killer_type,
    j->>'killer_id'               AS killer_id,
    CASE WHEN event_type = 'encounter_damage_summary' THEN j->'damage_done'     END AS summary_damage_done,
    CASE WHEN event_type = 'encounter_damage_summary' THEN j->'damage_received' END AS summary_damage_received,
    -- items, loot and gold
    j->>'item_instance_id'        AS item_instance_id,
    j->>'item_template_id'        AS item_template_id,
    j->>'assigned_character_id'   AS assigned_character_id,
    j->>'slot'                    AS slot,
    CAST(j->>'is_soulbound' AS BOOLEAN) AS is_soulbound,
    repair_int(r_gold_amount) AS gold_amount, r_gold_amount AS gold_amount_raw,
    CAST(j->>'gold_balance_after' AS BIGINT) AS gold_balance_after,
    -- economy
    j->>'merchant_id'             AS merchant_id,
    repair_int(r_price) AS price, r_price AS price_raw,
    j->>'trade_id'                AS trade_id,
    j->>'counterpart_character_id' AS counterpart_character_id,
    CAST(j->'items_given'    AS VARCHAR[]) AS items_given,
    CAST(j->'items_received' AS VARCHAR[]) AS items_received,
    CAST(j->>'gold_given'    AS BIGINT) AS gold_given,
    CAST(j->>'gold_received' AS BIGINT) AS gold_received,
    j->>'auction_id'              AS auction_id,
    repair_int(r_buyout_price) AS buyout_price, r_buyout_price AS buyout_price_raw,
    CAST(j->>'expires_at' AS TIMESTAMPTZ) AS expires_at_raw,
    j->>'seller_character_id'     AS seller_character_id,
    j->>'buyer_character_id'      AS buyer_character_id,
    CAST(j->>'auction_cut' AS BIGINT) AS auction_cut,
    CASE WHEN least(r_xp_amount, r_damage, r_gold_amount, r_price, r_buyout_price) < 0 THEN 'bitflip_recovered'
         WHEN greatest(r_xp_amount, r_damage, r_gold_amount, r_price, r_buyout_price) >= 2147483648 THEN 'overflow_nulled'
    END AS numeric_repair,
    body AS body_raw
FROM parsed
