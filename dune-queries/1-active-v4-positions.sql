-- V4 users on Ethereum Main Spoke with a currently non-zero supplied position.
-- Positions are tracked per `user, reserveId` using share balances.

WITH user_events AS (
    SELECT
        user,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.mainspoke_evt_supply

    UNION ALL

    SELECT
        user,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.mainspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.mainspoke_evt_liquidationcall
)

SELECT
    user,
    reserveId,
    SUM(share_delta_raw) AS current_supplied_shares_raw
FROM user_events
GROUP BY
    user,
    reserveId
HAVING SUM(share_delta_raw) > 0
ORDER BY current_supplied_shares_raw DESC
