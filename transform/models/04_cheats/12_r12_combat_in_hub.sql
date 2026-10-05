-- R12 Fight started in a capital hub.
SELECT 'R12' AS rule_id, e.character_id, e.event_ts_utc AS occurred_at, e.encounter_id,
       e.encounter_kind || ' fight started in ' || e.zone_id AS detail,
       [e.event_id] AS evidence_event_ids, [e.server_event_id] AS evidence_server_event_ids
FROM staging.stg_events e JOIN raw_ref.zones z USING (zone_id)
WHERE e.event_type = 'encounter_started' AND z.zone_type = 'hub'
