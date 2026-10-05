-- Known shard clock faults (see docs/data-quality-findings.md, DQ-3).
-- shard-04 restarted at 2026-09-07 03:17:44 UTC and from then on stamped events in America/Chicago
-- local time (CDT = UTC-5). Proven by received_at - event_ts jumping from ~0.7 s to exactly 18,000 s
-- between shard_seq 6,736,767 and 6,736,768. Kept as data, not buried in code, so it is reviewable.
SELECT * FROM (VALUES
    ('shard-04', 6736768::BIGINT, NULL::BIGINT, INTERVAL 5 HOUR,
     'Shard restarted 2026-09-07 03:17:44 UTC and stamped America/Chicago (CDT) local time instead of UTC')
) AS t(server_id, from_shard_seq, to_shard_seq, add_to_event_ts, reason)
