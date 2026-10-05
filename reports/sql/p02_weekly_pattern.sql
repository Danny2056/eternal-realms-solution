-- Weekly pattern: average active players and sessions per day of the week.
WITH daily AS (
    SELECT d.date_day, d.iso_day_of_week, d.day_name,
           count(DISTINCT s.character_id) AS players, count(s.login_at) AS sessions
    FROM marts.dim_date d LEFT JOIN marts.fct_sessions s ON s.session_date = d.date_day
    WHERE d.date_day < DATE '2026-09-10'          -- last day is partial (snapshot taken at end of 10 Sep)
    GROUP BY ALL
)
SELECT iso_day_of_week, day_name, count(*) AS days_observed,
       round(avg(players)) AS avg_active_players, round(avg(sessions)) AS avg_sessions
FROM daily GROUP BY ALL ORDER BY iso_day_of_week
