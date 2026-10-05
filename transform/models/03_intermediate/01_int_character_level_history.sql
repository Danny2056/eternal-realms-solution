-- Level of every character over time (one row per level held, with valid_from / valid_to).
-- Built from level_up events. The level before the first level-up in the window is (first new_level - 1);
-- characters with no level-up keep their snapshot level for the whole window.
-- Level-ups with an unknown level (DQ-7) are ignored, so they cannot create a false "level 0".
WITH ups AS (
    SELECT character_id, event_ts_utc AS valid_from, new_level AS level
    FROM staging.stg_events
    WHERE event_type = 'level_up' AND character_id IS NOT NULL AND new_level IS NOT NULL
),
first_up AS (
    SELECT character_id, arg_min(level, valid_from) - 1 AS level FROM ups GROUP BY 1
),
segments AS (
    SELECT character_id, valid_from, level FROM ups
    UNION ALL
    SELECT character_id, TIMESTAMPTZ '2000-01-01 00:00:00+00', level FROM first_up
    UNION ALL
    SELECT c.character_id, TIMESTAMPTZ '2000-01-01 00:00:00+00', c.level
    FROM raw_game.characters c
    WHERE NOT EXISTS (SELECT 1 FROM ups u WHERE u.character_id = c.character_id)
)
SELECT character_id,
       level,
       valid_from,
       coalesce(lead(valid_from) OVER (PARTITION BY character_id ORDER BY valid_from, level),
                TIMESTAMPTZ '2100-01-01 00:00:00+00') AS valid_to,
       ((level - 1) // 10) * 10 + 1 AS bracket_min_level,
       ((level - 1) // 10) * 10 + 10 AS bracket_max_level
FROM segments
