-- R11 Transport boarded by the wrong faction, from the wrong zone, or before its release.
SELECT 'R11' AS rule_id, e.character_id, e.event_ts_utc AS occurred_at, NULL AS encounter_id,
       'Boarded ' || t.name || ' as ' || ch.faction || ' from ' || e.zone_id AS detail,
       [e.event_id] AS evidence_event_ids, [e.server_event_id] AS evidence_server_event_ids
FROM staging.stg_events e
JOIN raw_ref.transports t USING (transport_id)
JOIN raw_game.characters ch USING (character_id)
JOIN raw_ref.game_versions v ON v.version = t.available_from_version
WHERE e.event_type = 'transport_boarded'
  AND ((t.faction IS NOT NULL AND t.faction <> ch.faction) OR e.zone_id <> t.from_zone_id OR e.event_ts_utc < v.released_at)
