-- Weekly end-of-week user balances for selected Aave V3 Ethereum assets.
-- https://dune.com/queries/7678703
-- dune.geeogi.result_aave_v3_ethereum_user_balances_weekly

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
weekly_user_transfers AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        week,
        user,
        weekly_amount_delta_raw
    FROM query_7678569
),
user_scaled_transfers AS (
    SELECT
        weekly_user_transfers.asset,
        weekly_user_transfers.reserve,
        weekly_user_transfers.a_token,
        weekly_user_transfers.decimals,
        weekly_user_transfers.week,
        weekly_user_transfers.user,
        weekly_user_transfers.weekly_amount_delta_raw * 1e27 / weekly_asset_reference.liquidityIndex AS scaled_amount_delta_raw
    FROM weekly_user_transfers
    INNER JOIN weekly_asset_reference
        ON weekly_user_transfers.reserve = weekly_asset_reference.reserve
       AND weekly_user_transfers.week = weekly_asset_reference.week
),
reserve_weeks AS (
    SELECT DISTINCT
        reserve,
        week
    FROM weekly_asset_reference
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
weekly_scaled_balances AS (
    SELECT
        user_week_spine.asset,
        user_week_spine.reserve,
        user_week_spine.a_token,
        user_week_spine.decimals,
        user_week_spine.week,
        user_week_spine.user,
        SUM(COALESCE(user_scaled_transfers.scaled_amount_delta_raw, 0)) OVER (
            PARTITION BY user_week_spine.reserve, user_week_spine.user
            ORDER BY user_week_spine.week
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS current_scaled_balance_raw
    FROM user_week_spine
    LEFT JOIN user_scaled_transfers
        ON user_week_spine.reserve = user_scaled_transfers.reserve
       AND user_week_spine.user = user_scaled_transfers.user
       AND user_week_spine.week = user_scaled_transfers.week
),
weekly_balances AS (
    SELECT
        weekly_scaled_balances.user,
        weekly_scaled_balances.asset,
        weekly_scaled_balances.reserve,
        weekly_scaled_balances.a_token,
        weekly_scaled_balances.decimals,
        weekly_scaled_balances.week,
        weekly_scaled_balances.current_scaled_balance_raw * weekly_asset_reference.liquidityIndex / 1e27 / POWER(10, weekly_scaled_balances.decimals) AS current_a_token_balance,
        latest_weekly_prices.price AS asset_price_usd
    FROM weekly_scaled_balances
    INNER JOIN weekly_asset_reference
        ON weekly_scaled_balances.reserve = weekly_asset_reference.reserve
       AND weekly_scaled_balances.week = weekly_asset_reference.week
    LEFT JOIN latest_weekly_prices
        ON weekly_scaled_balances.reserve = latest_weekly_prices.contract_address
       AND weekly_scaled_balances.week = latest_weekly_prices.week
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
