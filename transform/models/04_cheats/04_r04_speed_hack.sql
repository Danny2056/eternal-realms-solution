-- R04 Speed hack: consecutive zone entries by walking between adjacent zones faster than distance / 7 m/s.
WITH p AS (
    SELECT event_id, server_event_id, event_type, event_ts_utc, character_id, zone_id,
           lag(event_type)      OVER w AS prev_type,
           lag(zone_id)         OVER w AS prev_zone,
           lag(event_ts_utc)    OVER w AS prev_ts,
           lag(event_id)        OVER w AS prev_event_id,
           lag(server_event_id) OVER w AS prev_server_event_id
    FROM staging.stg_events
    WHERE event_type IN ('zone_entered', 'location_changed', 'session_login')
      AND character_id IS NOT NULL AND zone_id IS NOT NULL
    WINDOW w AS (PARTITION BY character_id ORDER BY event_ts_utc, event_type = 'zone_entered', shard_seq)
)
SELECT 'R04' AS rule_id, p.character_id, p.event_ts_utc AS occurred_at, NULL AS encounter_id,
       'Walked ' || p.prev_zone || ' -> ' || p.zone_id || ' in ' || round(epoch(p.event_ts_utc) - epoch(p.prev_ts))
         || ' s; minimum is ' || round(a.min_distance_m / 7.0) || ' s (' || a.min_distance_m || ' m at 7 m/s)' AS detail,
       [p.prev_event_id, p.event_id] AS evidence_event_ids,
       [p.prev_server_event_id, p.server_event_id] AS evidence_server_event_ids
FROM p
JOIN raw_ref.zone_adjacency a ON a.zone_a_id = p.prev_zone AND a.zone_b_id = p.zone_id
WHERE p.event_type = 'zone_entered' AND p.prev_type = 'zone_entered'
  AND epoch(p.event_ts_utc) - epoch(p.prev_ts) < a.min_distance_m / 7.0
