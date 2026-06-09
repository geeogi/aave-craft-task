-- Current user balances for selected Aave V3 Ethereum aTokens.
-- Approximates scaled balances using weekly liquidityIndex snapshots.
-- https://dune.com/queries/7677461

WITH weekly_balances AS (
    SELECT
        week,
        user,
        asset,
        reserve,
        a_token,
        current_a_token_balance,
        asset_price_usd,
        current_balance_usd
    FROM dune.geeogi_team.result_aave_v3_ethereum_user_balances_weekly
),
latest_week AS (
    SELECT
        MAX(week) AS week
    FROM weekly_balances
)

SELECT
    weekly_balances.user,
    weekly_balances.asset,
    weekly_balances.reserve,
    weekly_balances.a_token,
    weekly_balances.current_a_token_balance,
    weekly_balances.asset_price_usd,
    weekly_balances.current_balance_usd
FROM weekly_balances
INNER JOIN latest_week
    ON weekly_balances.week = latest_week.week
ORDER BY
    current_balance_usd DESC NULLS LAST
