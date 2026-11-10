
-- ==========================================
-- GOLD: Weekly Department Sales
-- Grain: week_no + department
-- ==========================================

CREATE OR REPLACE TABLE
    retail_analytics.gold.weekly_department_sales
USING DELTA
AS
SELECT
    t.week_no,

    COALESCE(
        p.department, 'UNMAPPED'
    ) AS department,

    COUNT(*) AS transaction_lines,

    COUNT(DISTINCT t.basket_id)
        AS distinct_baskets,

    SUM(t.quantity) AS total_units,

    SUM(t.sales_value) AS total_revenue

FROM retail_analytics.silver.transactions t

LEFT JOIN retail_analytics.silver.products p
    ON t.product_id = p.product_id

GROUP BY
    t.week_no,
    COALESCE(p.department, 'UNMAPPED');
