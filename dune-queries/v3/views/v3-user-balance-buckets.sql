-- Current holder portfolio size buckets for Aave V3 Ethereum.
-- https://dune.com/queries/7683195/11639910

WITH user_portfolios AS (
    SELECT
        user,
        SUM(current_balance_usd) AS portfolio_usd
    FROM query_7677461
    GROUP BY user
),
bucket_definitions AS (
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
bucketed_portfolios AS (
    SELECT
        user,
        portfolio_usd,
        CASE
            WHEN portfolio_usd >= 1 AND portfolio_usd < 1e3 THEN '1-1k'
            WHEN portfolio_usd >= 1e3 AND portfolio_usd < 1e4 THEN '1k-10k'
            WHEN portfolio_usd >= 1e4 AND portfolio_usd < 1e5 THEN '10k-100k'
            WHEN portfolio_usd >= 1e5 AND portfolio_usd < 1e6 THEN '100k-1m'
            WHEN portfolio_usd >= 1e6 AND portfolio_usd < 1e7 THEN '1m-10m'
            WHEN portfolio_usd >= 1e7 AND portfolio_usd < 1e8 THEN '10m-100m'
            ELSE '100m+'
        END AS balance_bucket,
        CASE
            WHEN portfolio_usd >= 1 AND portfolio_usd < 1e3 THEN 1
            WHEN portfolio_usd >= 1e3 AND portfolio_usd < 1e4 THEN 2
            WHEN portfolio_usd >= 1e4 AND portfolio_usd < 1e5 THEN 3
            WHEN portfolio_usd >= 1e5 AND portfolio_usd < 1e6 THEN 4
            WHEN portfolio_usd >= 1e6 AND portfolio_usd < 1e7 THEN 5
            WHEN portfolio_usd >= 1e7 AND portfolio_usd < 1e8 THEN 6
            ELSE 7
        END AS bucket_order
    FROM user_portfolios
    WHERE portfolio_usd >= 1
),
bucket_aggregates AS (
    SELECT
        balance_bucket,
        bucket_order,
        COUNT(*) AS users,
        SUM(portfolio_usd) AS total_portfolio_usd,
        AVG(portfolio_usd) AS avg_portfolio_usd
    FROM bucketed_portfolios
    GROUP BY
        balance_bucket,
        bucket_order
)

SELECT
    bucket_definitions.balance_bucket,
    bucket_definitions.bucket_order,
    COALESCE(bucket_aggregates.users, 0) AS users,
    COALESCE(bucket_aggregates.total_portfolio_usd, 0) AS total_portfolio_usd,
    bucket_aggregates.avg_portfolio_usd
FROM bucket_definitions
LEFT JOIN bucket_aggregates
    ON bucket_definitions.balance_bucket = bucket_aggregates.balance_bucket
   AND bucket_definitions.bucket_order = bucket_aggregates.bucket_order
ORDER BY
    bucket_definitions.bucket_order
