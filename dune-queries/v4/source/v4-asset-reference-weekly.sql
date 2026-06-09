-- Weekly Aave V4 asset reference across all Ethereum spokes.
-- https://dune.com/queries/7676557
-- dune.geeogi.result_aave_v4_ethereum_asset_reference_weekly

WITH params AS (
    SELECT DATE '2026-03-28' AS min_week_start
),
hubs AS (
    SELECT
        'CoreHub' AS hub,
        0xCca852Bc40e560adC3b1Cc58CA5b55638ce826c9 AS hub_address

    UNION ALL

    SELECT
        'PlusHub' AS hub,
        0x06002e9c4412CB7814a791eA3666D905871E536A AS hub_address

    UNION ALL

    SELECT
        'PrimeHub' AS hub,
        0x943827DCA022D0F354a8a8c332dA1e5Eb9f9F931 AS hub_address
),
all_assets AS (
    SELECT
        'CoreHub' AS hub,
        assetId,
        decimals,
        underlying AS address
    FROM aave_v4_ethereum.corehub_evt_addasset

    UNION ALL

    SELECT
        'PlusHub' AS hub,
        assetId,
        decimals,
        underlying AS address
    FROM aave_v4_ethereum.plushub_evt_addasset

    UNION ALL

    SELECT
        'PrimeHub' AS hub,
        assetId,
        decimals,
        underlying AS address
    FROM aave_v4_ethereum.primehub_evt_addasset
),
spoke_reserves AS (
    SELECT
        'MainSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.mainspoke_evt_addreserve

    UNION ALL

    SELECT
        'BluechipSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.bluechipspoke_evt_addreserve

    UNION ALL

    SELECT
        'EthenaCorrelatedSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_addreserve

    UNION ALL

    SELECT
        'EthenaEcosystemSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_addreserve

    UNION ALL

    SELECT
        'EtherFiSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.etherfispoke_evt_addreserve

    UNION ALL

    SELECT
        'ForexSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.forexspoke_evt_addreserve

    UNION ALL

    SELECT
        'GoldSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.goldspoke_evt_addreserve

    UNION ALL

    SELECT
        'KelpSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.kelpspoke_evt_addreserve

    UNION ALL

    SELECT
        'LidoSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.lidospoke_evt_addreserve

    UNION ALL

    SELECT
        'LombardBTCSpoke' AS spoke,
        hub AS hub_address,
        reserveId,
        assetId
    FROM aave_v4_ethereum.lombardbtcspoke_evt_addreserve
),
latest_symbols AS (
    SELECT
        contract_address,
        symbol
    FROM prices.latest
    WHERE blockchain = 'ethereum'
),
reserve_asset_map AS (
    SELECT
        hubs.hub,
        spoke_reserves.spoke,
        spoke_reserves.reserveId,
        spoke_reserves.assetId,
        all_assets.decimals,
        all_assets.address,
        latest_symbols.symbol
    FROM spoke_reserves
    INNER JOIN hubs
        ON spoke_reserves.hub_address = hubs.hub_address
    INNER JOIN all_assets
        ON hubs.hub = all_assets.hub
       AND spoke_reserves.assetId = all_assets.assetId
    LEFT JOIN latest_symbols
        ON all_assets.address = latest_symbols.contract_address
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
weekly_asset_prices AS (
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
    FROM weekly_asset_prices
    WHERE price_rank = 1
),
reserve_weeks AS (
    SELECT DISTINCT
        reserve_asset_map.spoke,
        reserve_asset_map.reserveId,
        latest_weekly_prices.week
    FROM reserve_asset_map
    INNER JOIN latest_weekly_prices
        ON reserve_asset_map.address = latest_weekly_prices.contract_address
    CROSS JOIN params
    WHERE latest_weekly_prices.week > params.min_week_start
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
)

SELECT
    reserve_asset_map.hub,
    reserve_asset_map.spoke,
    reserve_asset_map.reserveId,
    reserve_asset_map.assetId,
    reserve_asset_map.decimals,
    reserve_asset_map.address,
    reserve_asset_map.symbol,
    carried_amount_per_share.week,
    carried_amount_per_share.amount_per_share,
    latest_weekly_prices.price AS asset_price_usd
FROM reserve_asset_map
INNER JOIN carried_amount_per_share
    ON reserve_asset_map.spoke = carried_amount_per_share.spoke
   AND reserve_asset_map.reserveId = carried_amount_per_share.reserveId
LEFT JOIN latest_weekly_prices
    ON reserve_asset_map.address = latest_weekly_prices.contract_address
   AND carried_amount_per_share.week = latest_weekly_prices.week
