-- Weekly end-of-week user balances for selected Aave V3 Ethereum assets.
-- https://dune.com/queries/7678703

WITH weekly_asset_reference AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        week,
        liquidityIndex
    FROM dune.geeogi.result_aave_v3_ethereum_asset_reference_weekly
),
user_scaled_transfers AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        week,
        user,
        scaled_amount_delta_raw
    FROM query_7678693
),
reserve_weeks AS (
    SELECT DISTINCT
        asset,
        reserve,
        a_token,
        decimals,
        week
    FROM weekly_asset_reference
),
weekly_prices AS (
    SELECT
        contract_address,
        date_trunc('week', timestamp) AS week,
        price,
        ROW_NUMBER() OVER (
            PARTITION BY contract_address, date_trunc('week', timestamp)
            ORDER BY timestamp DESC
        ) AS price_rank
    FROM prices.day
    WHERE blockchain = 'ethereum'
),
latest_weekly_prices AS (
    SELECT
        contract_address,
        week,
        price
    FROM weekly_prices
    WHERE price_rank = 1
),
event_week_balances AS (
    SELECT
        user_scaled_transfers.asset,
        user_scaled_transfers.reserve,
        user_scaled_transfers.a_token,
        user_scaled_transfers.decimals,
        user_scaled_transfers.week,
        user_scaled_transfers.user,
        SUM(user_scaled_transfers.scaled_amount_delta_raw) OVER (
            PARTITION BY user_scaled_transfers.reserve, user_scaled_transfers.user
            ORDER BY user_scaled_transfers.week
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS current_scaled_balance_raw
    FROM user_scaled_transfers
),
user_activity_ranges AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        user,
        MIN(week) AS first_active_week
    FROM user_scaled_transfers
    GROUP BY
        asset,
        reserve,
        a_token,
        decimals,
        user
),
user_week_spine AS (
    SELECT
        user_activity_ranges.asset,
        user_activity_ranges.reserve,
        user_activity_ranges.a_token,
        user_activity_ranges.decimals,
        reserve_weeks.week,
        user_activity_ranges.user
    FROM user_activity_ranges
    INNER JOIN reserve_weeks
        ON user_activity_ranges.reserve = reserve_weeks.reserve
       AND reserve_weeks.week >= user_activity_ranges.first_active_week
),
carried_scaled_balances AS (
    SELECT
        user_week_spine.asset,
        user_week_spine.reserve,
        user_week_spine.a_token,
        user_week_spine.decimals,
        user_week_spine.week,
        user_week_spine.user,
        MAX_BY(event_week_balances.current_scaled_balance_raw, event_week_balances.week) AS current_scaled_balance_raw
    FROM user_week_spine
    LEFT JOIN event_week_balances
        ON user_week_spine.reserve = event_week_balances.reserve
       AND user_week_spine.user = event_week_balances.user
       AND event_week_balances.week <= user_week_spine.week
    GROUP BY
        user_week_spine.asset,
        user_week_spine.reserve,
        user_week_spine.a_token,
        user_week_spine.decimals,
        user_week_spine.week,
        user_week_spine.user
),
weekly_balances AS (
    SELECT
        carried_scaled_balances.user,
        carried_scaled_balances.asset,
        carried_scaled_balances.reserve,
        carried_scaled_balances.a_token,
        carried_scaled_balances.decimals,
        carried_scaled_balances.week,
        carried_scaled_balances.current_scaled_balance_raw * weekly_asset_reference.liquidityIndex / 1e27 / POWER(10, carried_scaled_balances.decimals) AS current_a_token_balance,
        latest_weekly_prices.price AS asset_price_usd
    FROM carried_scaled_balances
    INNER JOIN weekly_asset_reference
        ON carried_scaled_balances.reserve = weekly_asset_reference.reserve
       AND carried_scaled_balances.week = weekly_asset_reference.week
    LEFT JOIN latest_weekly_prices
        ON carried_scaled_balances.reserve = latest_weekly_prices.contract_address
       AND carried_scaled_balances.week = latest_weekly_prices.week
)

SELECT
    user,
    asset,
    reserve,
    a_token,
    week,
    current_a_token_balance,
    asset_price_usd,
    current_a_token_balance * asset_price_usd AS current_balance_usd
FROM weekly_balances
WHERE current_a_token_balance > 0
ORDER BY
    week DESC,
    current_balance_usd DESC NULLS LAST
