-- Weekly Aave V4 asset reference across all Ethereum spokes.
-- Includes static reserve metadata plus carried-forward weekly amount_per_share and weekly price.

WITH spokes AS (
    SELECT
        'MainSpoke' AS spoke,
        0x94e7A5dCbE816e498b89aB752661904E2F56c485 AS spoke_address

    UNION ALL

    SELECT
        'BluechipSpoke' AS spoke,
        0x973a023A77420ba610f06b3858aD991Df6d85A08 AS spoke_address

    UNION ALL

    SELECT
        'EthenaCorrelatedSpoke' AS spoke,
        0x58131E79531caB1d52301228d1f7b842F26B9649 AS spoke_address

    UNION ALL

    SELECT
        'EthenaEcosystemSpoke' AS spoke,
        0xba1B3D55D249692b669A164024A838309B7508AF AS spoke_address

    UNION ALL

    SELECT
        'EtherFiSpoke' AS spoke,
        0xbF10BDfE177dE0336aFD7fcCF80A904E15386219 AS spoke_address

    UNION ALL

    SELECT
        'ForexSpoke' AS spoke,
        0xD8B93635b8C6d0fF98CbE90b5988E3F2d1Cd9da1 AS spoke_address

    UNION ALL

    SELECT
        'GoldSpoke' AS spoke,
        0x65407b940966954b23dfA3caA5C0702bB42984DC AS spoke_address

    UNION ALL

    SELECT
        'KelpSpoke' AS spoke,
        0x3131FE68C4722e726fe6B2819ED68e514395B9a4 AS spoke_address

    UNION ALL

    SELECT
        'LidoSpoke' AS spoke,
        0xe1900480ac69f0B296841Cd01cC37546d92F35Cd AS spoke_address

    UNION ALL

    SELECT
        'LombardBTCSpoke' AS spoke,
        0x7EC68b5695e803e98a21a9A05d744F28b0a7753D AS spoke_address
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
