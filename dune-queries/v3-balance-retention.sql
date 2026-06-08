-- Weekly balance-based user retention curve for selected Aave V3 Ethereum assets.
-- Cohort entry is the first week a user has balance >= 100 USD.
-- Retention is whether the user also has balance >= 100 USD in each later observation week.
-- Limited to the most recent 12 cohort weeks.

WITH weekly_balances AS (
    SELECT
        week,
        user,
        SUM(current_balance_usd) AS current_balance_usd
    FROM query_7678703
    GROUP BY
        week,
        user
),
cohort_source AS (
    SELECT
        week,
        user
    FROM weekly_balances
    WHERE current_balance_usd >= 100
),
user_cohorts AS (
    SELECT
        user,
        MIN(week) AS cohort_week
    FROM cohort_source
    GROUP BY user
),
latest_cohort_week AS (
    SELECT
        MAX(cohort_week) AS cohort_week
    FROM user_cohorts
),
selected_cohorts AS (
    SELECT
        user_cohorts.user,
        user_cohorts.cohort_week
    FROM user_cohorts
    INNER JOIN latest_cohort_week
        ON user_cohorts.cohort_week >= date_add('week', -11, latest_cohort_week.cohort_week)
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
    cohort_observations.observation_week,
    date_diff('week', cohort_observations.cohort_week, cohort_observations.observation_week) AS weeks_since_cohort,
    cohort_sizes.cohort_users,
    COUNT_IF(cohort_observations.current_balance_usd >= 100) AS retained_users,
    COUNT_IF(cohort_observations.current_balance_usd >= 100) * 1.0 / cohort_sizes.cohort_users AS retained_user_share
FROM cohort_observations
INNER JOIN cohort_sizes
    ON cohort_observations.cohort_week = cohort_sizes.cohort_week
GROUP BY
    cohort_observations.cohort_week,
    cohort_observations.observation_week,
    date_diff('week', cohort_observations.cohort_week, cohort_observations.observation_week),
    cohort_sizes.cohort_users
ORDER BY
    cohort_observations.cohort_week,
    cohort_observations.observation_week
