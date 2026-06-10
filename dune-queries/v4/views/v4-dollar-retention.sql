-- Weekly constant-price dollar retention for Aave V4 Ethereum.
-- Cohort entry is the first week a user has total balance >= 100 USD.
-- Later balances are valued using each cohort asset's cohort-week price.
-- Gross retention allows asset balances to grow above cohort units.
-- Capped retention limits each asset to its cohort-week units.
-- https://dune.com/queries/7682899
-- https://dune.com/queries/7682899/11639581

WITH params AS (
    SELECT
        100 AS min_balance_usd,
        TIMESTAMP '2026-03-30' AS min_cohort_week
),
weekly_positions AS (
    SELECT
        week,
        user,
        spoke,
        reserveId,
        address,
        current_supplied_amount,
        asset_price_usd,
        current_position_usd
    FROM dune.geeogi_team.result_aave_v4_ethereum_user_balances_weekly
),
weekly_user_balances AS (
    SELECT
        week,
        user,
        SUM(current_position_usd) AS current_balance_usd
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
-- Freeze each cohort's starting asset amounts and prices at entry week.
cohort_entry_positions AS (
    SELECT
        analysis_cohorts.cohort_week,
        analysis_cohorts.user,
        weekly_positions.spoke,
        weekly_positions.reserveId,
        weekly_positions.address,
        weekly_positions.current_supplied_amount AS cohort_amount,
        weekly_positions.asset_price_usd AS cohort_price_usd,
        weekly_positions.current_position_usd AS cohort_position_usd
    FROM analysis_cohorts
    INNER JOIN weekly_positions
        ON analysis_cohorts.user = weekly_positions.user
       AND analysis_cohorts.cohort_week = weekly_positions.week
),
cohort_start_values AS (
    SELECT
        cohort_week,
        SUM(cohort_position_usd) AS cohort_start_balance_usd
    FROM cohort_entry_positions
    GROUP BY cohort_week
),
observation_weeks AS (
    SELECT DISTINCT
        week
    FROM weekly_positions
),
-- Follow only the cohort-entry positions through later weeks at frozen entry prices.
cohort_position_values_by_week AS (
    SELECT
        cohort_entry_positions.cohort_week,
        observation_weeks.week AS observation_week,
        cohort_entry_positions.user,
        cohort_entry_positions.spoke,
        cohort_entry_positions.reserveId,
        cohort_entry_positions.address,
        cohort_entry_positions.cohort_amount,
        cohort_entry_positions.cohort_price_usd,
        COALESCE(weekly_positions.current_supplied_amount, 0) AS observation_amount
    FROM cohort_entry_positions
    INNER JOIN observation_weeks
        ON observation_weeks.week >= cohort_entry_positions.cohort_week
    LEFT JOIN weekly_positions
        ON cohort_entry_positions.user = weekly_positions.user
       AND cohort_entry_positions.spoke = weekly_positions.spoke
       AND cohort_entry_positions.reserveId = weekly_positions.reserveId
       AND cohort_entry_positions.address = weekly_positions.address
       AND observation_weeks.week = weekly_positions.week
),
retention_values_by_week AS (
    SELECT
        cohort_week,
        observation_week,
        SUM(observation_amount * cohort_price_usd) AS gross_retained_balance_usd,
        SUM(LEAST(observation_amount, cohort_amount) * cohort_price_usd) AS capped_retained_balance_usd
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
    retention_values_by_week.gross_retained_balance_usd,
    retention_values_by_week.gross_retained_balance_usd * 100.0 / cohort_start_values.cohort_start_balance_usd AS gross_retained_balance_pct,
    retention_values_by_week.capped_retained_balance_usd,
    retention_values_by_week.capped_retained_balance_usd * 100.0 / cohort_start_values.cohort_start_balance_usd AS capped_retained_balance_pct
FROM retention_values_by_week
INNER JOIN cohort_sizes
    ON retention_values_by_week.cohort_week = cohort_sizes.cohort_week
INNER JOIN cohort_start_values
    ON retention_values_by_week.cohort_week = cohort_start_values.cohort_week
ORDER BY
    retention_values_by_week.cohort_week,
    retention_values_by_week.observation_week
