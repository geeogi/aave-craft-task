-- Weekly net aToken transfer deltas for selected Aave V3 Ethereum assets.
-- https://dune.com/queries/7678569

WITH weekly_asset_reference AS (
    SELECT
        asset,
        reserve,
        a_token,
        decimals
    FROM dune.geeogi_team.result_aave_v3_ethereum_asset_reference_weekly
),
selected_atokens AS (
    SELECT DISTINCT
        asset,
        reserve,
        a_token,
        decimals
    FROM weekly_asset_reference
),
user_transfers AS (
    SELECT
        selected_atokens.asset,
        selected_atokens.reserve,
        selected_atokens.a_token,
        selected_atokens.decimals,
        date_trunc('week', evt_block_time) AS week,
        "to" AS user,
        value AS amount_delta_raw
    FROM erc20_ethereum.evt_Transfer
    INNER JOIN selected_atokens
        ON erc20_ethereum.evt_Transfer.contract_address = selected_atokens.a_token

    UNION ALL

    SELECT
        selected_atokens.asset,
        selected_atokens.reserve,
        selected_atokens.a_token,
        selected_atokens.decimals,
        date_trunc('week', evt_block_time) AS week,
        "from" AS user,
        -value AS amount_delta_raw
    FROM erc20_ethereum.evt_Transfer
    INNER JOIN selected_atokens
        ON erc20_ethereum.evt_Transfer.contract_address = selected_atokens.a_token
)

SELECT
    asset,
    reserve,
    a_token,
    decimals,
    week,
    user,
    SUM(amount_delta_raw) AS weekly_amount_delta_raw
FROM user_transfers
WHERE user != 0x0000000000000000000000000000000000000000
GROUP BY
    asset,
    reserve,
    a_token,
    decimals,
    week,
    user
HAVING SUM(amount_delta_raw) != 0
