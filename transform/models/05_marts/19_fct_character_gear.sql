-- Grain: one row per character: gear currently equipped at snapshot time and the resulting gear score,
-- capped per the gear-score table for the character's bracket (rulebook 4.2).
WITH eq AS (
    SELECT i.character_id, sum(t.item_level) AS raw_gear_score, count(*) AS equipped_items
    FROM raw_game.item_instances i JOIN raw_ref.item_templates t USING (item_template_id)
    WHERE i.is_equipped AND t.item_kind = 'gear' AND i.character_id IS NOT NULL
    GROUP BY 1
)
SELECT c.character_id, c.class_id, c.current_level, c.current_bracket_min_level AS bracket_min_level,
       coalesce(eq.equipped_items, 0) AS equipped_items, coalesce(eq.raw_gear_score, 0) AS raw_gear_score,
       least(coalesce(eq.raw_gear_score, 0), g.max_gear_score) AS gear_score, g.max_gear_score AS bracket_cap
FROM marts.dim_character c
LEFT JOIN eq USING (character_id)
JOIN raw_ref.gear_score_caps g ON c.current_level BETWEEN g.bracket_min_level AND g.bracket_max_level
