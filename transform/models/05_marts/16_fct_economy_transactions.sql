-- Grain: one row per completed transaction (merchant sale, player trade, auction sale).
-- Trades and auctions are logged once per side; here each transaction is counted once.
-- transaction_date is the plain date of transacted_at, the key to dim_date.
SELECT *, CAST(transacted_at AS DATE) AS transaction_date FROM (
SELECT 'merchant_sale' AS transaction_type, event_id, event_ts_utc AS transacted_at, character_id,
       NULL AS counterpart_character_id, item_instance_id, item_template_id, price AS gold_amount, merchant_id AS venue
FROM staging.stg_events WHERE event_type = 'item_sold'
UNION ALL
SELECT 'trade', min(event_id), min(event_ts_utc), min(character_id), max(character_id), NULL, NULL,
       sum(gold_given), any_value(zone_id)
FROM staging.stg_events WHERE event_type = 'trade_completed' AND trade_id IS NOT NULL GROUP BY trade_id
UNION ALL
SELECT 'auction_sale', event_id, event_ts_utc, character_id, buyer_character_id, item_instance_id, item_template_id,
       price, zone_id
FROM staging.stg_events WHERE event_type = 'auction_sold'
)
