-- Total transactions within a time window (edit the two timestamps).
SELECT transaction_type, count(*) AS transactions, sum(gold_amount) AS gold_value
FROM marts.fct_economy_transactions
WHERE transacted_at >= TIMESTAMPTZ '2026-08-26 09:41:00+00'   -- example: patch 2.1 onwards
  AND transacted_at <  TIMESTAMPTZ '2026-09-11 00:00:00+00'
GROUP BY ROLLUP (transaction_type) ORDER BY transaction_type NULLS LAST
