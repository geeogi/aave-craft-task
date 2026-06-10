-- Weekly net supplied share deltas across all Aave V4 Ethereum spokes.
-- We use Supply, Withdraw and Liquidation to track supply share transfers.
-- https://dune.com/queries/7682214

WITH user_shares AS (
    SELECT
        user,
        spoke,
        reserveId,
        date_trunc('week', evt_block_time) AS week,
        CASE
            WHEN event_type = 'supply' THEN shares_raw
            WHEN event_type = 'withdraw' THEN -shares_raw
            WHEN event_type = 'liquidation' THEN -shares_raw
        END AS share_delta_raw
    FROM query_7677938
    WHERE event_type IN ('supply', 'withdraw', 'liquidation')
)

SELECT
    user,
    spoke,
    reserveId,
    week,
    SUM(share_delta_raw) AS weekly_share_delta_raw
FROM user_shares
GROUP BY
    user,
    spoke,
    reserveId,
    week
HAVING SUM(share_delta_raw) != 0
