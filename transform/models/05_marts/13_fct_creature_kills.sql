-- Grain: one row per creature killed (a PVE encounter that at least one participant won).
SELECT encounter_id, any_value(creature_id) AS creature_id, any_value(creature_rank) AS creature_rank,
       any_value(zone_id) AS zone_id, any_value(sub_zone_id) AS sub_zone_id,
       max(ended_at) AS killed_at, CAST(max(ended_at) AS DATE) AS kill_date,
       count(*) AS participants, max(duration_s) AS fight_duration_s
FROM marts.fct_encounter_participation
WHERE encounter_kind = 'pve' AND outcome = 'victory'
GROUP BY encounter_id
