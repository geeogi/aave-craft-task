-- Current V4 user profile by portfolio size bucket.
-- Includes current supplied balance, average supply/borrow event counts since V4 launch,
-- and average wallet age based on first observed Ethereum transaction.
-- https://dune.com/queries/7686784

WITH params AS (
    SELECT
        DATE '2026-03-30' AS v4_start_date
),
user_portfolios AS (
    SELECT
        user,
        SUM(current_position_usd) AS portfolio_usd
    FROM query_7676585
    GROUP BY user
),
supply_events_since_v4_start AS (
    SELECT
        user,
        COUNT(*) AS supply_event_count_since_v4_start
    FROM query_7677938
    CROSS JOIN params
    WHERE event_type = 'supply'
      AND CAST(evt_block_time AS date) >= params.v4_start_date
    GROUP BY user
),
borrow_events_since_v4_start AS (
    SELECT
        user,
        COUNT(*) AS borrow_event_count_since_v4_start
    FROM query_7677938
    CROSS JOIN params
    WHERE event_type = 'borrow'
      AND CAST(evt_block_time AS date) >= params.v4_start_date
    GROUP BY user
),
wallet_ages AS (
    SELECT
        ethereum.transactions."from" AS user,
        DATE_DIFF('day', CAST(MIN(ethereum.transactions.block_time) AS date), CURRENT_DATE) AS wallet_age_days
    FROM ethereum.transactions
    INNER JOIN user_portfolios
        ON ethereum.transactions."from" = user_portfolios.user
       AND user_portfolios.portfolio_usd >= 1
    GROUP BY ethereum.transactions."from"
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
bucketed_users AS (
    SELECT
        user_portfolios.user,
        user_portfolios.portfolio_usd,
        COALESCE(supply_events_since_v4_start.supply_event_count_since_v4_start, 0) AS supply_event_count_since_v4_start,
        COALESCE(borrow_events_since_v4_start.borrow_event_count_since_v4_start, 0) AS borrow_event_count_since_v4_start,
        wallet_ages.wallet_age_days,
        CASE
            WHEN user_portfolios.portfolio_usd >= 1 AND user_portfolios.portfolio_usd < 1e3 THEN '1-1k'
            WHEN user_portfolios.portfolio_usd >= 1e3 AND user_portfolios.portfolio_usd < 1e4 THEN '1k-10k'
            WHEN user_portfolios.portfolio_usd >= 1e4 AND user_portfolios.portfolio_usd < 1e5 THEN '10k-100k'
            WHEN user_portfolios.portfolio_usd >= 1e5 AND user_portfolios.portfolio_usd < 1e6 THEN '100k-1m'
            WHEN user_portfolios.portfolio_usd >= 1e6 AND user_portfolios.portfolio_usd < 1e7 THEN '1m-10m'
            WHEN user_portfolios.portfolio_usd >= 1e7 AND user_portfolios.portfolio_usd < 1e8 THEN '10m-100m'
            ELSE '100m+'
        END AS balance_bucket
    FROM user_portfolios
    LEFT JOIN supply_events_since_v4_start
        ON user_portfolios.user = supply_events_since_v4_start.user
    LEFT JOIN borrow_events_since_v4_start
        ON user_portfolios.user = borrow_events_since_v4_start.user
    LEFT JOIN wallet_ages
        ON user_portfolios.user = wallet_ages.user
    WHERE user_portfolios.portfolio_usd >= 1
),
bucket_aggregates AS (
    SELECT
        balance_bucket,
        COUNT(*) AS users,
        SUM(portfolio_usd) AS total_supplied_usd,
        AVG(supply_event_count_since_v4_start) AS avg_supply_events_since_v4_start,
        AVG(borrow_event_count_since_v4_start) AS avg_borrow_events_since_v4_start,
        APPROX_PERCENTILE(wallet_age_days, 0.5) AS median_wallet_age_days
    FROM bucketed_users
    GROUP BY
        balance_bucket
)

SELECT
    bucket_definitions.balance_bucket AS "Portfolio bucket",
    COALESCE(bucket_aggregates.users, 0) AS "Users",
    COALESCE(bucket_aggregates.total_supplied_usd, 0) AS "Supplied ($)",
    bucket_aggregates.avg_supply_events_since_v4_start AS "Supply Events (avg)",
    bucket_aggregates.avg_borrow_events_since_v4_start AS "Borrow Events (avg)",
    bucket_aggregates.median_wallet_age_days AS "Wallet Age (median)"
FROM bucket_definitions
LEFT JOIN bucket_aggregates
    ON bucket_definitions.balance_bucket = bucket_aggregates.balance_bucket
ORDER BY
    bucket_definitions.bucket_order
