-- Current V3 supplied balance for users with V3 balance > $100 on the V4 start week
-- who never used V4, split by asset category.

WITH params AS (
    SELECT
        TIMESTAMP '2026-03-30' AS v4_start_week,
        100 AS min_start_balance_usd
),
v3_start_balances AS (
    SELECT
        user,
        SUM(current_balance_usd) AS v3_start_balance_usd
    FROM dune.geeogi.result_aave_v3_ethereum_user_balances_weekly
    CROSS JOIN params
    WHERE week = params.v4_start_week
    GROUP BY user
    HAVING SUM(current_balance_usd) > MAX(params.min_start_balance_usd)
),
v4_historical_users AS (
    SELECT DISTINCT
        user
    FROM query_7682230
),
v3_current_balances AS (
    SELECT
        user,
        asset AS symbol,
        current_balance_usd
    FROM query_7677461
),
asset_categories AS (
    SELECT
        symbol,
        asset_category,
        category_order
    FROM query_7684965
),
category_definitions AS (
    SELECT DISTINCT
        category_order,
        asset_category
    FROM asset_categories
    UNION ALL
    SELECT MAX(category_order) + 1 AS category_order, 'Other' AS asset_category
    FROM asset_categories
),
classified_balances AS (
    SELECT
        COALESCE(asset_categories.asset_category, 'Other') AS asset_category,
        COALESCE(asset_categories.category_order, (SELECT MAX(category_order) + 1 FROM asset_categories)) AS category_order,
        v3_current_balances.user,
        v3_current_balances.current_balance_usd
    FROM v3_start_balances
    INNER JOIN v3_current_balances
        ON v3_start_balances.user = v3_current_balances.user
    LEFT JOIN v4_historical_users
        ON v3_start_balances.user = v4_historical_users.user
    LEFT JOIN asset_categories
        ON v3_current_balances.symbol = asset_categories.symbol
    WHERE v4_historical_users.user IS NULL
),
category_aggregates AS (
    SELECT
        asset_category,
        category_order,
        SUM(current_balance_usd) AS total_position_usd
    FROM classified_balances
    GROUP BY
        asset_category,
        category_order
)

SELECT
    'V3 non-migrators' AS user_group,
    1 AS group_order,
    category_definitions.asset_category,
    category_definitions.category_order,
    COALESCE(category_aggregates.total_position_usd, 0) AS total_position_usd
FROM category_definitions
LEFT JOIN category_aggregates
    ON category_definitions.asset_category = category_aggregates.asset_category
ORDER BY
    category_definitions.category_order
