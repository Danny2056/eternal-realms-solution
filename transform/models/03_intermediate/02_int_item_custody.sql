-- Chain of custody for every item instance: one row each time an item changes hands.
-- holder_after = who holds the item after the event (NULL = left the game or went into auction escrow).
-- giver = who handed the item over (for trades, auction listings and merchant sales).
WITH moves AS (
    SELECT item_instance_id, event_ts_utc, event_id, server_event_id, event_type,
           character_id AS holder_after, NULL::VARCHAR AS giver
    FROM staging.stg_events
    WHERE event_type IN ('item_looted', 'auction_purchased', 'auction_expired') AND item_instance_id IS NOT NULL
    UNION ALL
    SELECT unnest(items_given), event_ts_utc, event_id, server_event_id, event_type,
           counterpart_character_id, character_id
    FROM staging.stg_events
    WHERE event_type = 'trade_completed' AND len(items_given) > 0
    UNION ALL
    SELECT item_instance_id, event_ts_utc, event_id, server_event_id, event_type,
           NULL, character_id
    FROM staging.stg_events
    WHERE event_type IN ('auction_created', 'item_sold') AND item_instance_id IS NOT NULL
)
SELECT *,
       lag(holder_after) OVER w AS holder_before,
       row_number()      OVER w AS custody_step
FROM moves
WINDOW w AS (PARTITION BY item_instance_id ORDER BY event_ts_utc, event_id)
