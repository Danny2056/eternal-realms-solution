-- Player activity over time: daily active players and sessions.
SELECT d.date_day, d.day_name,
       count(DISTINCT s.character_id) AS daily_active_players,
       count(s.login_at) AS sessions,
       round(sum(s.duration_s) / 3600, 1) AS hours_played
FROM marts.dim_date d
LEFT JOIN marts.fct_sessions s ON s.session_date = d.date_day
GROUP BY ALL ORDER BY d.date_day
