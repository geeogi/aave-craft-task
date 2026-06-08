-- V4 users on Ethereum Main Spoke with active supplied positions, valued in USD.
-- Uses query 1 as the active-position input:
-- https://dune.com/queries/2332427

WITH active_positions AS (
    SELECT
        user,
        reserveId,
        current_supplied_shares_raw
    FROM query_2332427
),
reserve_asset_ids AS (
    SELECT
        reserveId,
        assetId,
        ROW_NUMBER() OVER (
            PARTITION BY reserveId
            ORDER BY evt_block_number DESC, evt_index DESC
        ) AS reserve_rank
    FROM aave_v4_ethereum.mainspoke_evt_addreserve
),
latest_reserve_asset_ids AS (
    SELECT
        reserveId,
        assetId
    FROM reserve_asset_ids
    WHERE reserve_rank = 1
),
hub_assets AS (
    SELECT
        assetId,
        underlying,
        decimals,
        ROW_NUMBER() OVER (
            PARTITION BY assetId
            ORDER BY evt_block_number DESC, evt_index DESC
        ) AS asset_rank
    FROM aave_v4_ethereum.corehub_evt_addasset
),
latest_hub_assets AS (
    SELECT
        assetId,
        underlying,
        decimals
    FROM hub_assets
    WHERE asset_rank = 1
),
reserve_underlyings AS (
    SELECT
        latest_reserve_asset_ids.reserveId,
        latest_reserve_asset_ids.assetId,
        latest_hub_assets.underlying,
        latest_hub_assets.decimals AS underlying_decimals
    FROM latest_reserve_asset_ids
    INNER JOIN latest_hub_assets
        ON latest_reserve_asset_ids.assetId = latest_hub_assets.assetId
),
latest_prices AS (
    SELECT
        contract_address,
        symbol,
        decimals,
        price
    FROM prices.latest
    WHERE blockchain = 'ethereum'
)

SELECT
    active_positions.user,
    active_positions.reserveId,
    reserve_underlyings.assetId,
    reserve_underlyings.underlying AS asset_address,
    latest_prices.symbol,
    active_positions.current_supplied_shares_raw,
    active_positions.current_supplied_shares_raw AS current_supplied_amount_raw,
    CAST(active_positions.current_supplied_shares_raw AS DOUBLE) / POWER(10, reserve_underlyings.underlying_decimals) AS current_supplied_amount,
    latest_prices.price AS asset_price_usd,
    CAST(active_positions.current_supplied_shares_raw AS DOUBLE) / POWER(10, reserve_underlyings.underlying_decimals) * latest_prices.price AS current_position_usd
FROM active_positions
INNER JOIN reserve_underlyings
    ON active_positions.reserveId = reserve_underlyings.reserveId
LEFT JOIN latest_prices
    ON reserve_underlyings.underlying = latest_prices.contract_address
ORDER BY current_position_usd DESC NULLS LAST
