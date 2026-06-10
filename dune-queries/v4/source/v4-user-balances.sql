-- User balances across all Aave V4 Ethereum spokes.
-- Takes our latest balances for each user.
-- https://dune.com/queries/7676585

WITH weekly_balances AS (
    SELECT
        hub,
        week,
        user,
        spoke,
        reserveId,
        address,
        symbol,
        current_supplied_shares_raw,
        amount_per_share,
        current_supplied_amount,
        asset_price_usd,
        current_position_usd
    FROM dune.geeogi_team.result_aave_v4_ethereum_user_balances_weekly
),
latest_week AS (
    SELECT
        MAX(week) AS week
    FROM weekly_balances
)

SELECT
    weekly_balances.user,
    weekly_balances.hub,
    weekly_balances.spoke,
    weekly_balances.symbol,
    weekly_balances.current_supplied_amount,
    weekly_balances.current_position_usd
FROM weekly_balances
INNER JOIN latest_week
    ON weekly_balances.week = latest_week.week
ORDER BY
    current_position_usd DESC NULLS LAST
