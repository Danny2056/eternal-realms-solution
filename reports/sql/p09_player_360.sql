-- Player 360: total time played, average XP per day, current gear score and its percentile in the peer group
-- (same class, same 10-level bracket, both factions). Confirmed cheaters are excluded from the peer group.
-- Change the character in the last line to look up another player.
WITH played AS (
    SELECT character_id, sum(duration_s) / 3600 AS hours_played, count(DISTINCT session_date) AS days_played
    FROM marts.fct_sessions GROUP BY 1
),
xp AS (
    SELECT character_id, sum(xp_amount) AS xp_earned, count(DISTINCT xp_date) AS xp_days FROM marts.fct_xp GROUP BY 1
),
peers AS (
    SELECT g.*, c.class_name, c.character_name,
           (SELECT count(*) FROM marts.fct_character_gear p JOIN marts.dim_character pc USING (character_id)
             WHERE p.class_id = g.class_id AND p.bracket_min_level = g.bracket_min_level
               AND p.character_id <> g.character_id AND NOT pc.is_confirmed_cheater) AS peer_count,
           (SELECT count(*) FROM marts.fct_character_gear p JOIN marts.dim_character pc USING (character_id)
             WHERE p.class_id = g.class_id AND p.bracket_min_level = g.bracket_min_level
               AND p.character_id <> g.character_id AND NOT pc.is_confirmed_cheater
               AND p.gear_score < g.gear_score) AS peers_below
    FROM marts.fct_character_gear g JOIN marts.dim_character c USING (character_id)
)
SELECT p.character_id, p.character_name, p.class_name, p.current_level,
       round(coalesce(pl.hours_played, 0), 1) AS total_hours_played,
       coalesce(pl.days_played, 0) AS days_played,
       round(coalesce(x.xp_earned, 0) / nullif(pl.days_played, 0)) AS avg_xp_per_day_played,
       p.gear_score, p.peer_count,
       round(100.0 * p.peers_below / nullif(p.peer_count, 0)) AS gear_percentile,
       'Your gear is better than ' || coalesce(round(100.0 * p.peers_below / nullif(p.peer_count, 0)), 0)::INT
         || '% of other ' || p.class_name || 's between levels ' || p.bracket_min_level || ' and '
         || (p.bracket_min_level + 9) || '.' AS player_message
FROM peers p LEFT JOIN played pl USING (character_id) LEFT JOIN xp x USING (character_id)
-- Example: chr_1696, the most active player of the month.
WHERE p.character_id = 'chr_1696'
