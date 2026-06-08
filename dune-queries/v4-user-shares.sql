-- Net supplied shares across all V4 spokes.
-- Replace <v4_all_events_query_id> with the saved Dune query id for v4-all-events.sql.

WITH user_events AS (
    SELECT
        user,
        spoke,
        reserveId,
        CASE
            WHEN event_type = 'supply' THEN shares_raw
            WHEN event_type = 'withdraw' THEN -shares_raw
            WHEN event_type = 'liquidation' THEN -shares_raw
        END AS share_delta_raw
    FROM query_<v4_all_events_query_id>
    WHERE event_type IN ('supply', 'withdraw', 'liquidation')
)

SELECT
    user,
    spoke,
    reserveId,
    SUM(share_delta_raw) AS current_supplied_shares_raw
FROM user_events
GROUP BY
    user,
    spoke,
    reserveId
HAVING SUM(share_delta_raw) > 0
ORDER BY
    current_supplied_shares_raw DESC
