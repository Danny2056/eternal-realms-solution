-- Item template dimension. Grain: one row per item template, allowed classes as a list.
SELECT t.*, (SELECT list(class_id ORDER BY class_id) FROM raw_ref.item_template_classes c
             WHERE c.item_template_id = t.item_template_id) AS allowed_classes
FROM raw_ref.item_templates t
