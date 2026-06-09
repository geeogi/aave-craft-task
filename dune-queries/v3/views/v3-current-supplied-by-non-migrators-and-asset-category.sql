-- Current V3 supplied balance for users with no V4 history, split by asset category.
-- Intended for a single stacked bar chart of non-migrator supply composition.

WITH v4_historical_users AS (
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
),
classified_balances AS (
    SELECT
        COALESCE(asset_categories.asset_category, 'Other') AS asset_category,
        COALESCE(
            asset_categories.category_order,
            (
                SELECT category_definitions.category_order
                FROM category_definitions
                WHERE category_definitions.asset_category = 'Other'
            )
        ) AS category_order,
        v3_current_balances.user,
        v3_current_balances.current_balance_usd
    FROM v3_current_balances
    LEFT JOIN v4_historical_users
        ON v3_current_balances.user = v4_historical_users.user
    LEFT JOIN asset_categories
        ON v3_current_balances.symbol = asset_categories.symbol
    WHERE v4_historical_users.user IS NULL
),
category_aggregates AS (
    SELECT
        asset_category,
        category_order,
        COUNT(DISTINCT user) AS users,
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
    COALESCE(category_aggregates.users, 0) AS users,
    COALESCE(category_aggregates.total_position_usd, 0) AS total_position_usd
FROM category_definitions
LEFT JOIN category_aggregates
    ON category_definitions.asset_category = category_aggregates.asset_category
ORDER BY
    category_definitions.category_order
