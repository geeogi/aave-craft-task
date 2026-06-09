-- Shared symbol -> category mapping for Aave asset exposure analysis.
-- Downstream queries should LEFT JOIN on symbol and default unmatched symbols to 'Other'.
-- https://dune.com/queries/7684965

WITH category_ordering AS (
    SELECT 'ETH' AS asset_category, 1 AS category_order
    UNION ALL
    SELECT 'Stablecoins', 2
    UNION ALL
    SELECT 'Incentivised stablecoins', 3
    UNION ALL
    SELECT 'Yield coins', 4
    UNION ALL
    SELECT 'BTC', 5
    UNION ALL
    SELECT 'LST', 6
),
symbol_categories AS (
    SELECT 'ETH' AS symbol, 'ETH' AS asset_category
    UNION ALL
    SELECT 'WETH', 'ETH'

    UNION ALL
    SELECT 'USDC', 'Stablecoins'
    UNION ALL
    SELECT 'USDC.e', 'Stablecoins'
    UNION ALL
    SELECT 'USDT', 'Stablecoins'
    UNION ALL
    SELECT 'DAI', 'Stablecoins'
    UNION ALL
    SELECT 'USDS', 'Stablecoins'
    UNION ALL
    SELECT 'GHO', 'Stablecoins'
    UNION ALL
    SELECT 'LUSD', 'Stablecoins'
    UNION ALL
    SELECT 'FRAX', 'Stablecoins'
    UNION ALL
    SELECT 'crvUSD', 'Stablecoins'
    UNION ALL
    SELECT 'PYUSD', 'Stablecoins'
    UNION ALL
    SELECT 'TUSD', 'Stablecoins'
    UNION ALL
    SELECT 'USDP', 'Stablecoins'
    UNION ALL
    SELECT 'EURC', 'Stablecoins'
    UNION ALL
    SELECT 'RLUSD', 'Stablecoins'

    UNION ALL
    SELECT 'USDe', 'Incentivised stablecoins'
    UNION ALL
    SELECT 'USDG', 'Incentivised stablecoins'
    UNION ALL
    SELECT 'frxUSD', 'Incentivised stablecoins'
    UNION ALL
    SELECT 'sUSDe', 'Yield coins'

    UNION ALL
    SELECT 'WBTC', 'BTC'
    UNION ALL
    SELECT 'cbBTC', 'BTC'
    UNION ALL
    SELECT 'tBTC', 'BTC'
    UNION ALL
    SELECT 'renBTC', 'BTC'
    UNION ALL
    SELECT 'LBTC', 'BTC'

    UNION ALL
    SELECT 'stETH', 'LST'
    UNION ALL
    SELECT 'wstETH', 'LST'
    UNION ALL
    SELECT 'eETH', 'LST'
    UNION ALL
    SELECT 'weETH', 'LST'
    UNION ALL
    SELECT 'ezETH', 'LST'
    UNION ALL
    SELECT 'rsETH', 'LST'
    UNION ALL
    SELECT 'rETH', 'LST'
    UNION ALL
    SELECT 'cbETH', 'LST'
    UNION ALL
    SELECT 'frxETH', 'LST'
    UNION ALL
    SELECT 'sfrxETH', 'LST'
    UNION ALL
    SELECT 'osETH', 'LST'
    UNION ALL
    SELECT 'swETH', 'LST'
    UNION ALL
    SELECT 'ETHx', 'LST'
    UNION ALL
    SELECT 'mETH', 'LST'
    UNION ALL
    SELECT 'ankrETH', 'LST'
    UNION ALL
    SELECT 'OETH', 'LST'
    UNION ALL
    SELECT 'pufETH', 'LST'
    UNION ALL
    SELECT 'uniETH', 'LST'
    UNION ALL
    SELECT 'STONE', 'LST'
)

SELECT
    symbol_categories.symbol,
    symbol_categories.asset_category,
    category_ordering.category_order
FROM symbol_categories
INNER JOIN category_ordering
    ON symbol_categories.asset_category = category_ordering.asset_category
ORDER BY
    category_ordering.category_order,
    symbol_categories.symbol
