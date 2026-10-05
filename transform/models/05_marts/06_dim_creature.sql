-- Creature dimension. Grain: one row per creature.
SELECT c.*, z.name AS zone_name FROM raw_ref.creatures c LEFT JOIN raw_ref.zones z USING (zone_id)
