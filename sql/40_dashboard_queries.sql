
-- ==========================================
-- VISUALIZATION
-- ==========================================
-- Department Revenue

WITH department_totals AS (
    SELECT
        department
        ,SUM(total_revenue) AS revenue
        ,RANK() OVER(ORDER BY SUM(total_revenue) DESC) ranking
    FROM retail_analytics.gold.weekly_department_sales
    GROUP BY department
)

SELECT
    department
    ,revenue
    ,ROUND(
        100.0 * revenue / SUM(revenue) OVER (),2
    ) AS revenue_share_pct
    , ranking
FROM department_totals
WHERE department <> 'UNMAPPED'
ORDER BY revenue DESC
LIMIT 10;

-- Weekly Revenue

WITH top_departments AS (
    SELECT department
    FROM retail_analytics.gold.weekly_department_sales
    WHERE department <> 'UNMAPPED'
    GROUP BY department
    ORDER BY SUM(total_revenue) DESC
    LIMIT 5
)
SELECT
    g.week_no,
    g.department,
    g.total_revenue
FROM retail_analytics.gold.weekly_department_sales g
JOIN top_departments t
    ON g.department = t.department
ORDER BY g.week_no, g.department;

-- DSITINCT BASKETS
SELECT
    COUNT(DISTINCT basket_id) AS unique_baskets
FROM retail_analytics.silver.transactions;

-- DEPARTMENT PERFORMANCE

WITH department_metrics AS (
    SELECT
        COALESCE(p.department, 'UNMAPPED') AS department,
        SUM(t.sales_value) AS revenue,
        COUNT(DISTINCT t.basket_id) AS unique_baskets,
        COUNT(*) AS receipt_lines
    FROM retail_analytics.silver.transactions t
    LEFT JOIN retail_analytics.silver.products p
        ON t.product_id = p.product_id
    GROUP BY COALESCE(p.department, 'UNMAPPED')
)

SELECT
    department,
    revenue,

    ROUND(
        100.0 * revenue / NULLIF(SUM(revenue) OVER (), 0),
        2
    ) AS revenue_share_pct,

    unique_baskets,
    receipt_lines,

    ROUND(
        revenue / NULLIF(unique_baskets, 0),
        2
    ) AS revenue_per_basket

FROM department_metrics
ORDER BY revenue DESC;
