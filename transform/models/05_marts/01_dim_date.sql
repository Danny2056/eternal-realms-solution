-- Calendar dimension covering the snapshot window. Grain: one row per day.
SELECT CAST(d AS DATE) AS date_day,
       CAST(strftime(d, '%Y%m%d') AS INT) AS date_key,
       dayname(d) AS day_name,
       isodow(d) AS iso_day_of_week,          -- 1 = Monday ... 7 = Sunday
       isodow(d) IN (6, 7) AS is_weekend,
       weekofyear(d) AS iso_week,
       CAST(date_trunc('week', d) AS DATE) AS week_start,
       CAST(d AS DATE) >= DATE '2026-08-26' AS is_patch_2_1
FROM range(TIMESTAMP '2026-08-10', TIMESTAMP '2026-09-11', INTERVAL 1 DAY) AS t(d)
