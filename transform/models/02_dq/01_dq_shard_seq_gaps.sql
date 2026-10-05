-- DQ-2: events lost in delivery. Each row is one missing shard_seq, with the events either side of it,
-- so cheat rules can tell "the event chain is broken because the game was cheated" apart from
-- "the event chain is broken because the delivery lost an event".
WITH seqs AS (
    SELECT server_id, shard_seq, event_ts_utc,
           lead(shard_seq)    OVER w AS next_seq,
           lead(event_ts_utc) OVER w AS next_ts
    FROM staging.stg_events
    WINDOW w AS (PARTITION BY server_id ORDER BY shard_seq)
)
SELECT server_id,
       missing_seq,
       shard_seq    AS prev_seq,
       event_ts_utc AS prev_event_ts,
       next_seq,
       next_ts      AS next_event_ts
FROM seqs, range(shard_seq + 1, next_seq) AS r(missing_seq)
WHERE next_seq - shard_seq > 1
