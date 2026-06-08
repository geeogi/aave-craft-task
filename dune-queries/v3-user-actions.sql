-- User supply, withdraw, borrow, and repay activity across Aave V3 Ethereum.
-- One row per address that has ever supplied to V3.
-- Uses Supply.onBehalfOf, Withdraw.user, Borrow.onBehalfOf, and Repay.user for user attribution.

WITH daily_prices AS (
    SELECT
        contract_address,
        CAST(timestamp AS date) AS price_date,
        price
    FROM prices.day
    WHERE blockchain = 'ethereum'
),
supply_events AS (
    SELECT
        onBehalfOf AS user,
        reserve,
        evt_block_date,
        amount AS amount_raw
    FROM aave_v3_ethereum.pool_evt_supply
),
withdraw_events AS (
    SELECT
        user,
        reserve,
        evt_block_date,
        amount AS amount_raw
    FROM aave_v3_ethereum.pool_evt_withdraw
),
borrow_events AS (
    SELECT
        onBehalfOf AS user,
        reserve,
        evt_block_date,
        amount AS amount_raw
    FROM aave_v3_ethereum.pool_evt_borrow
),
repay_events AS (
    SELECT
        user,
        reserve,
        evt_block_date,
        amount AS amount_raw
    FROM aave_v3_ethereum.pool_evt_repay
),
token_decimals AS (
    SELECT
        contract_address,
        decimals
    FROM tokens.erc20
    WHERE blockchain = 'ethereum'
),
priced_supply_events AS (
    SELECT
        supply_events.user,
        supply_events.evt_block_date,
        supply_events.amount_raw / POWER(10, token_decimals.decimals) * daily_prices.price AS amount_usd
    FROM supply_events
    LEFT JOIN token_decimals
        ON supply_events.reserve = token_decimals.contract_address
    LEFT JOIN daily_prices
        ON supply_events.reserve = daily_prices.contract_address
       AND supply_events.evt_block_date = daily_prices.price_date
),
priced_withdraw_events AS (
    SELECT
        withdraw_events.user,
        withdraw_events.evt_block_date,
        withdraw_events.amount_raw / POWER(10, token_decimals.decimals) * daily_prices.price AS amount_usd
    FROM withdraw_events
    LEFT JOIN token_decimals
        ON withdraw_events.reserve = token_decimals.contract_address
    LEFT JOIN daily_prices
        ON withdraw_events.reserve = daily_prices.contract_address
       AND withdraw_events.evt_block_date = daily_prices.price_date
),
priced_borrow_events AS (
    SELECT
        borrow_events.user,
        borrow_events.evt_block_date,
        borrow_events.amount_raw / POWER(10, token_decimals.decimals) * daily_prices.price AS amount_usd
    FROM borrow_events
    LEFT JOIN token_decimals
        ON borrow_events.reserve = token_decimals.contract_address
    LEFT JOIN daily_prices
        ON borrow_events.reserve = daily_prices.contract_address
       AND borrow_events.evt_block_date = daily_prices.price_date
),
priced_repay_events AS (
    SELECT
        repay_events.user,
        repay_events.evt_block_date,
        repay_events.amount_raw / POWER(10, token_decimals.decimals) * daily_prices.price AS amount_usd
    FROM repay_events
    LEFT JOIN token_decimals
        ON repay_events.reserve = token_decimals.contract_address
    LEFT JOIN daily_prices
        ON repay_events.reserve = daily_prices.contract_address
       AND repay_events.evt_block_date = daily_prices.price_date
),
supply_metrics AS (
    SELECT
        user,
        COUNT(*) AS supply_event_count,
        SUM(amount_usd) AS supply_volume_usd,
        MIN(evt_block_date) AS first_supply_event_date,
        MAX(evt_block_date) AS last_supply_event_date
    FROM priced_supply_events
    GROUP BY user
),
withdraw_metrics AS (
    SELECT
        user,
        COUNT(*) AS withdraw_event_count,
        SUM(amount_usd) AS withdraw_volume_usd,
        MIN(evt_block_date) AS first_withdraw_event_date,
        MAX(evt_block_date) AS last_withdraw_event_date
    FROM priced_withdraw_events
    GROUP BY user
),
borrow_metrics AS (
    SELECT
        user,
        COUNT(*) AS borrow_event_count,
        SUM(amount_usd) AS borrow_volume_usd,
        MIN(evt_block_date) AS first_borrow_event_date,
        MAX(evt_block_date) AS last_borrow_event_date
    FROM priced_borrow_events
    GROUP BY user
),
repay_metrics AS (
    SELECT
        user,
        COUNT(*) AS repay_event_count,
        SUM(amount_usd) AS repay_volume_usd,
        MIN(evt_block_date) AS first_repay_event_date,
        MAX(evt_block_date) AS last_repay_event_date
    FROM priced_repay_events
    GROUP BY user
)

SELECT
    supply_metrics.user,
    supply_metrics.supply_event_count,
    supply_metrics.supply_volume_usd,
    supply_metrics.first_supply_event_date,
    supply_metrics.last_supply_event_date,
    COALESCE(withdraw_metrics.withdraw_event_count, 0) AS withdraw_event_count,
    COALESCE(withdraw_metrics.withdraw_volume_usd, 0) AS withdraw_volume_usd,
    withdraw_metrics.first_withdraw_event_date,
    withdraw_metrics.last_withdraw_event_date,
    COALESCE(borrow_metrics.borrow_event_count, 0) AS borrow_event_count,
    COALESCE(borrow_metrics.borrow_volume_usd, 0) AS borrow_volume_usd,
    borrow_metrics.first_borrow_event_date,
    borrow_metrics.last_borrow_event_date,
    COALESCE(repay_metrics.repay_event_count, 0) AS repay_event_count,
    COALESCE(repay_metrics.repay_volume_usd, 0) AS repay_volume_usd,
    repay_metrics.first_repay_event_date,
    repay_metrics.last_repay_event_date
FROM supply_metrics
LEFT JOIN withdraw_metrics
    ON supply_metrics.user = withdraw_metrics.user
LEFT JOIN borrow_metrics
    ON supply_metrics.user = borrow_metrics.user
LEFT JOIN repay_metrics
    ON supply_metrics.user = repay_metrics.user
ORDER BY
    supply_metrics.supply_volume_usd DESC NULLS LAST
