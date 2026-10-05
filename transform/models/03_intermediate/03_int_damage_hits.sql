-- Every boss and PVP hit with the attacker's level and the maximum damage the rulebook allows at that level.
-- Max possible hit = (ability base at level + 0.5 x gear-score cap of the bracket) x 1.1 (variance) x 2 (crit).
-- Using the bracket cap (not the actual gear score) makes the limit generous, so it never flags honest players.
SELECT d.event_id, d.server_event_id, d.event_type, d.event_ts_utc, d.encounter_id,
       d.character_id, ch.class_id, l.level,
       d.ability_id, d.attack_type, d.damage, d.is_critical,
       d.target_creature_id, d.target_character_id,
       a.base_damage + a.damage_per_level * l.level AS ability_base_at_level,
       gc.max_gear_score AS gear_score_cap,
       (a.base_damage + a.damage_per_level * l.level + 0.5 * gc.max_gear_score) * 1.1 * 2 AS max_possible_hit
FROM staging.stg_events d
JOIN raw_game.characters ch USING (character_id)
JOIN raw_ref.abilities a USING (ability_id)
ASOF JOIN intermediate.int_character_level_history l
       ON l.character_id = d.character_id AND d.event_ts_utc >= l.valid_from
JOIN raw_ref.gear_score_caps gc ON l.level BETWEEN gc.bracket_min_level AND gc.bracket_max_level
WHERE d.event_type IN ('pve_damage_dealt', 'pvp_damage_dealt') AND d.damage IS NOT NULL
