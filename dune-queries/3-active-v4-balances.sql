-- V4 users on Ethereum Main Spoke with active supplied positions, valued in USD.
-- https://dune.com/queries/7676585

WITH active_positions AS (
    SELECT
        user,
        reserveId,
        current_supplied_shares_raw
    FROM query_2332427
),
reserve_asset_map AS (
    SELECT
        spoke,
        reserveId,
        assetId,
        decimals,
        address AS asset_address,
        symbol,
        price
    FROM query_7676557
)

SELECT
    active_positions.user,
    reserve_asset_map.symbol,
    -- Using shares as amounts, for ease for now
    active_positions.current_supplied_shares_raw / POWER(10, reserve_asset_map.decimals) AS current_supplied_amount,
    active_positions.current_supplied_shares_raw / POWER(10, reserve_asset_map.decimals) * reserve_asset_map.price AS current_position_usd
FROM active_positions
INNER JOIN reserve_asset_map
    ON active_positions.reserveId = reserve_asset_map.reserveId
ORDER BY current_position_usd DESC NULLS LAST
