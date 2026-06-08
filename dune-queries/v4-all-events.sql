-- All core user events across all Aave V4 Ethereum spokes.
-- Single source of truth for spoke-level event unions used by downstream V4 queries.

WITH all_events AS (
    SELECT
        'MainSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.mainspoke_evt_supply

    UNION ALL

    SELECT
        'MainSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.mainspoke_evt_withdraw

    UNION ALL

    SELECT
        'MainSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.mainspoke_evt_borrow

    UNION ALL

    SELECT
        'MainSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.mainspoke_evt_liquidationcall

    UNION ALL

    SELECT
        'BluechipSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.bluechipspoke_evt_supply

    UNION ALL

    SELECT
        'BluechipSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.bluechipspoke_evt_withdraw

    UNION ALL

    SELECT
        'BluechipSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.bluechipspoke_evt_borrow

    UNION ALL

    SELECT
        'BluechipSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.bluechipspoke_evt_liquidationcall

    UNION ALL

    SELECT
        'EthenaCorrelatedSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_supply

    UNION ALL

    SELECT
        'EthenaCorrelatedSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_withdraw

    UNION ALL

    SELECT
        'EthenaCorrelatedSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_borrow

    UNION ALL

    SELECT
        'EthenaCorrelatedSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.ethenacorrelatedspoke_evt_liquidationcall

    UNION ALL

    SELECT
        'EthenaEcosystemSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_supply

    UNION ALL

    SELECT
        'EthenaEcosystemSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_withdraw

    UNION ALL

    SELECT
        'EthenaEcosystemSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_borrow

    UNION ALL

    SELECT
        'EthenaEcosystemSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.ethenaecosystemspoke_evt_liquidationcall

    UNION ALL

    SELECT
        'EtherFiSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.etherfispoke_evt_supply

    UNION ALL

    SELECT
        'EtherFiSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.etherfispoke_evt_withdraw

    UNION ALL

    SELECT
        'EtherFiSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.etherfispoke_evt_borrow

    UNION ALL

    SELECT
        'EtherFiSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.etherfispoke_evt_liquidationcall

    UNION ALL

    SELECT
        'ForexSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.forexspoke_evt_supply

    UNION ALL

    SELECT
        'ForexSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.forexspoke_evt_withdraw

    UNION ALL

    SELECT
        'ForexSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.forexspoke_evt_borrow

    UNION ALL

    SELECT
        'ForexSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.forexspoke_evt_liquidationcall

    UNION ALL

    SELECT
        'GoldSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.goldspoke_evt_supply

    UNION ALL

    SELECT
        'GoldSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.goldspoke_evt_withdraw

    UNION ALL

    SELECT
        'GoldSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.goldspoke_evt_borrow

    UNION ALL

    SELECT
        'GoldSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.goldspoke_evt_liquidationcall

    UNION ALL

    SELECT
        'KelpSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.kelpspoke_evt_supply

    UNION ALL

    SELECT
        'KelpSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.kelpspoke_evt_withdraw

    UNION ALL

    SELECT
        'KelpSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.kelpspoke_evt_borrow

    UNION ALL

    SELECT
        'KelpSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.kelpspoke_evt_liquidationcall

    UNION ALL

    SELECT
        'LidoSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.lidospoke_evt_supply

    UNION ALL

    SELECT
        'LidoSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.lidospoke_evt_withdraw

    UNION ALL

    SELECT
        'LidoSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.lidospoke_evt_borrow

    UNION ALL

    SELECT
        'LidoSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.lidospoke_evt_liquidationcall

    UNION ALL

    SELECT
        'LombardBTCSpoke' AS spoke,
        'supply' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        suppliedAmount AS amount_raw,
        suppliedShares AS shares_raw
    FROM aave_v4_ethereum.lombardbtcspoke_evt_supply

    UNION ALL

    SELECT
        'LombardBTCSpoke' AS spoke,
        'withdraw' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        withdrawnAmount AS amount_raw,
        withdrawnShares AS shares_raw
    FROM aave_v4_ethereum.lombardbtcspoke_evt_withdraw

    UNION ALL

    SELECT
        'LombardBTCSpoke' AS spoke,
        'borrow' AS event_type,
        user,
        reserveId,
        evt_block_time,
        evt_block_date,
        drawnAmount AS amount_raw,
        drawnShares AS shares_raw
    FROM aave_v4_ethereum.lombardbtcspoke_evt_borrow

    UNION ALL

    SELECT
        'LombardBTCSpoke' AS spoke,
        'liquidation' AS event_type,
        user,
        collateralReserveId AS reserveId,
        evt_block_time,
        evt_block_date,
        collateralAmountRemoved AS amount_raw,
        collateralSharesLiquidated AS shares_raw
    FROM aave_v4_ethereum.lombardbtcspoke_evt_liquidationcall
)

SELECT
    spoke,
    event_type,
    user,
    reserveId,
    evt_block_time,
    evt_block_date,
    amount_raw,
    shares_raw
FROM all_events
