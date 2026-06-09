-- Weekly balance-based user retention curve for selected Aave V3 Ethereum assets.
-- Cohort entry is the first week a user has balance >= 100 USD.
-- Retention is whether the user also has balance >= 100 USD in later observation weeks.
-- https://dune.com/queries/7679077

WITH params AS (
    SELECT
        100 AS min_balance_usd,
        TIMESTAMP '2026-03-30' AS min_cohort_week
),
weekly_balances AS (
    SELECT
        week,
        user,
        SUM(current_balance_usd) AS current_balance_usd
    FROM dune.geeogi_team.result_aave_v3_ethereum_user_balances_weekly
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
cohort_observations AS (
    SELECT
        selected_cohorts.cohort_week,
        weekly_balances.week AS observation_week,
        selected_cohorts.user,
        weekly_balances.current_balance_usd
    FROM selected_cohorts
    INNER JOIN weekly_balances
        ON selected_cohorts.user = weekly_balances.user
       AND weekly_balances.week >= selected_cohorts.cohort_week
)

SELECT
    cohort_observations.cohort_week,
    CAST(cohort_observations.cohort_week AS date) AS cohort_date,
    CONCAT(
        CAST(day_of_month(cohort_observations.cohort_week) AS varchar),
        CASE
            WHEN day_of_month(cohort_observations.cohort_week) IN (11, 12, 13) THEN 'th'
            WHEN mod(day_of_month(cohort_observations.cohort_week), 10) = 1 THEN 'st'
            WHEN mod(day_of_month(cohort_observations.cohort_week), 10) = 2 THEN 'nd'
            WHEN mod(day_of_month(cohort_observations.cohort_week), 10) = 3 THEN 'rd'
            ELSE 'th'
        END,
        ' ',
        date_format(cohort_observations.cohort_week, '%b')
    ) AS cohort_label,
    cohort_observations.observation_week,
    date_diff('week', cohort_observations.cohort_week, cohort_observations.observation_week) AS weeks_since_cohort,
    cohort_sizes.cohort_users,
    COUNT_IF(cohort_observations.current_balance_usd >= params.min_balance_usd) AS retained_users,
    COUNT_IF(cohort_observations.current_balance_usd >= params.min_balance_usd) * 1.0 / cohort_sizes.cohort_users AS retained_user_share,
    COUNT_IF(cohort_observations.current_balance_usd >= params.min_balance_usd) * 100.0 / cohort_sizes.cohort_users AS retained_user_pct
FROM cohort_observations
INNER JOIN cohort_sizes
    ON cohort_observations.cohort_week = cohort_sizes.cohort_week
CROSS JOIN params
GROUP BY
    cohort_observations.cohort_week,
    cohort_observations.observation_week,
    date_diff('week', cohort_observations.cohort_week, cohort_observations.observation_week),
    cohort_sizes.cohort_users
ORDER BY
    cohort_observations.cohort_week,
    cohort_observations.observation_week
