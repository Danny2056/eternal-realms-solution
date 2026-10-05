-- R13 XP award different from the creature's fixed XP (after the DQ-6 repair; unknown values are skipped).
SELECT 'R13' AS rule_id, e.character_id, e.event_ts_utc AS occurred_at, e.encounter_id,
       'Received ' || e.xp_amount || ' XP from ' || c.name || ', which grants ' || c.xp_reward AS detail,
       [e.event_id] AS evidence_event_ids, [e.server_event_id] AS evidence_server_event_ids
FROM staging.stg_events e JOIN raw_ref.creatures c USING (creature_id)
WHERE e.event_type = 'xp_gained' AND e.xp_amount IS NOT NULL AND e.xp_amount <> c.xp_reward
