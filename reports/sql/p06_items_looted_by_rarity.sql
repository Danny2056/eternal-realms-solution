-- Items looted by day, broken down by item rarity.
PIVOT (SELECT loot_date, coalesce(rarity, 'unknown') AS rarity FROM marts.fct_loot)
ON rarity IN ('common', 'uncommon', 'rare', 'epic', 'legendary', 'unknown')
USING count(*) GROUP BY loot_date ORDER BY loot_date
