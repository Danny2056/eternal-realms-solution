-- Grain: one row per character per encounter (PVE or PVP), the core combat fact.
-- Damage comes from the per-encounter summary for normal/elite creatures, and from hit-by-hit events for
-- bosses and PVP. The character's level at the start of the fight is attached for peer comparisons.
WITH starts AS (
    SELECT encounter_id, character_id, any_value(encounter_kind) AS encounter_kind, any_value(creature_id) AS creature_id,
           any_value(opponent_character_ids) AS opponent_character_ids, any_value(party_id) AS party_id,
           any_value(zone_id) AS zone_id, any_value(sub_zone_id) AS sub_zone_id, min(event_ts_utc) AS started_at
    FROM staging.stg_events WHERE event_type = 'encounter_started' AND encounter_id IS NOT NULL AND character_id IS NOT NULL
    GROUP BY 1, 2
),
ends AS (
    SELECT encounter_id, character_id, any_value(outcome) AS outcome, max(event_ts_utc) AS ended_at
    FROM staging.stg_events WHERE event_type = 'encounter_ended' AND encounter_id IS NOT NULL AND character_id IS NOT NULL
    GROUP BY 1, 2
),
summary AS (
    SELECT encounter_id, character_id,
           (SELECT sum(CAST(x->>'total' AS BIGINT)) FROM unnest(CAST(summary_damage_done AS JSON[])) u(x)) AS dmg_done,
           (SELECT sum(CAST(x->>'total' AS BIGINT)) FROM unnest(CAST(summary_damage_received AS JSON[])) u(x)) AS dmg_received
    FROM staging.stg_events WHERE event_type = 'encounter_damage_summary' AND encounter_id IS NOT NULL
),
hits AS (
    SELECT encounter_id, character_id,
           sum(damage) FILTER (WHERE event_type IN ('pve_damage_dealt', 'pvp_damage_dealt'))     AS dmg_done,
           sum(damage) FILTER (WHERE event_type IN ('pve_damage_received', 'pvp_damage_received')) AS dmg_received
    FROM staging.stg_events
    WHERE event_type IN ('pve_damage_dealt', 'pvp_damage_dealt', 'pve_damage_received', 'pvp_damage_received')
      AND encounter_id IS NOT NULL
    GROUP BY 1, 2
)
SELECT s.encounter_id, s.character_id, s.encounter_kind, s.creature_id, cr.rank AS creature_rank,
       s.opponent_character_ids, s.party_id, s.party_id IS NOT NULL AS in_party,
       s.zone_id, s.sub_zone_id, s.started_at, e.ended_at, CAST(s.started_at AS DATE) AS encounter_date,
       epoch(e.ended_at) - epoch(s.started_at) AS duration_s,
       e.outcome,
       coalesce(sm.dmg_done, h.dmg_done) AS damage_done,
       coalesce(sm.dmg_received, h.dmg_received) AS damage_received,
       l.level AS level_at_start, l.bracket_min_level
FROM starts s
LEFT JOIN ends e USING (encounter_id, character_id)
LEFT JOIN summary sm USING (encounter_id, character_id)
LEFT JOIN hits h USING (encounter_id, character_id)
LEFT JOIN raw_ref.creatures cr ON cr.creature_id = s.creature_id
ASOF LEFT JOIN intermediate.int_character_level_history l
       ON l.character_id = s.character_id AND s.started_at >= l.valid_from
