-- Grain: one row per XP award.
SELECT event_id, event_ts_utc, CAST(event_ts_utc AS DATE) AS xp_date, character_id, encounter_id,
       creature_id, zone_id, xp_amount, xp_total
FROM staging.stg_events WHERE event_type = 'xp_gained'
