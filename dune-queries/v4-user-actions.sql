-- User supply and borrow activity across all Aave V4 Ethereum spokes.
-- One row per address that has ever supplied to V4.

WITH asset_reference AS (
    SELECT DISTINCT
        hub,
        spoke,
        reserveId,
        decimals,
        address
    FROM query_7676557
),
prices_day AS (
    SELECT
        contract_address,
        CAST(timestamp AS date) AS price_date,
        price
    FROM prices.day
    WHERE blockchain = 'ethereum'
),
supply_events AS (
    SELECT
        user,
        spoke,
        reserveId,
        evt_block_date,
        amount_raw
    FROM query_<v4_all_events_query_id>
    WHERE event_type = 'supply'
),
borrow_events AS (
    SELECT
        user,
        spoke,
        reserveId,
        evt_block_date,
        amount_raw
    FROM query_<v4_all_events_query_id>
    WHERE event_type = 'borrow'
),
priced_supply_events AS (
    SELECT
        supply_events.user,
        supply_events.evt_block_date,
        supply_events.amount_raw / POWER(10, asset_reference.decimals) * prices_day.price AS amount_usd
    FROM supply_events
    INNER JOIN asset_reference
        ON supply_events.spoke = asset_reference.spoke
       AND supply_events.reserveId = asset_reference.reserveId
    LEFT JOIN prices_day
        ON asset_reference.address = prices_day.contract_address
       AND supply_events.evt_block_date = prices_day.price_date
),
priced_borrow_events AS (
    SELECT
        borrow_events.user,
        borrow_events.evt_block_date,
        borrow_events.amount_raw / POWER(10, asset_reference.decimals) * prices_day.price AS amount_usd
    FROM borrow_events
    INNER JOIN asset_reference
        ON borrow_events.spoke = asset_reference.spoke
       AND borrow_events.reserveId = asset_reference.reserveId
    LEFT JOIN prices_day
        ON asset_reference.address = prices_day.contract_address
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
