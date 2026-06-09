-- Weekly V4 supplied balance split by whether the user has any V3 balance history.
-- https://dune.com/queries/7683488/11640216

WITH v3_historical_users AS (
    SELECT DISTINCT
        user
    FROM dune.geeogi.result_aave_v3_ethereum_user_balances_weekly
),
v4_weekly_user_balances AS (
    SELECT
        week,
        user,
        SUM(current_position_usd) AS portfolio_usd
    FROM dune.geeogi_team.result_aave_v4_ethereum_user_balances_weekly
    GROUP BY
        week,
        user
),
origin_definitions AS (
    SELECT 1 AS origin_order, 'Prior V3 user' AS user_origin
    UNION ALL
    SELECT 2 AS origin_order, 'No V3 history' AS user_origin
),
classified_balances AS (
    SELECT
        v4_weekly_user_balances.week,
        CASE
            WHEN v3_historical_users.user IS NOT NULL THEN 'Prior V3 user'
            ELSE 'No V3 history'
        END AS user_origin,
        v4_weekly_user_balances.user,
        v4_weekly_user_balances.portfolio_usd
    FROM v4_weekly_user_balances
    LEFT JOIN v3_historical_users
        ON v4_weekly_user_balances.user = v3_historical_users.user
),
weekly_origin_aggregates AS (
    SELECT
        week,
        user_origin,
        COUNT(*) AS users,
        SUM(portfolio_usd) AS total_portfolio_usd
    FROM classified_balances
    GROUP BY
        week,
        user_origin
),
v4_weeks AS (
    SELECT DISTINCT
        week
    FROM v4_weekly_user_balances
)

SELECT
    v4_weeks.week,
    origin_definitions.user_origin,
    origin_definitions.origin_order,
    COALESCE(weekly_origin_aggregates.users, 0) AS users,
    COALESCE(weekly_origin_aggregates.total_portfolio_usd, 0) AS total_portfolio_usd
FROM v4_weeks
CROSS JOIN origin_definitions
LEFT JOIN weekly_origin_aggregates
    ON v4_weeks.week = weekly_origin_aggregates.week
   AND origin_definitions.user_origin = weekly_origin_aggregates.user_origin
ORDER BY
    v4_weeks.week,
    origin_definitions.origin_order
