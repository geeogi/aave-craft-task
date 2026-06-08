-- Current user balances for selected Aave V3 Ethereum aTokens.
-- Approximates scaled balances using weekly liquidityIndex snapshots.

WITH weekly_asset_reference AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        week,
        liquidityIndex
    FROM query_7678464
),
selected_atokens AS (
    SELECT DISTINCT
        asset,
        reserve,
        a_token,
        decimals
    FROM weekly_asset_reference
),
ranked_liquidity_index AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        liquidityIndex,
        ROW_NUMBER() OVER (
            PARTITION BY reserve
            ORDER BY week DESC
        ) AS liquidity_index_rank
    FROM weekly_asset_reference
),
latest_liquidity_index AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        liquidityIndex
    FROM ranked_liquidity_index
    WHERE liquidity_index_rank = 1
),
user_transfers AS (
    SELECT
        selected_atokens.asset,
        selected_atokens.reserve,
        selected_atokens.a_token,
        selected_atokens.decimals,
        date_trunc('week', evt_block_time) AS week,
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
        date_trunc('week', evt_block_time) AS week,
        "from" AS user,
        -value AS amount_delta_raw
    FROM erc20_ethereum.evt_Transfer
    INNER JOIN selected_atokens
        ON erc20_ethereum.evt_Transfer.contract_address = selected_atokens.a_token
),
user_scaled_transfers AS (
    SELECT
        user_transfers.asset,
        user_transfers.reserve,
        user_transfers.a_token,
        user_transfers.decimals,
        user_transfers.user,
        user_transfers.amount_delta_raw * 1e27 / weekly_asset_reference.liquidityIndex AS scaled_amount_delta_raw
    FROM user_transfers
    INNER JOIN weekly_asset_reference
        ON user_transfers.reserve = weekly_asset_reference.reserve
       AND user_transfers.week = weekly_asset_reference.week
    WHERE user_transfers.user != 0x0000000000000000000000000000000000000000
),
current_scaled_balances AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        user,
        SUM(scaled_amount_delta_raw) AS current_scaled_balance_raw
    FROM user_scaled_transfers
    GROUP BY
        asset,
        reserve,
        a_token,
        decimals,
        user
    HAVING SUM(scaled_amount_delta_raw) > 0
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
    current_scaled_balances.user,
    current_scaled_balances.asset,
    current_scaled_balances.reserve,
    current_scaled_balances.a_token,
    latest_prices.symbol,
    current_scaled_balances.current_scaled_balance_raw * latest_liquidity_index.liquidityIndex / 1e27 / POWER(10, current_scaled_balances.decimals) AS current_a_token_balance,
    latest_prices.price AS asset_price_usd,
    current_scaled_balances.current_scaled_balance_raw * latest_liquidity_index.liquidityIndex / 1e27 / POWER(10, current_scaled_balances.decimals) * latest_prices.price AS current_balance_usd
FROM current_scaled_balances
INNER JOIN latest_liquidity_index
    ON current_scaled_balances.reserve = latest_liquidity_index.reserve
LEFT JOIN latest_prices
    ON current_scaled_balances.reserve = latest_prices.contract_address
ORDER BY
    current_balance_usd DESC NULLS LAST
