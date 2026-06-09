-- Weekly scaled aToken transfer deltas for selected Aave V3 Ethereum assets.
-- https://dune.com/queries/7678693

WITH weekly_asset_reference AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals,
        week,
        liquidityIndex
    FROM dune.geeogi.result_aave_v3_ethereum_asset_reference_weekly
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
)

SELECT
    weekly_user_transfers.asset,
    weekly_user_transfers.reserve,
    weekly_user_transfers.a_token,
    weekly_user_transfers.decimals,
    weekly_user_transfers.week,
    weekly_user_transfers.user,
    weekly_user_transfers.weekly_amount_delta_raw * 1e27 / weekly_asset_reference.liquidityIndex AS scaled_amount_delta_raw
FROM weekly_user_transfers
INNER JOIN weekly_asset_reference
    ON weekly_user_transfers.reserve = weekly_asset_reference.reserve
   AND weekly_user_transfers.week = weekly_asset_reference.week
