-- One row per data-quality check, so the numbers in docs/data-quality-findings.md are reproducible.
SELECT 'DQ-1' AS check_id, 'Duplicate deliveries removed' AS check_name,
       (SELECT count(*) FROM raw_intake.events) - (SELECT count(*) FROM staging.stg_events) AS affected_rows
UNION ALL
SELECT 'DQ-2', 'Events lost in delivery (shard_seq gaps)', (SELECT count(*) FROM dq.dq_shard_seq_gaps)
UNION ALL
SELECT 'DQ-3', 'Timestamps corrected for shard clock fault', (SELECT count(*) FROM staging.stg_events WHERE ts_corrected)
UNION ALL
SELECT 'DQ-4a', 'Events with an empty body', (SELECT count(*) FROM staging.stg_events WHERE body_missing)
UNION ALL
SELECT 'DQ-4b', 'Events missing character_id where the type requires it',
       (SELECT count(*) FROM staging.stg_events
        WHERE character_id IS NULL AND NOT body_missing AND event_type <> 'item_dropped')

UNION ALL
SELECT 'DQ-5a', 'Placeholder zone_unknown replaced by NULL',
       (SELECT count(*) FROM raw_intake.events WHERE body LIKE '%zone_unknown%')
UNION ALL
SELECT 'DQ-5b', 'Events referencing a character that does not exist',
       (SELECT count(*) FROM staging.stg_events e
        WHERE character_id IS NOT NULL
          AND NOT EXISTS (SELECT 1 FROM raw_game.characters c WHERE c.character_id = e.character_id))
UNION ALL
SELECT 'DQ-6a', 'Corrupted integers recovered (bitwise NOT)', (SELECT count(*) FROM staging.stg_events WHERE numeric_repair = 'bitflip_recovered')
UNION ALL
SELECT 'DQ-6b', 'Corrupted integers unrecoverable (set to NULL)', (SELECT count(*) FROM staging.stg_events WHERE numeric_repair = 'overflow_nulled')
UNION ALL
SELECT 'DQ-7', 'Level-up events reporting level 0 (set to NULL)',
       (SELECT count(*) FROM staging.stg_events WHERE event_type = 'level_up' AND new_level IS NULL AND NOT body_missing)
