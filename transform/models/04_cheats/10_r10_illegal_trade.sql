-- R10 Trade between different factions or different zones (checked on both sides of the trade).
SELECT 'R10' AS rule_id, a.character_id, a.event_ts_utc AS occurred_at, NULL AS encounter_id,
       'Trade ' || a.trade_id || ' with ' || b.character_id || ': factions ' || ca.faction || '/' || cb.faction
         || ', zones ' || a.zone_id || '/' || b.zone_id AS detail,
       [a.event_id, b.event_id] AS evidence_event_ids, [a.server_event_id, b.server_event_id] AS evidence_server_event_ids
FROM staging.stg_events a
JOIN staging.stg_events b ON b.trade_id = a.trade_id AND b.event_type = 'trade_completed' AND b.character_id > a.character_id
JOIN raw_game.characters ca ON ca.character_id = a.character_id
JOIN raw_game.characters cb ON cb.character_id = b.character_id
WHERE a.event_type = 'trade_completed' AND (ca.faction <> cb.faction OR a.zone_id <> b.zone_id)
