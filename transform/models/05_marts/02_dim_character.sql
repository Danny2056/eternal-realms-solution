-- Character dimension (current state at snapshot) with account and cheat flag.
-- Grain: one row per character. Level over time lives in dim_character_level (slowly changing).
SELECT c.character_id, c.name AS character_name, c.account_id, a.created_at AS account_created_at,
       c.faction, c.class_id, cl.name AS class_name, cl.armor_type, cl.crit_chance,
       c.level AS current_level,
       ((c.level - 1) // 10) * 10 + 1 AS current_bracket_min_level,
       c.xp AS current_xp, c.gold AS current_gold,
       c.zone_id AS last_zone_id, c.sub_zone_id AS last_sub_zone_id,
       c.created_at, c.last_login_at, c.last_logout_at,
       coalesce(o.confirmed_cheater, false) AS is_confirmed_cheater
FROM raw_game.characters c
JOIN raw_game.accounts a USING (account_id)
JOIN raw_ref.classes cl USING (class_id)
LEFT JOIN cheats.cheat_offenders o USING (character_id)
