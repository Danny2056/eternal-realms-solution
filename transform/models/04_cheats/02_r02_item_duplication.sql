-- R02 Item duplication: a character hands over an item it had already handed to someone else
-- and never got back (it gave the item away earlier, and the item's last holder is someone else).
SELECT 'R02' AS rule_id, c.giver AS character_id, c.event_ts_utc AS occurred_at, NULL AS encounter_id,
       'Gave ' || c.item_instance_id || ' (' || c.event_type || ') while ' || c.holder_before
         || ' held it; first given away at ' || strftime(prev.event_ts_utc, '%Y-%m-%d %H:%M:%S') AS detail,
       [prev.event_id, c.event_id] AS evidence_event_ids,
       [prev.server_event_id, c.server_event_id] AS evidence_server_event_ids
FROM intermediate.int_item_custody c
JOIN LATERAL (
    SELECT p.event_id, p.server_event_id, p.event_ts_utc
    FROM intermediate.int_item_custody p
    WHERE p.item_instance_id = c.item_instance_id AND p.giver = c.giver
      AND p.custody_step < c.custody_step
    ORDER BY p.custody_step DESC LIMIT 1
) prev ON TRUE
WHERE c.giver IS NOT NULL AND c.holder_before IS NOT NULL AND c.holder_before <> c.giver
