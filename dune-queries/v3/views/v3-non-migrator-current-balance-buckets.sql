-- Users with V3 balance > $100 on the V4 start week who never used V4.
-- Buckets non-migrators by their current V3 balances and shows current V3 totals by bucket.
-- https://dune.com/queries/7684185

WITH params AS (
    SELECT
        TIMESTAMP '2026-03-30' AS v4_start_week,
        100 AS min_start_balance_usd
),
v3_start_balances AS (
    SELECT
        user,
        SUM(current_balance_usd) AS v3_start_balance_usd
    FROM dune.geeogi.result_aave_v3_ethereum_user_balances_weekly
    CROSS JOIN params
    WHERE week = params.v4_start_week
    GROUP BY user
    HAVING SUM(current_balance_usd) > MAX(params.min_start_balance_usd)
),
v4_users AS (
    SELECT DISTINCT
        user
    FROM query_7682230
),
v3_current AS (
    SELECT
        user,
        SUM(current_balance_usd) AS current_v3_balance_usd
    FROM query_7677461
    GROUP BY user
),
bucket_defs AS (
    SELECT 1 AS bucket_order, '1-1k' AS balance_bucket
    UNION ALL
    SELECT 2 AS bucket_order, '1k-10k' AS balance_bucket
    UNION ALL
    SELECT 3 AS bucket_order, '10k-100k' AS balance_bucket
    UNION ALL
    SELECT 4 AS bucket_order, '100k-1m' AS balance_bucket
    UNION ALL
    SELECT 5 AS bucket_order, '1m-10m' AS balance_bucket
    UNION ALL
    SELECT 6 AS bucket_order, '10m-100m' AS balance_bucket
    UNION ALL
    SELECT 7 AS bucket_order, '100m+' AS balance_bucket
),
non_migrators AS (
    SELECT
        v3_start_balances.user,
        COALESCE(v3_current.current_v3_balance_usd, 0) AS current_v3_balance_usd
    FROM v3_start_balances
    LEFT JOIN v4_users
        ON v3_start_balances.user = v4_users.user
    LEFT JOIN v3_current
        ON v3_start_balances.user = v3_current.user
    WHERE v4_users.user IS NULL
),
classified AS (
    SELECT
        user,
        current_v3_balance_usd,
        CASE
            WHEN current_v3_balance_usd < 1e3 THEN '1-1k'
            WHEN current_v3_balance_usd < 1e4 THEN '1k-10k'
            WHEN current_v3_balance_usd < 1e5 THEN '10k-100k'
            WHEN current_v3_balance_usd < 1e6 THEN '100k-1m'
            WHEN current_v3_balance_usd < 1e7 THEN '1m-10m'
            WHEN current_v3_balance_usd < 1e8 THEN '10m-100m'
            ELSE '100m+'
        END AS balance_bucket,
        CASE
            WHEN current_v3_balance_usd < 1e3 THEN 1
            WHEN current_v3_balance_usd < 1e4 THEN 2
            WHEN current_v3_balance_usd < 1e5 THEN 3
            WHEN current_v3_balance_usd < 1e6 THEN 4
            WHEN current_v3_balance_usd < 1e7 THEN 5
            WHEN current_v3_balance_usd < 1e8 THEN 6
            ELSE 7
        END AS bucket_order
    FROM non_migrators
),
bucket_aggregates AS (
    SELECT
        balance_bucket,
        bucket_order,
        SUM(current_v3_balance_usd) AS current_v3_balance_usd
    FROM classified
    GROUP BY
        balance_bucket,
        bucket_order
)

SELECT
    bucket_defs.balance_bucket,
    bucket_defs.bucket_order,
    COALESCE(bucket_aggregates.current_v3_balance_usd, 0) AS current_v3_balance_usd
FROM bucket_defs
LEFT JOIN bucket_aggregates
    ON bucket_defs.balance_bucket = bucket_aggregates.balance_bucket
   AND bucket_defs.bucket_order = bucket_aggregates.bucket_order
ORDER BY
    bucket_defs.bucket_order
