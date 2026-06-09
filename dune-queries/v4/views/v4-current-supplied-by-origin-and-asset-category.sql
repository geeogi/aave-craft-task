-- Current V4 supplied balance split by user origin and asset category.
-- Intended for a two-bar stacked chart: Prior V3 user vs No V3 history.

WITH v3_historical_users AS (
    SELECT DISTINCT
        user
    FROM dune.geeogi.result_aave_v3_ethereum_user_balances_weekly
),
v4_current_balances AS (
    SELECT
        user,
        symbol,
        current_position_usd
    FROM query_7676585
),
asset_categories AS (
    SELECT
        symbol,
        asset_category,
        category_order
    FROM query_7684965
),
origin_definitions AS (
    SELECT 1 AS origin_order, 'Prior V3 user' AS user_origin
    UNION ALL
    SELECT 2 AS origin_order, 'No V3 history' AS user_origin
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
        CASE
            WHEN v3_historical_users.user IS NOT NULL THEN 'Prior V3 user'
            ELSE 'No V3 history'
        END AS user_origin,
        COALESCE(asset_categories.asset_category, 'Other') AS asset_category,
        COALESCE(asset_categories.category_order, (SELECT MAX(category_order) + 1 FROM asset_categories)) AS category_order,
        v4_current_balances.user,
        v4_current_balances.current_position_usd
    FROM v4_current_balances
    LEFT JOIN v3_historical_users
        ON v4_current_balances.user = v3_historical_users.user
    LEFT JOIN asset_categories
        ON v4_current_balances.symbol = asset_categories.symbol
),
origin_category_aggregates AS (
    SELECT
        user_origin,
        asset_category,
        category_order,
        COUNT(DISTINCT user) AS users,
        SUM(current_position_usd) AS total_position_usd
    FROM classified_balances
    GROUP BY
        user_origin,
        asset_category,
        category_order
)

SELECT
    origin_definitions.user_origin,
    origin_definitions.origin_order,
    category_definitions.asset_category,
    category_definitions.category_order,
    COALESCE(origin_category_aggregates.users, 0) AS users,
    COALESCE(origin_category_aggregates.total_position_usd, 0) AS total_position_usd
FROM origin_definitions
CROSS JOIN category_definitions
LEFT JOIN origin_category_aggregates
    ON origin_definitions.user_origin = origin_category_aggregates.user_origin
   AND category_definitions.asset_category = origin_category_aggregates.asset_category
ORDER BY
    origin_definitions.origin_order,
    category_definitions.category_order
