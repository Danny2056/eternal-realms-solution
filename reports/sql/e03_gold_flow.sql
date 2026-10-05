-- Gold flow: gold entering the economy (creature drops, merchant sales by rarity) vs gold leaving it
-- (auction house cut), and the net result. Player-to-player transfers do not change the total and are excluded.
WITH flows AS (
    SELECT CASE WHEN movement = 'merchant_sale' THEN 'merchant_sale_' || coalesce(item_rarity, 'unknown')
                ELSE movement END AS line, flow_type, sum(amount) AS gold
    FROM marts.fct_gold_ledger WHERE flow_type IN ('source', 'sink')
    GROUP BY ALL
)
SELECT flow_type, line, gold FROM flows
UNION ALL SELECT 'total', 'gold_in',  sum(gold) FROM flows WHERE flow_type = 'source'
UNION ALL SELECT 'total', 'gold_out', sum(gold) FROM flows WHERE flow_type = 'sink'
UNION ALL SELECT 'total', 'net',      sum(gold) FROM flows
ORDER BY flow_type DESC, gold DESC
