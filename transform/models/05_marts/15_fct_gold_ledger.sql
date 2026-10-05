-- Grain: one row per gold movement for a character, signed (+ in, - out).
-- flow_type tells whether gold enters the economy (source), leaves it (sink) or moves between players (transfer).
WITH sold AS (
    SELECT e.*, t.rarity FROM staging.stg_events e
    LEFT JOIN raw_ref.item_templates t ON t.item_template_id = e.item_template_id
    WHERE e.event_type = 'item_sold'
)
SELECT event_id, event_ts_utc, CAST(event_ts_utc AS DATE) AS ledger_date, character_id,
       'creature_drop' AS movement, 'source' AS flow_type, gold_amount AS amount, NULL AS item_rarity
FROM staging.stg_events WHERE event_type = 'gold_credited'
UNION ALL
SELECT event_id, event_ts_utc, CAST(event_ts_utc AS DATE), character_id, 'merchant_sale', 'source', price, rarity FROM sold
UNION ALL
SELECT event_id, event_ts_utc, CAST(event_ts_utc AS DATE), character_id, 'trade', 'transfer',
       gold_received - gold_given, NULL
FROM staging.stg_events WHERE event_type = 'trade_completed' AND (gold_received <> 0 OR gold_given <> 0)
UNION ALL
SELECT event_id, event_ts_utc, CAST(event_ts_utc AS DATE), character_id, 'auction_purchase', 'transfer', -price, NULL
FROM staging.stg_events WHERE event_type = 'auction_purchased'
UNION ALL
SELECT event_id, event_ts_utc, CAST(event_ts_utc AS DATE), character_id, 'auction_sale', 'transfer', price - auction_cut, NULL
FROM staging.stg_events WHERE event_type = 'auction_sold'
UNION ALL   -- the auction house keeps 5 %: this gold leaves the economy
SELECT event_id, event_ts_utc, CAST(event_ts_utc AS DATE), NULL, 'auction_house_cut', 'sink', -auction_cut, NULL
FROM staging.stg_events WHERE event_type = 'auction_sold'
