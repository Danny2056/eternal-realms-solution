-- Damage per second percentile within the peer group. DPS is measured per character and per level bracket
-- over the fights it won (damage done / fight duration), so a character is compared with peers at the level it
-- had when it fought. Confirmed cheaters are excluded from the peer group.
WITH dps AS (
    SELECT f.character_id, c.class_name, f.bracket_min_level,
           sum(f.damage_done) / nullif(sum(f.duration_s), 0) AS dps, count(*) AS fights
    FROM marts.fct_encounter_participation f JOIN marts.dim_character c USING (character_id)
    WHERE f.outcome = 'victory' AND f.duration_s > 0 AND f.damage_done IS NOT NULL AND NOT c.is_confirmed_cheater
    GROUP BY ALL HAVING count(*) >= 10
),
ranked AS (
    SELECT *, count(*) OVER (PARTITION BY class_name, bracket_min_level) - 1 AS peer_count,
           rank() OVER (PARTITION BY class_name, bracket_min_level ORDER BY dps) - 1 AS peers_below
    FROM dps
)
SELECT character_id, class_name, bracket_min_level || '-' || (bracket_min_level + 9) AS level_bracket,
       round(dps, 1) AS dps, fights, peer_count,
       round(100.0 * peers_below / nullif(peer_count, 0)) AS dps_percentile,
       'Your damage per second is higher than ' || coalesce(round(100.0 * peers_below / nullif(peer_count, 0)), 0)::INT
         || '% of other ' || class_name || 's between levels ' || bracket_min_level || ' and '
         || (bracket_min_level + 9) || '.' AS player_message
FROM ranked
ORDER BY class_name, bracket_min_level, dps DESC
