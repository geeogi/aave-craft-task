-- Weekly Aave V3 reserve reference for selected Ethereum assets.
-- Uses the latest ReserveDataUpdated event in each week as the liquidityIndex snapshot.
-- https://dune.com/queries/7678464
-- dune.geeogi_team.result_aave_v3_ethereum_asset_reference_weekly

WITH selected_assets AS (
    SELECT
        'WETH' AS asset,
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 AS reserve,
        0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8 AS a_token,
        18 AS decimals

    UNION ALL

    SELECT
        'WBTC' AS asset,
        0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599 AS reserve,
        0x5Ee5bf7ae06D1Be5997A1A72006FE6C607eC6DE8 AS a_token,
        8 AS decimals

    UNION ALL

    SELECT
        'wstETH' AS asset,
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0 AS reserve,
        0x0B925eD163218f6662a35e0f0371Ac234f9E9371 AS a_token,
        18 AS decimals

    UNION ALL

    SELECT
        'weETH' AS asset,
        0xCd5fE23C85820F7B72D0926FC9b05b43E359b7ee AS reserve,
        0xBdfa7b7893081B35Fb54027489e2Bc7A38275129 AS a_token,
        18 AS decimals

    UNION ALL

    SELECT
        'rsETH' AS asset,
        0xA1290d69cA485bC62b5EA2c7cC9C42A25aC6A3A3 AS reserve,
        0x8Eb270e296023E9D92081fdF967dDd7878724424 AS a_token,
        18 AS decimals

    UNION ALL

    SELECT
        'cbBTC' AS asset,
        0xcBB7C0000aB88B473b1f5AFd9ef808440eed33BF AS reserve,
        0x5c647Ce0Ae10658ec44FA4E11A51c96E94efd1Dd AS a_token,
        8 AS decimals

    UNION ALL

    SELECT
        'USDC' AS asset,
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 AS reserve,
        0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c AS a_token,
        6 AS decimals

    UNION ALL

    SELECT
        'USDT' AS asset,
        0xdAC17F958D2ee523a2206206994597C13D831ec7 AS reserve,
        0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a AS a_token,
        6 AS decimals

    UNION ALL

    SELECT
        'USDe' AS asset,
        0x4c9EDD5852cd905f086C759E8383e09bff1E68B3 AS reserve,
        0x41393e5e337606dc3821075Af65AeE84D7688CBD AS a_token,
        18 AS decimals

    UNION ALL

    SELECT
        'sUSDe' AS asset,
        0x9D39A5DE30e57443Bff2A8307A4256C8797A3497 AS reserve,
        0x5d3a1Ff2b6BAb83b63cd9AD0787074081a52ef34 AS a_token,
        18 AS decimals
),
weekly_reserve_updates AS (
    SELECT
        aave_v3_ethereum.pool_evt_reservedataupdated.reserve AS reserve,
        date_trunc('week', aave_v3_ethereum.pool_evt_reservedataupdated.evt_block_time) AS week,
        aave_v3_ethereum.pool_evt_reservedataupdated.liquidityIndex AS liquidityIndex,
        ROW_NUMBER() OVER (
            PARTITION BY
                aave_v3_ethereum.pool_evt_reservedataupdated.reserve,
                date_trunc('week', aave_v3_ethereum.pool_evt_reservedataupdated.evt_block_time)
            ORDER BY
                aave_v3_ethereum.pool_evt_reservedataupdated.evt_block_time DESC,
                aave_v3_ethereum.pool_evt_reservedataupdated.evt_index DESC
        ) AS update_rank
    FROM aave_v3_ethereum.pool_evt_reservedataupdated
    INNER JOIN selected_assets
        ON aave_v3_ethereum.pool_evt_reservedataupdated.reserve = selected_assets.reserve
),
weekly_liquidity_index AS (
    SELECT
        reserve,
        week,
        liquidityIndex
    FROM weekly_reserve_updates
    WHERE update_rank = 1
),
asset_week_ranges AS (
    SELECT
        reserve,
        MIN(week) AS first_week
    FROM weekly_liquidity_index
    GROUP BY reserve
),
reserve_weeks AS (
    SELECT
        asset_week_ranges.reserve,
        CAST(week AS timestamp) AS week
    FROM asset_week_ranges
    CROSS JOIN UNNEST(
        sequence(
            CAST(asset_week_ranges.first_week AS date),
            CAST(date_trunc('week', current_timestamp) AS date),
            INTERVAL '7' day
        )
    ) AS weeks(week)
),
carried_liquidity_index AS (
    SELECT
        reserve_weeks.reserve,
        reserve_weeks.week,
        MAX_BY(weekly_liquidity_index.liquidityIndex, weekly_liquidity_index.week) AS liquidityIndex
    FROM reserve_weeks
    LEFT JOIN weekly_liquidity_index
        ON reserve_weeks.reserve = weekly_liquidity_index.reserve
       AND weekly_liquidity_index.week <= reserve_weeks.week
    GROUP BY
        reserve_weeks.reserve,
        reserve_weeks.week
)

SELECT
    selected_assets.asset,
    selected_assets.reserve,
    selected_assets.a_token,
    selected_assets.decimals,
    carried_liquidity_index.week,
    carried_liquidity_index.liquidityIndex
FROM carried_liquidity_index
INNER JOIN selected_assets
    ON carried_liquidity_index.reserve = selected_assets.reserve
ORDER BY
    carried_liquidity_index.week DESC,
    selected_assets.asset
