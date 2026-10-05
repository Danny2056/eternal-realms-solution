-- Creatures killed by day, split by creature rank.
SELECT kill_date, count(*) AS creatures_killed,
       count(*) FILTER (WHERE creature_rank = 'normal') AS normal,
       count(*) FILTER (WHERE creature_rank = 'elite')  AS elite,
       count(*) FILTER (WHERE creature_rank = 'boss')   AS boss
FROM marts.fct_creature_kills GROUP BY 1 ORDER BY 1
