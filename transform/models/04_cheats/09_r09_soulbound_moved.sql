-- R09 Soulbound item traded or auctioned (it had been equipped before).
SELECT 'R09' AS rule_id, c.giver AS character_id, c.event_ts_utc AS occurred_at, NULL AS encounter_id,
       c.item_instance_id || ' moved by ' || c.event_type || ' after being equipped on '
         || strftime(eq.event_ts_utc, '%Y-%m-%d %H:%M:%S') AS detail,
       [eq.event_id, c.event_id] AS evidence_event_ids, [eq.server_event_id, c.server_event_id] AS evidence_server_event_ids
FROM intermediate.int_item_custody c
JOIN LATERAL (
    SELECT event_id, server_event_id, event_ts_utc FROM staging.stg_events s
    WHERE s.event_type = 'item_equipped' AND s.item_instance_id = c.item_instance_id AND s.event_ts_utc < c.event_ts_utc
    ORDER BY s.event_ts_utc LIMIT 1
) eq ON TRUE
WHERE c.event_type IN ('trade_completed', 'auction_created')
