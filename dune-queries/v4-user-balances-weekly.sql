-- Weekly end-of-week user balances across all Aave V4 Ethereum spokes.
-- https://dune.com/queries/7682230

WITH reserve_asset_map AS (
    SELECT
        hub,
        spoke,
        reserveId,
        assetId,
        decimals,
        address,
        symbol,
        week,
        amount_per_share,
        asset_price_usd
    FROM dune.geeogi.result_aave_v4_ethereum_asset_reference_weekly
),
weekly_user_transfers AS (
    SELECT
        user,
        spoke,
        reserveId,
        week,
        weekly_share_delta_raw
    FROM dune.geeogi.result_aave_v4_ethereum_user_transfers_weekly
),
reserve_weeks AS (
    SELECT DISTINCT
        spoke,
        reserveId,
        week
    FROM reserve_asset_map
),
user_activity_ranges AS (
    SELECT
        spoke,
        reserveId,
        user,
        MIN(week) AS first_active_week
    FROM weekly_user_transfers
    GROUP BY
        spoke,
        reserveId,
        user
),
user_week_spine AS (
    SELECT
        user_activity_ranges.spoke,
        user_activity_ranges.reserveId,
        reserve_weeks.week,
        user_activity_ranges.user
    FROM user_activity_ranges
    INNER JOIN reserve_weeks
        ON user_activity_ranges.spoke = reserve_weeks.spoke
       AND user_activity_ranges.reserveId = reserve_weeks.reserveId
       AND reserve_weeks.week >= user_activity_ranges.first_active_week
),
weekly_share_balances AS (
    SELECT
        user_week_spine.spoke,
        user_week_spine.reserveId,
        user_week_spine.week,
        user_week_spine.user,
        SUM(COALESCE(weekly_user_transfers.weekly_share_delta_raw, 0)) OVER (
            PARTITION BY user_week_spine.spoke, user_week_spine.reserveId, user_week_spine.user
            ORDER BY user_week_spine.week
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS current_supplied_shares_raw
    FROM user_week_spine
    LEFT JOIN weekly_user_transfers
        ON user_week_spine.spoke = weekly_user_transfers.spoke
       AND user_week_spine.reserveId = weekly_user_transfers.reserveId
       AND user_week_spine.user = weekly_user_transfers.user
       AND user_week_spine.week = weekly_user_transfers.week
),
weekly_balances AS (
    SELECT
        weekly_share_balances.user,
        reserve_asset_map.hub,
        weekly_share_balances.spoke,
        reserve_asset_map.symbol,
        reserve_asset_map.reserveId,
        reserve_asset_map.address,
        weekly_share_balances.week,
        weekly_share_balances.current_supplied_shares_raw,
        reserve_asset_map.amount_per_share,
        weekly_share_balances.current_supplied_shares_raw * reserve_asset_map.amount_per_share / POWER(10, reserve_asset_map.decimals) AS current_supplied_amount,
        reserve_asset_map.asset_price_usd
    FROM weekly_share_balances
    INNER JOIN reserve_asset_map
        ON weekly_share_balances.spoke = reserve_asset_map.spoke
       AND weekly_share_balances.reserveId = reserve_asset_map.reserveId
       AND weekly_share_balances.week = reserve_asset_map.week
)

SELECT
    user,
    hub,
    spoke,
    symbol,
    reserveId,
    address,
    week,
    current_supplied_shares_raw,
    amount_per_share,
    current_supplied_amount,
    asset_price_usd,
    current_supplied_amount * asset_price_usd AS current_position_usd
FROM weekly_balances
WHERE current_supplied_shares_raw > 0
ORDER BY
    week DESC,
    current_position_usd DESC NULLS LAST
