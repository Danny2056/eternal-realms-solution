-- Total population by class, faction and level bracket (current state at snapshot).
SELECT faction, class_name, current_bracket_min_level AS bracket_min_level,
       current_bracket_min_level || '-' || (current_bracket_min_level + 9) AS level_bracket,
       count(*) AS characters
FROM marts.dim_character
GROUP BY ALL ORDER BY faction, class_name, bracket_min_level
