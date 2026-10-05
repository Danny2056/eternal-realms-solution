-- R05 Gear above level: equipped item requires at least 2 levels more than the character had.
-- (A 1-level gap happens when the equip and the level-up share the same second, so it is not flagged.)
WITH tpl AS (   -- recover the item template from any event that names it (DQ-4)
    SELECT item_instance_id, any_value(item_template_id) AS item_template_id
    FROM staging.stg_events
    WHERE item_instance_id IS NOT NULL AND item_template_id IS NOT NULL
    GROUP BY 1
)
SELECT 'R05' AS rule_id, e.character_id, e.event_ts_utc AS occurred_at, NULL AS encounter_id,
       'Equipped ' || t.name || ' (requires level ' || t.level_requirement || ') at level ' || l.level AS detail,
       [e.event_id] AS evidence_event_ids, [e.server_event_id] AS evidence_server_event_ids
FROM staging.stg_events e
JOIN tpl ON tpl.item_instance_id = e.item_instance_id
JOIN raw_ref.item_templates t ON t.item_template_id = coalesce(e.item_template_id, tpl.item_template_id)
ASOF JOIN intermediate.int_character_level_history l
       ON l.character_id = e.character_id AND e.event_ts_utc >= l.valid_from
WHERE e.event_type = 'item_equipped' AND t.level_requirement - l.level >= 2
