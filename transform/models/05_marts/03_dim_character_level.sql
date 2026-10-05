-- Slowly changing dimension: the level a character held between valid_from and valid_to, with its
-- 10-level peer bracket. Join any fact on character_id and event time to get the level at that moment.
SELECT character_id, level, valid_from, valid_to, bracket_min_level, bracket_max_level,
       bracket_min_level || '-' || bracket_max_level AS bracket_label
FROM intermediate.int_character_level_history
