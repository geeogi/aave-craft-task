-- Current user balances for selected Aave V3 Ethereum aTokens.
-- Reconstructs balances by netting ERC20 Transfer events on the aToken contracts.

WITH selected_atokens AS (
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
),
user_events AS (
    SELECT
        selected_atokens.asset,
        selected_atokens.reserve,
        selected_atokens.a_token,
        selected_atokens.decimals,
        "to" AS user,
        value AS amount_delta_raw
    FROM erc20_ethereum.evt_Transfer
    INNER JOIN selected_atokens
        ON erc20_ethereum.evt_Transfer.contract_address = selected_atokens.a_token

    UNION ALL

    SELECT
        selected_atokens.asset,
        selected_atokens.reserve,
        selected_atokens.a_token,
        selected_atokens.decimals,
        "from" AS user,
        -value AS amount_delta_raw
    FROM erc20_ethereum.evt_Transfer
    INNER JOIN selected_atokens
        ON erc20_ethereum.evt_Transfer.contract_address = selected_atokens.a_token
),
current_a_token_balances AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        user,
        SUM(amount_delta_raw) AS current_a_token_balance_raw
    FROM user_events
    WHERE user != 0x0000000000000000000000000000000000000000
    GROUP BY
        asset,
        reserve,
        a_token,
        decimals,
        user,
        reserve
    HAVING SUM(amount_delta_raw) > 0
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
    current_a_token_balances.user,
    current_a_token_balances.asset,
    current_a_token_balances.reserve,
    current_a_token_balances.a_token,
    latest_prices.symbol,
    current_a_token_balances.current_a_token_balance_raw / POWER(10, current_a_token_balances.decimals) AS current_a_token_balance,
    latest_prices.price AS asset_price_usd,
    current_a_token_balances.current_a_token_balance_raw / POWER(10, current_a_token_balances.decimals) * latest_prices.price AS current_balance_usd
FROM current_a_token_balances
LEFT JOIN latest_prices
    ON current_a_token_balances.reserve = latest_prices.contract_address
ORDER BY
    current_balance_usd DESC NULLS LAST
