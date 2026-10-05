-- One row per character with at least one violation: how many, of which kinds, when.
-- A character counts as a confirmed cheater when it broke a high-severity rule, or broke at least 3 different
-- rules; isolated low/medium findings are listed for review but not treated as proof (lost events, DQ-2).
SELECT character_id, account_id, faction, class_id,
       count(*) AS violations,
       count(DISTINCT rule_id) AS distinct_rules,
       list(DISTINCT rule_name ORDER BY rule_name) AS rules_broken,
       count(*) FILTER (WHERE severity = 'high') AS high_severity,
       min(occurred_at) AS first_violation_at,
       max(occurred_at) AS last_violation_at,
       (count(*) FILTER (WHERE severity = 'high') > 0 OR count(DISTINCT rule_id) >= 3) AS confirmed_cheater
FROM cheats.cheat_violations
WHERE character_known
GROUP BY ALL
ORDER BY confirmed_cheater DESC, distinct_rules DESC, violations DESC
