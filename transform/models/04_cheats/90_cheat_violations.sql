-- Every rule violation in one table, with the rule's description and the evidence trail back to the raw events.
-- evidence_event_ids  -> raw_intake.events.event_id (the delivery that was kept)
-- evidence_server_event_ids -> the shard's own id for the game event
WITH v AS (
    SELECT * FROM cheats.r01_burst_damage
    UNION ALL SELECT * FROM cheats.r02_item_duplication
    UNION ALL SELECT * FROM cheats.r03_equip_stacking
    UNION ALL SELECT * FROM cheats.r04_speed_hack
    UNION ALL SELECT * FROM cheats.r05_gear_above_level
    UNION ALL SELECT * FROM cheats.r06_hit_above_max
    UNION ALL SELECT * FROM cheats.r07_ability_cooldown
    UNION ALL SELECT * FROM cheats.r08_amulet_cooldown
    UNION ALL SELECT * FROM cheats.r09_soulbound_moved
    UNION ALL SELECT * FROM cheats.r10_illegal_trade
    UNION ALL SELECT * FROM cheats.r11_transport_misuse
    UNION ALL SELECT * FROM cheats.r12_combat_in_hub
    UNION ALL SELECT * FROM cheats.r13_wrong_xp
)
SELECT row_number() OVER (ORDER BY v.occurred_at, v.rule_id) AS violation_id,
       v.rule_id, r.rule_name, r.category, r.severity, r.rulebook_section,
       v.character_id, ch.account_id, ch.faction, ch.class_id,
       v.occurred_at, v.encounter_id, v.detail,
       v.evidence_event_ids, v.evidence_server_event_ids,
       ch.character_id IS NOT NULL AS character_known
FROM v
JOIN cheats.cheat_rule_catalog r USING (rule_id)
LEFT JOIN raw_game.characters ch ON ch.character_id = v.character_id
