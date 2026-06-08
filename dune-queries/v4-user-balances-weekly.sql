-- Weekly end-of-week user balances across all Aave V4 Ethereum spokes.
-- Replace <v4_user_transfers_weekly_query_id> with the saved Dune query id for v4-user-transfers-weekly.sql.

WITH reserve_asset_map AS (
    SELECT DISTINCT
        hub,
        spoke,
        reserveId,
        assetId,
        decimals,
        address,
        symbol
    FROM query_7676557
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
weekly_rate_events AS (
    SELECT
        spoke,
        reserveId,
        date_trunc('week', evt_block_time) AS week,
        CAST(amount_raw AS DOUBLE) / NULLIF(CAST(shares_raw AS DOUBLE), 0) AS amount_per_share,
        ROW_NUMBER() OVER (
            PARTITION BY spoke, reserveId, date_trunc('week', evt_block_time)
            ORDER BY evt_block_time DESC
        ) AS rate_rank
    FROM query_7677938
    WHERE event_type IN ('supply', 'withdraw')
      AND shares_raw > 0
),
weekly_amount_per_share AS (
    SELECT
        spoke,
        reserveId,
        week,
        amount_per_share
    FROM weekly_rate_events
    WHERE rate_rank = 1
),
reserve_weeks AS (
    SELECT DISTINCT
        reserve_asset_map.spoke,
        reserve_asset_map.reserveId,
        date_trunc('week', prices.day.timestamp) AS week
    FROM reserve_asset_map
    INNER JOIN prices.day
        ON reserve_asset_map.address = prices.day.contract_address
    WHERE prices.day.blockchain = 'ethereum'
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
carried_amount_per_share AS (
    SELECT
        reserve_weeks.spoke,
        reserve_weeks.reserveId,
        reserve_weeks.week,
        COALESCE(MAX_BY(weekly_amount_per_share.amount_per_share, weekly_amount_per_share.week), 1) AS amount_per_share
    FROM reserve_weeks
    LEFT JOIN weekly_amount_per_share
        ON reserve_weeks.spoke = weekly_amount_per_share.spoke
       AND reserve_weeks.reserveId = weekly_amount_per_share.reserveId
       AND weekly_amount_per_share.week <= reserve_weeks.week
    GROUP BY
        reserve_weeks.spoke,
        reserve_weeks.reserveId,
        reserve_weeks.week
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
        carried_amount_per_share.amount_per_share,
        carried_share_balances.current_supplied_shares_raw * carried_amount_per_share.amount_per_share / POWER(10, reserve_asset_map.decimals) AS current_supplied_amount,
        latest_weekly_prices.price AS asset_price_usd
    FROM carried_share_balances
    INNER JOIN reserve_asset_map
        ON carried_share_balances.spoke = reserve_asset_map.spoke
       AND carried_share_balances.reserveId = reserve_asset_map.reserveId
    INNER JOIN carried_amount_per_share
        ON carried_share_balances.spoke = carried_amount_per_share.spoke
       AND carried_share_balances.reserveId = carried_amount_per_share.reserveId
       AND carried_share_balances.week = carried_amount_per_share.week
    LEFT JOIN latest_weekly_prices
        ON reserve_asset_map.address = latest_weekly_prices.contract_address
       AND carried_share_balances.week = latest_weekly_prices.week
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
