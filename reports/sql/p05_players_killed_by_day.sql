-- Players killed by day.
SELECT death_date, count(*) AS players_killed, count(DISTINCT character_id) AS distinct_victims
FROM marts.fct_deaths GROUP BY 1 ORDER BY 1
