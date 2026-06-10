-- Weekly constant-price dollar retention for selected Aave V3 Ethereum assets.
-- Cohort entry is the first week a user has total balance >= 100 USD.
-- Later balances are valued using each held asset's cohort-week price.
-- This counts capital retained on Aave even if users rotate between assets.
-- https://dune.com/queries/7682869
-- https://dune.com/queries/7682869/11639552

WITH params AS (
    SELECT
        100 AS min_balance_usd,
        TIMESTAMP '2026-03-30' AS min_cohort_week
),
weekly_positions AS (
    SELECT
        week,
        user,
        asset,
        reserve,
        a_token,
        current_a_token_balance,
        asset_price_usd,
        current_balance_usd
    FROM dune.geeogi_team.result_aave_v3_ethereum_user_balances_weekly
),
weekly_user_balances AS (
    SELECT
        week,
        user,
        SUM(current_balance_usd) AS current_balance_usd
    FROM weekly_positions
    GROUP BY
        week,
        user
),
user_cohorts AS (
    SELECT
        user,
        MIN(week) AS cohort_week
    FROM weekly_user_balances
    CROSS JOIN params
    WHERE current_balance_usd >= params.min_balance_usd
    GROUP BY user
),
analysis_cohorts AS (
    SELECT
        user,
        cohort_week
    FROM user_cohorts
    CROSS JOIN params
    WHERE cohort_week >= params.min_cohort_week
),
cohort_sizes AS (
    SELECT
        cohort_week,
        COUNT(*) AS cohort_users
    FROM analysis_cohorts
    GROUP BY cohort_week
),
cohort_start_values AS (
    SELECT
        analysis_cohorts.cohort_week,
        SUM(weekly_positions.current_balance_usd) AS cohort_start_balance_usd
    FROM analysis_cohorts
    INNER JOIN weekly_positions
        ON analysis_cohorts.user = weekly_positions.user
       AND analysis_cohorts.cohort_week = weekly_positions.week
    GROUP BY analysis_cohorts.cohort_week
),
observation_weeks AS (
    SELECT DISTINCT
        week
    FROM weekly_positions
),
cohort_week_asset_prices AS (
    SELECT DISTINCT
        week,
        reserve,
        a_token,
        asset_price_usd AS cohort_price_usd
    FROM weekly_positions
),
cohort_user_weeks AS (
    SELECT
        analysis_cohorts.cohort_week,
        observation_weeks.week AS observation_week,
        analysis_cohorts.user
    FROM analysis_cohorts
    INNER JOIN observation_weeks
        ON observation_weeks.week >= analysis_cohorts.cohort_week
),
-- Reprice each later-held asset using its price in the user's cohort week.
cohort_position_values_by_week AS (
    SELECT
        cohort_user_weeks.cohort_week,
        cohort_user_weeks.observation_week,
        cohort_user_weeks.user,
        COALESCE(weekly_positions.current_a_token_balance, 0) AS observation_amount,
        COALESCE(cohort_week_asset_prices.cohort_price_usd, 0) AS cohort_price_usd
    FROM cohort_user_weeks
    LEFT JOIN weekly_positions
        ON cohort_user_weeks.user = weekly_positions.user
       AND cohort_user_weeks.observation_week = weekly_positions.week
    LEFT JOIN cohort_week_asset_prices
        ON cohort_user_weeks.cohort_week = cohort_week_asset_prices.week
       AND weekly_positions.reserve = cohort_week_asset_prices.reserve
       AND weekly_positions.a_token = cohort_week_asset_prices.a_token
),
retention_values_by_week AS (
    SELECT
        cohort_week,
        observation_week,
        SUM(observation_amount * cohort_price_usd) AS retained_balance_usd
    FROM cohort_position_values_by_week
    GROUP BY
        cohort_week,
        observation_week
)

SELECT
    retention_values_by_week.cohort_week,
    CAST(retention_values_by_week.cohort_week AS date) AS cohort_date,
    CONCAT(
        CAST(day_of_month(retention_values_by_week.cohort_week) AS varchar),
        CASE
            WHEN day_of_month(retention_values_by_week.cohort_week) IN (11, 12, 13) THEN 'th'
            WHEN mod(day_of_month(retention_values_by_week.cohort_week), 10) = 1 THEN 'st'
            WHEN mod(day_of_month(retention_values_by_week.cohort_week), 10) = 2 THEN 'nd'
            WHEN mod(day_of_month(retention_values_by_week.cohort_week), 10) = 3 THEN 'rd'
            ELSE 'th'
        END,
        ' ',
        date_format(retention_values_by_week.cohort_week, '%b')
    ) AS cohort_label,
    retention_values_by_week.observation_week,
    date_diff('week', retention_values_by_week.cohort_week, retention_values_by_week.observation_week) AS weeks_since_cohort,
    cohort_sizes.cohort_users,
    cohort_start_values.cohort_start_balance_usd,
    retention_values_by_week.retained_balance_usd,
    retention_values_by_week.retained_balance_usd * 100.0 / cohort_start_values.cohort_start_balance_usd AS retained_balance_pct
FROM retention_values_by_week
INNER JOIN cohort_sizes
    ON retention_values_by_week.cohort_week = cohort_sizes.cohort_week
INNER JOIN cohort_start_values
    ON retention_values_by_week.cohort_week = cohort_start_values.cohort_week
ORDER BY
    retention_values_by_week.cohort_week,
    retention_values_by_week.observation_week
