-- User balances in USD across all V4 spokes.
-- Replace <v4_user_balances_weekly_query_id> with the saved Dune query id for v4-user-balances-weekly.sql.

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
    FROM query_<v4_user_balances_weekly_query_id>
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
