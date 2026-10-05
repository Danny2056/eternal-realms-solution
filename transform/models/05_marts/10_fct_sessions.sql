-- Grain: one row per play session (login to the next logout of the same character).
-- Sessions whose logout was lost (DQ-2) are closed at the next login, and flagged.
WITH s AS (
    SELECT character_id, account_id, event_type, event_ts_utc, zone_id,
           lead(event_type)   OVER w AS next_type,
           lead(event_ts_utc) OVER w AS next_ts
    FROM staging.stg_events
    WHERE event_type IN ('session_login', 'session_logout') AND character_id IS NOT NULL
    WINDOW w AS (PARTITION BY character_id ORDER BY event_ts_utc)
)
SELECT character_id, login_at, logout_at, session_date, login_zone_id,
       epoch(logout_at) - epoch(login_at) AS duration_s, logout_missing
FROM (
    SELECT s.character_id, s.event_ts_utc AS login_at,
           s.next_ts AS logout_at, CAST(s.event_ts_utc AS DATE) AS session_date, s.zone_id AS login_zone_id,
           s.next_type IS DISTINCT FROM 'session_logout' AS logout_missing
    FROM s WHERE s.event_type = 'session_login'
)
WHERE logout_at IS NOT NULL AND NOT logout_missing
