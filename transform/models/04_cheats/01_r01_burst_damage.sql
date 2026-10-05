-- R01 Burst damage: more than one hit by the same attacker in the same encounter at the same instant.
SELECT 'R01' AS rule_id, character_id, event_ts_utc AS occurred_at, encounter_id,
       count(*) || ' hits at the same instant, ' || sum(damage) || ' damage on '
         || coalesce(any_value(target_character_id), any_value(target_creature_id)) AS detail,
       list(event_id ORDER BY event_id) AS evidence_event_ids,
       list(server_event_id ORDER BY event_id) AS evidence_server_event_ids
FROM intermediate.int_damage_hits
GROUP BY character_id, encounter_id, event_ts_utc
HAVING count(*) > 1
