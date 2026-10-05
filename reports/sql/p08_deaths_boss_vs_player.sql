-- Players killed by bosses vs players killed by other players (other creatures shown for completeness).
-- Every category is listed even when it has no deaths: bosses killed nobody during the window (see anomalies).
WITH cats(killer_category, sort) AS (VALUES ('boss', 1), ('player', 2), ('creature', 3), ('unknown', 4))
SELECT c.killer_category, count(d.event_id) AS deaths,
       round(100.0 * count(d.event_id) / sum(count(d.event_id)) OVER (), 1) AS pct
FROM cats c LEFT JOIN marts.fct_deaths d USING (killer_category)
GROUP BY c.killer_category, c.sort ORDER BY c.sort
