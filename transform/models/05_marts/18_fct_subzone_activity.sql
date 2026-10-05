-- Grain: one row per sub-zone per hour: how many events and distinct characters were active there.
-- Uses every event that names a sub-zone (movement, fights, loot) as a presence signal; feeds the heat map.
SELECT date_trunc('hour', e.event_ts_utc) AS activity_hour, CAST(e.event_ts_utc AS DATE) AS activity_date, e.sub_zone_id, z.zone_id,
       count(*) AS events, count(DISTINCT e.character_id) AS active_characters
FROM staging.stg_events e JOIN marts.dim_zone z USING (sub_zone_id)
WHERE e.sub_zone_id IS NOT NULL
GROUP BY ALL
