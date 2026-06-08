-- User supply and borrow activity across Aave V3 Ethereum.
-- One row per address that has ever supplied to V3.
-- Note: borrow metrics assume the standard decoded V3 borrow event table and columns.

WITH prices_day AS (
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
borrow_events AS (
    SELECT
        onBehalfOf AS user,
        reserve,
        evt_block_date,
        amount AS amount_raw
    FROM aave_v3_ethereum.pool_evt_borrow
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
        supply_events.amount_raw / POWER(10, token_decimals.decimals) * prices_day.price AS amount_usd
    FROM supply_events
    LEFT JOIN token_decimals
        ON supply_events.reserve = token_decimals.contract_address
    LEFT JOIN prices_day
        ON supply_events.reserve = prices_day.contract_address
       AND supply_events.evt_block_date = prices_day.price_date
),
priced_borrow_events AS (
    SELECT
        borrow_events.user,
        borrow_events.evt_block_date,
        borrow_events.amount_raw / POWER(10, token_decimals.decimals) * prices_day.price AS amount_usd
    FROM borrow_events
    LEFT JOIN token_decimals
        ON borrow_events.reserve = token_decimals.contract_address
    LEFT JOIN prices_day
        ON borrow_events.reserve = prices_day.contract_address
       AND borrow_events.evt_block_date = prices_day.price_date
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
borrow_metrics AS (
    SELECT
        user,
        COUNT(*) AS borrow_event_count,
        SUM(amount_usd) AS borrow_volume_usd,
        MIN(evt_block_date) AS first_borrow_event_date,
        MAX(evt_block_date) AS last_borrow_event_date
    FROM priced_borrow_events
    GROUP BY user
)

SELECT
    supply_metrics.user,
    supply_metrics.supply_event_count,
    supply_metrics.supply_volume_usd,
    supply_metrics.first_supply_event_date,
    supply_metrics.last_supply_event_date,
    COALESCE(borrow_metrics.borrow_event_count, 0) AS borrow_event_count,
    COALESCE(borrow_metrics.borrow_volume_usd, 0) AS borrow_volume_usd,
    borrow_metrics.first_borrow_event_date,
    borrow_metrics.last_borrow_event_date
FROM supply_metrics
LEFT JOIN borrow_metrics
    ON supply_metrics.user = borrow_metrics.user
ORDER BY
    supply_metrics.supply_volume_usd DESC NULLS LAST
