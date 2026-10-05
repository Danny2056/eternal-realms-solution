-- R06 Hit above maximum damage (bosses cannot be critically hit, so their limit has no x2).
SELECT 'R06' AS rule_id, character_id, event_ts_utc AS occurred_at, encounter_id,
       'Hit for ' || damage || ', maximum possible ' || round(max_possible_hit) AS detail,
       [event_id] AS evidence_event_ids, [server_event_id] AS evidence_server_event_ids
FROM intermediate.int_damage_hits
WHERE damage > CASE WHEN event_type = 'pve_damage_dealt' THEN max_possible_hit / 2 ELSE max_possible_hit END
