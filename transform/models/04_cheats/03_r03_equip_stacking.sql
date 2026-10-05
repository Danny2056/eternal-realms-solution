-- R03 Equip stacking: an equip into a slot whose previous equip/unequip event was also an equip,
-- less than one second earlier (so nothing was taken off in between).
WITH e AS (
    SELECT event_id, server_event_id, event_type, event_ts_utc, character_id, slot, item_instance_id,
           lag(event_type)      OVER w AS prev_type,
           lag(event_ts_utc)    OVER w AS prev_ts,
           lag(event_id)        OVER w AS prev_event_id,
           lag(server_event_id) OVER w AS prev_server_event_id
    FROM staging.stg_events
    WHERE event_type IN ('item_equipped', 'item_unequipped') AND character_id IS NOT NULL AND slot IS NOT NULL
    WINDOW w AS (PARTITION BY character_id, slot ORDER BY event_ts_utc, event_id)
)
SELECT 'R03' AS rule_id, character_id, event_ts_utc AS occurred_at, NULL AS encounter_id,
       'Equipped ' || item_instance_id || ' in ' || slot || ' '
         || round(epoch(event_ts_utc) - epoch(prev_ts), 3) || ' s after the previous equip, without unequipping' AS detail,
       [prev_event_id, event_id] AS evidence_event_ids,
       [prev_server_event_id, server_event_id] AS evidence_server_event_ids
FROM e
WHERE event_type = 'item_equipped' AND prev_type = 'item_equipped'
  AND epoch(event_ts_utc) - epoch(prev_ts) < 1.0
