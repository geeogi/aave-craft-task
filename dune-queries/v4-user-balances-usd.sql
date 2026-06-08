-- User balances in USD across all V4 spokes.

WITH reserve_asset_map AS (
    SELECT
        hub,
        spoke,
        reserveId,
        assetId,
        decimals,
        address,
        symbol,
        price,
        amount_per_share
    FROM query_7676557
),
net_supplied_shares AS (
    SELECT
        user,
        spoke,
        reserveId,
        current_supplied_shares_raw
    FROM query_2332427
)

SELECT
    net_supplied_shares.user,
    reserve_asset_map.hub,
    net_supplied_shares.spoke,
    reserve_asset_map.symbol,
    reserve_asset_map.amount_per_share,
    net_supplied_shares.current_supplied_shares_raw * reserve_asset_map.amount_per_share / POWER(10, reserve_asset_map.decimals) AS current_supplied_amount,
    net_supplied_shares.current_supplied_shares_raw * reserve_asset_map.amount_per_share / POWER(10, reserve_asset_map.decimals) * reserve_asset_map.price AS current_position_usd
FROM net_supplied_shares
INNER JOIN reserve_asset_map
    ON net_supplied_shares.spoke = reserve_asset_map.spoke
   AND net_supplied_shares.reserveId = reserve_asset_map.reserveId
ORDER BY
    current_position_usd DESC NULLS LAST
