-- Weekly end-of-week user balances across all Aave V4 Ethereum spokes.
-- Replace <v4_user_transfers_weekly_query_id> with the saved Dune query id for v4-user-transfers-weekly.sql.
-- Replace <v4_asset_reference_weekly_query_id> with the saved Dune query id for v4-asset-reference-weekly.sql.

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
    FROM query_<v4_asset_reference_weekly_query_id>
),
weekly_user_transfers AS (
    SELECT
        user,
        spoke,
        reserveId,
        week,
        weekly_share_delta_raw
    FROM query_<v4_user_transfers_weekly_query_id>
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
event_week_balances AS (
    SELECT
        weekly_user_transfers.spoke,
        weekly_user_transfers.reserveId,
        weekly_user_transfers.week,
        weekly_user_transfers.user,
        SUM(weekly_user_transfers.weekly_share_delta_raw) OVER (
            PARTITION BY weekly_user_transfers.spoke, weekly_user_transfers.reserveId, weekly_user_transfers.user
            ORDER BY weekly_user_transfers.week
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS current_supplied_shares_raw
    FROM weekly_user_transfers
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
carried_share_balances AS (
    SELECT
        user_week_spine.spoke,
        user_week_spine.reserveId,
        user_week_spine.week,
        user_week_spine.user,
        MAX_BY(event_week_balances.current_supplied_shares_raw, event_week_balances.week) AS current_supplied_shares_raw
    FROM user_week_spine
    LEFT JOIN event_week_balances
        ON user_week_spine.spoke = event_week_balances.spoke
       AND user_week_spine.reserveId = event_week_balances.reserveId
       AND user_week_spine.user = event_week_balances.user
       AND event_week_balances.week <= user_week_spine.week
    GROUP BY
        user_week_spine.spoke,
        user_week_spine.reserveId,
        user_week_spine.week,
        user_week_spine.user
),
weekly_balances AS (
    SELECT
        carried_share_balances.user,
        reserve_asset_map.hub,
        carried_share_balances.spoke,
        reserve_asset_map.symbol,
        reserve_asset_map.reserveId,
        reserve_asset_map.address,
        carried_share_balances.week,
        carried_share_balances.current_supplied_shares_raw,
        reserve_asset_map.amount_per_share,
        carried_share_balances.current_supplied_shares_raw * reserve_asset_map.amount_per_share / POWER(10, reserve_asset_map.decimals) AS current_supplied_amount,
        reserve_asset_map.asset_price_usd
    FROM carried_share_balances
    INNER JOIN reserve_asset_map
        ON carried_share_balances.spoke = reserve_asset_map.spoke
       AND carried_share_balances.reserveId = reserve_asset_map.reserveId
       AND carried_share_balances.week = reserve_asset_map.week
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
