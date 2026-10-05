-- R07 Ability reused during its own cooldown or within the 1.5 s global cooldown.
WITH u AS (
    SELECT e.event_id, e.server_event_id, e.event_ts_utc, e.character_id, e.ability_id, e.encounter_id, a.cooldown_s,
           epoch(e.event_ts_utc) - epoch(lag(e.event_ts_utc) OVER (PARTITION BY e.character_id ORDER BY e.event_ts_utc, e.event_id)) AS gap_any,
           epoch(e.event_ts_utc) - epoch(lag(e.event_ts_utc) OVER (PARTITION BY e.character_id, e.ability_id ORDER BY e.event_ts_utc, e.event_id)) AS gap_same
    FROM staging.stg_events e LEFT JOIN raw_ref.abilities a USING (ability_id)
    WHERE e.event_type = 'ability_used' AND e.character_id IS NOT NULL
)
SELECT 'R07' AS rule_id, character_id, event_ts_utc AS occurred_at, encounter_id,
       ability_id || ' used ' || round(least(gap_any, gap_same), 2) || ' s after the previous use' AS detail,
       [event_id] AS evidence_event_ids, [server_event_id] AS evidence_server_event_ids
FROM u
WHERE gap_any < 1.5 - 0.001 OR (cooldown_s IS NOT NULL AND gap_same < cooldown_s - 0.001)
