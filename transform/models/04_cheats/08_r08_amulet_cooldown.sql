-- R08 Amulet used again within 60 minutes.
WITH u AS (
    SELECT event_id, server_event_id, event_ts_utc, character_id,
           lag(event_ts_utc) OVER (PARTITION BY character_id ORDER BY event_ts_utc) AS prev_ts,
           lag(event_id)     OVER (PARTITION BY character_id ORDER BY event_ts_utc) AS prev_event_id,
           lag(server_event_id) OVER (PARTITION BY character_id ORDER BY event_ts_utc) AS prev_server_event_id
    FROM staging.stg_events WHERE event_type = 'amulet_used' AND character_id IS NOT NULL
)
SELECT 'R08' AS rule_id, character_id, event_ts_utc AS occurred_at, NULL AS encounter_id,
       'Amulet used ' || round((epoch(event_ts_utc) - epoch(prev_ts)) / 60, 1) || ' min after the previous use' AS detail,
       [prev_event_id, event_id] AS evidence_event_ids, [prev_server_event_id, server_event_id] AS evidence_server_event_ids
FROM u WHERE epoch(event_ts_utc) - epoch(prev_ts) < 3600
