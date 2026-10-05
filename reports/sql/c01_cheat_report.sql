-- Cheat report: who cheated, what rules they broke, and the vulnerable mechanics.
SELECT o.character_id, o.account_id, c.character_name, c.class_name, o.violations, o.rules_broken,
       o.first_violation_at, o.last_violation_at
FROM cheats.cheat_offenders o JOIN marts.dim_character c USING (character_id)
WHERE o.confirmed_cheater ORDER BY o.violations DESC
