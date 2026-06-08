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
weekly_user_transfers AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        week,
        user,
        weekly_amount_delta_raw
    FROM query_7678569
),
user_scaled_transfers AS (
    SELECT
        weekly_user_transfers.asset,
        weekly_user_transfers.reserve,
        weekly_user_transfers.a_token,
        weekly_user_transfers.decimals,
        weekly_user_transfers.user,
        weekly_user_transfers.weekly_amount_delta_raw * 1e27 / weekly_asset_reference.liquidityIndex AS scaled_amount_delta_raw
    FROM weekly_user_transfers
    INNER JOIN weekly_asset_reference
        ON weekly_user_transfers.reserve = weekly_asset_reference.reserve
       AND weekly_user_transfers.week = weekly_asset_reference.week
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
