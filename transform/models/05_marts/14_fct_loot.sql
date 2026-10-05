-- Grain: one row per item looted. Template recovered from the drop when the loot event lost it (DQ-4).
WITH drops AS (
    SELECT item_instance_id, any_value(item_template_id) AS item_template_id, any_value(creature_id) AS creature_id
    FROM staging.stg_events WHERE event_type = 'item_dropped' AND item_instance_id IS NOT NULL GROUP BY 1
)
SELECT l.event_id, l.server_event_id, l.event_ts_utc AS looted_at, CAST(l.event_ts_utc AS DATE) AS loot_date,
       l.character_id, l.encounter_id, d.creature_id, l.zone_id, l.sub_zone_id, l.item_instance_id,
       coalesce(l.item_template_id, d.item_template_id) AS item_template_id, t.rarity, t.item_level, t.slot
FROM staging.stg_events l
LEFT JOIN drops d USING (item_instance_id)
LEFT JOIN raw_ref.item_templates t ON t.item_template_id = coalesce(l.item_template_id, d.item_template_id)
WHERE l.event_type = 'item_looted'
