-- Grain: one row per character death. killer_category separates PVP, bosses and other creatures.
SELECT d.event_id, d.server_event_id, d.event_ts_utc AS died_at, CAST(d.event_ts_utc AS DATE) AS death_date,
       d.character_id, d.encounter_id, d.zone_id, d.sub_zone_id, d.killer_type, d.killer_id,
       CASE WHEN d.killer_type = 'character' OR (d.killer_type IS NULL AND d.killer_id LIKE 'chr_%') THEN 'player'   -- DQ-4: type lost, id survives
            WHEN cr.rank = 'boss' THEN 'boss'
            WHEN d.killer_type = 'creature' THEN 'creature'
            ELSE 'unknown' END AS killer_category
FROM staging.stg_events d
LEFT JOIN raw_ref.creatures cr ON cr.creature_id = d.killer_id
WHERE d.event_type = 'character_died'
