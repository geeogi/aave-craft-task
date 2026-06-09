-- Weekly constant-price dollar retention for selected Aave V3 Ethereum assets.
-- Cohort entry is the first week a user has total balance >= 100 USD.
-- Later balances are valued using each cohort asset's cohort-week price.
-- Gross retention allows asset balances to grow above cohort units.
-- Capped retention limits each asset to its cohort-week units.
-- https://dune.com/queries/7682869
-- https://dune.com/queries/7682869/11639552

WITH params AS (
    SELECT
        100 AS min_balance_usd,
        TIMESTAMP '2026-03-30' AS min_cohort_week
),
weekly_user_positions AS (
    SELECT
        week,
        user,
        asset,
        reserve,
        a_token,
        current_a_token_balance,
        asset_price_usd,
        current_balance_usd
    FROM dune.geeogi.result_aave_v3_ethereum_user_balances_weekly
),
weekly_balances AS (
    SELECT
        week,
        user,
        SUM(current_balance_usd) AS current_balance_usd
    FROM weekly_user_positions
    GROUP BY
        week,
        user
),
cohort_source AS (
    SELECT
        week,
        user
    FROM weekly_balances
    CROSS JOIN params
    WHERE current_balance_usd >= params.min_balance_usd
),
user_cohorts AS (
    SELECT
        user,
        MIN(week) AS cohort_week
    FROM cohort_source
    GROUP BY user
),
selected_cohorts AS (
    SELECT
        user_cohorts.user,
        user_cohorts.cohort_week
    FROM user_cohorts
    CROSS JOIN params
    WHERE user_cohorts.cohort_week >= params.min_cohort_week
),
cohort_sizes AS (
    SELECT
        cohort_week,
        COUNT(*) AS cohort_users
    FROM selected_cohorts
    GROUP BY cohort_week
),
cohort_positions AS (
    SELECT
        selected_cohorts.cohort_week,
        selected_cohorts.user,
        weekly_user_positions.asset,
        weekly_user_positions.reserve,
        weekly_user_positions.a_token,
        weekly_user_positions.current_a_token_balance AS cohort_amount,
        weekly_user_positions.asset_price_usd AS cohort_price_usd,
        weekly_user_positions.current_balance_usd AS cohort_position_usd
    FROM selected_cohorts
    INNER JOIN weekly_user_positions
        ON selected_cohorts.user = weekly_user_positions.user
       AND selected_cohorts.cohort_week = weekly_user_positions.week
),
cohort_start_values AS (
    SELECT
        cohort_week,
        SUM(cohort_position_usd) AS cohort_start_balance_usd
    FROM cohort_positions
    GROUP BY cohort_week
),
observation_weeks AS (
    SELECT DISTINCT
        week
    FROM weekly_user_positions
),
cohort_position_observations AS (
    SELECT
        cohort_positions.cohort_week,
        observation_weeks.week AS observation_week,
        cohort_positions.user,
        cohort_positions.asset,
        cohort_positions.reserve,
        cohort_positions.a_token,
        cohort_positions.cohort_amount,
        cohort_positions.cohort_price_usd,
        COALESCE(weekly_user_positions.current_a_token_balance, 0) AS observation_amount
    FROM cohort_positions
    INNER JOIN observation_weeks
        ON observation_weeks.week >= cohort_positions.cohort_week
    LEFT JOIN weekly_user_positions
        ON cohort_positions.user = weekly_user_positions.user
       AND cohort_positions.reserve = weekly_user_positions.reserve
       AND cohort_positions.a_token = weekly_user_positions.a_token
       AND observation_weeks.week = weekly_user_positions.week
),
cohort_observation_values AS (
    SELECT
        cohort_week,
        observation_week,
        SUM(observation_amount * cohort_price_usd) AS gross_retained_balance_usd,
        SUM(LEAST(observation_amount, cohort_amount) * cohort_price_usd) AS capped_retained_balance_usd
    FROM cohort_position_observations
    GROUP BY
        cohort_week,
        observation_week
)

SELECT
    cohort_observation_values.cohort_week,
    CAST(cohort_observation_values.cohort_week AS date) AS cohort_date,
    CONCAT(
        CAST(day_of_month(cohort_observation_values.cohort_week) AS varchar),
        CASE
            WHEN day_of_month(cohort_observation_values.cohort_week) IN (11, 12, 13) THEN 'th'
            WHEN mod(day_of_month(cohort_observation_values.cohort_week), 10) = 1 THEN 'st'
            WHEN mod(day_of_month(cohort_observation_values.cohort_week), 10) = 2 THEN 'nd'
            WHEN mod(day_of_month(cohort_observation_values.cohort_week), 10) = 3 THEN 'rd'
            ELSE 'th'
        END,
        ' ',
        date_format(cohort_observation_values.cohort_week, '%b')
    ) AS cohort_label,
    cohort_observation_values.observation_week,
    date_diff('week', cohort_observation_values.cohort_week, cohort_observation_values.observation_week) AS weeks_since_cohort,
    cohort_sizes.cohort_users,
    cohort_start_values.cohort_start_balance_usd,
    cohort_observation_values.gross_retained_balance_usd,
    cohort_observation_values.gross_retained_balance_usd * 100.0 / cohort_start_values.cohort_start_balance_usd AS gross_retained_balance_pct,
    cohort_observation_values.capped_retained_balance_usd,
    cohort_observation_values.capped_retained_balance_usd * 100.0 / cohort_start_values.cohort_start_balance_usd AS capped_retained_balance_pct
FROM cohort_observation_values
INNER JOIN cohort_sizes
    ON cohort_observation_values.cohort_week = cohort_sizes.cohort_week
INNER JOIN cohort_start_values
    ON cohort_observation_values.cohort_week = cohort_start_values.cohort_week
ORDER BY
    cohort_observation_values.cohort_week,
    cohort_observation_values.observation_week
