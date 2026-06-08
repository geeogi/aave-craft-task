-- Net supplied shares across all V4 spokes.
-- https://dune.com/queries/2332427

WITH user_events AS (
    -- Net shares for MainSpoke
    SELECT
        user,
        'MainSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.mainspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'MainSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.mainspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'MainSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.mainspoke_evt_liquidationcall

    UNION ALL

    -- Net shares for BluechipSpoke
    SELECT
        user,
        'BluechipSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.bluechipspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'BluechipSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.bluechipspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'BluechipSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.bluechipspoke_evt_liquidationcall

    UNION ALL

    -- Net shares for EthenaCorrelatedSpoke
    SELECT
        user,
        'EthenaCorrelatedSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'EthenaCorrelatedSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'EthenaCorrelatedSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_liquidationcall

    UNION ALL

    -- Net shares for EthenaEcosystemSpoke
    SELECT
        user,
        'EthenaEcosystemSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'EthenaEcosystemSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'EthenaEcosystemSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_liquidationcall

    UNION ALL

    -- Net shares for EtherFiSpoke
    SELECT
        user,
        'EtherFiSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.etherfispoke_evt_supply

    UNION ALL

    SELECT
        user,
        'EtherFiSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.etherfispoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'EtherFiSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.etherfispoke_evt_liquidationcall

    UNION ALL

    -- Net shares for ForexSpoke
    SELECT
        user,
        'ForexSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.forexspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'ForexSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.forexspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'ForexSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.forexspoke_evt_liquidationcall

    UNION ALL

    -- Net shares for GoldSpoke
    SELECT
        user,
        'GoldSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.goldspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'GoldSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.goldspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'GoldSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.goldspoke_evt_liquidationcall

    UNION ALL

    -- Net shares for KelpSpoke
    SELECT
        user,
        'KelpSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.kelpspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'KelpSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.kelpspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'KelpSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.kelpspoke_evt_liquidationcall

    UNION ALL

    -- Net shares for LidoSpoke
    SELECT
        user,
        'LidoSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.lidospoke_evt_supply

    UNION ALL

    SELECT
        user,
        'LidoSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.lidospoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'LidoSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.lidospoke_evt_liquidationcall

    UNION ALL

    -- Net shares for LombardBTCSpoke
    SELECT
        user,
        'LombardBTCSpoke' AS spoke,
        reserveId,
        suppliedShares AS share_delta_raw
    FROM aave_v4_ethereum.lombardbtcspoke_evt_supply

    UNION ALL

    SELECT
        user,
        'LombardBTCSpoke' AS spoke,
        reserveId,
        -withdrawnShares AS share_delta_raw
    FROM aave_v4_ethereum.lombardbtcspoke_evt_withdraw

    UNION ALL

    SELECT
        user,
        'LombardBTCSpoke' AS spoke,
        collateralReserveId AS reserveId,
        -collateralSharesLiquidated AS share_delta_raw
    FROM aave_v4_ethereum.lombardbtcspoke_evt_liquidationcall
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
