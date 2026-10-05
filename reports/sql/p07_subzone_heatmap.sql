-- Heat map of activity per sub-zone: active characters by sub-zone and hour of day (UTC), whole window.
SELECT z.zone_name, z.sub_zone_name, hour(a.activity_hour) AS hour_utc,
       sum(a.events) AS events, round(avg(a.active_characters), 1) AS avg_active_characters
FROM marts.fct_subzone_activity a JOIN marts.dim_zone z USING (sub_zone_id)
GROUP BY ALL ORDER BY z.zone_name, z.sub_zone_name, hour_utc
