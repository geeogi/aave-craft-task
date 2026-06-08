-- Aave V4 Ethereum Main Spoke reserve metadata.
-- Maps Main Spoke `reserveId` values to Hub-level asset metadata via `assetId`.
-- https://dune.com/queries/7676557

WITH assets AS (
    SELECT
        assetId,
        decimals,
        underlying
    FROM aave_v4_ethereum.corehub_evt_addasset
),
reserves AS (
    SELECT
        reserveId,
        assetId,
        hub
    FROM aave_v4_ethereum.mainspoke_evt_addreserve
),
latest_prices AS (
    SELECT
        contract_address,
        symbol,
        price
    FROM prices.latest
    WHERE blockchain = 'ethereum'
)

SELECT
    'ethereum_mainspoke' AS spoke,
    reserves.reserveId,
    reserves.assetId,
    assets.decimals,
    assets.underlying AS address,
    latest_prices.symbol,
    latest_prices.price,
    reserves.hub
FROM reserves
INNER JOIN assets
    ON reserves.assetId = assets.assetId
LEFT JOIN latest_prices
    ON assets.underlying = latest_prices.contract_address
ORDER BY
    reserves.reserveId
