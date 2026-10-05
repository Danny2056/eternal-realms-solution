-- How often each rule fired, including rules that never fired (proof that the check ran and the game held).
SELECT r.rule_id, r.rule_name, r.category, r.severity, r.rulebook_section,
       count(v.violation_id) AS violations,
       count(DISTINCT v.character_id) AS characters,
       r.plain_english
FROM cheats.cheat_rule_catalog r
LEFT JOIN cheats.cheat_violations v USING (rule_id)
GROUP BY ALL
ORDER BY r.rule_id
