-- Zone and sub-zone dimension. Grain: one row per sub-zone (zone attributes repeated).
SELECT s.sub_zone_id, s.name AS sub_zone_name, z.zone_id, z.name AS zone_name, z.zone_type,
       z.faction AS zone_faction, z.min_level, z.max_level, z.server_id
FROM raw_ref.sub_zones s JOIN raw_ref.zones z USING (zone_id)
