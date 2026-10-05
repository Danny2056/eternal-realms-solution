-- Number of items sold to merchants, broken down by item rarity.
SELECT coalesce(t.rarity, 'unknown') AS rarity, count(*) AS items_sold, sum(x.gold_amount) AS gold_paid
FROM marts.fct_economy_transactions x
LEFT JOIN marts.dim_item_template t USING (item_template_id)
WHERE x.transaction_type = 'merchant_sale'
GROUP BY 1
ORDER BY CASE coalesce(t.rarity, 'unknown') WHEN 'common' THEN 1 WHEN 'uncommon' THEN 2 WHEN 'rare' THEN 3 WHEN 'epic' THEN 4
                     WHEN 'legendary' THEN 5 ELSE 6 END
