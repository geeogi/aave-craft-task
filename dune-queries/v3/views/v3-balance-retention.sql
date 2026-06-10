-- Weekly balance-based user retention curve for selected Aave V3 Ethereum assets.
-- Cohort entry is the first week a user has balance >= 100 USD.
-- Retention is whether the user also has balance >= 100 USD in later observation weeks.
-- https://dune.com/queries/7679077

WITH params AS (
    SELECT
        100 AS min_balance_usd,
        TIMESTAMP '2026-03-30' AS min_cohort_week
),
weekly_user_balances AS (
    SELECT
        week,
        user,
        SUM(current_balance_usd) AS current_balance_usd
    FROM dune.geeogi_team.result_aave_v3_ethereum_user_balances_weekly
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
observation_weeks AS (
    SELECT DISTINCT
        week
    FROM weekly_user_balances
),
cohort_week_spine AS (
    SELECT
        analysis_cohorts.cohort_week,
        analysis_cohorts.user,
        observation_weeks.week AS observation_week
    FROM analysis_cohorts
    INNER JOIN observation_weeks
        ON observation_weeks.week >= analysis_cohorts.cohort_week
),
cohort_balances_by_week AS (
    SELECT
        cohort_week_spine.cohort_week,
        cohort_week_spine.observation_week,
        cohort_week_spine.user,
        weekly_user_balances.current_balance_usd
    FROM cohort_week_spine
    LEFT JOIN weekly_user_balances
        ON cohort_week_spine.user = weekly_user_balances.user
       AND cohort_week_spine.observation_week = weekly_user_balances.week
),
retention_by_week AS (
    SELECT
        cohort_balances_by_week.cohort_week,
        cohort_balances_by_week.observation_week,
        date_diff('week', cohort_balances_by_week.cohort_week, cohort_balances_by_week.observation_week) AS weeks_since_cohort,
        cohort_sizes.cohort_users,
        COUNT_IF(cohort_balances_by_week.current_balance_usd >= params.min_balance_usd) AS retained_users
    FROM cohort_balances_by_week
    INNER JOIN cohort_sizes
        ON cohort_balances_by_week.cohort_week = cohort_sizes.cohort_week
    CROSS JOIN params
    GROUP BY
        cohort_balances_by_week.cohort_week,
        cohort_balances_by_week.observation_week,
        date_diff('week', cohort_balances_by_week.cohort_week, cohort_balances_by_week.observation_week),
        cohort_sizes.cohort_users
)

SELECT
    retention_by_week.cohort_week,
    CAST(retention_by_week.cohort_week AS date) AS cohort_date,
    CONCAT(
        CAST(day_of_month(retention_by_week.cohort_week) AS varchar),
        CASE
            WHEN day_of_month(retention_by_week.cohort_week) IN (11, 12, 13) THEN 'th'
            WHEN mod(day_of_month(retention_by_week.cohort_week), 10) = 1 THEN 'st'
            WHEN mod(day_of_month(retention_by_week.cohort_week), 10) = 2 THEN 'nd'
            WHEN mod(day_of_month(retention_by_week.cohort_week), 10) = 3 THEN 'rd'
            ELSE 'th'
        END,
        ' ',
        date_format(retention_by_week.cohort_week, '%b')
    ) AS cohort_label,
    retention_by_week.observation_week,
    retention_by_week.weeks_since_cohort,
    retention_by_week.cohort_users,
    retention_by_week.retained_users,
    retention_by_week.retained_users * 1.0 / retention_by_week.cohort_users AS retained_user_share,
    retention_by_week.retained_users * 100.0 / retention_by_week.cohort_users AS retained_user_pct
FROM retention_by_week
ORDER BY
    retention_by_week.cohort_week,
    retention_by_week.observation_week
