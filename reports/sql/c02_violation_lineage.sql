-- Lineage: trace every piece of evidence for one violation back to the raw delivered rows.
-- Change the violation_id to inspect another violation (see cheats.cheat_violations).
SELECT v.violation_id, v.rule_name, v.character_id, v.detail,
       r.event_id, r.server_event_id, r.server_id, r.shard_seq, r.source_batch_id, r.source_file,
       r.event_type, r.event_ts AS event_ts_as_delivered, r.body
FROM cheats.cheat_violations v, unnest(v.evidence_event_ids) AS u(event_id)
JOIN raw_intake.events r ON r.event_id = u.event_id
WHERE v.violation_id = 23
ORDER BY r.event_id
