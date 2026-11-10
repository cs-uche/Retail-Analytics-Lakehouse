
-- Reconcile transaction lines and revenue
WITH silver_totals AS (
    SELECT
        COUNT(*) AS transaction_lines,
        SUM(sales_value) AS revenue
    FROM retail_analytics.silver.transactions
),

gold_totals AS (
    SELECT
        SUM(transaction_lines) AS transaction_lines,
        SUM(total_revenue) AS revenue
    FROM retail_analytics.gold.weekly_department_sales
)

SELECT
    s.transaction_lines AS silver_lines,
    g.transaction_lines AS gold_lines,

    s.transaction_lines - g.transaction_lines
        AS row_difference,

    s.revenue AS silver_revenue,
    g.revenue AS gold_revenue,

    s.revenue - g.revenue
        AS revenue_difference

FROM silver_totals s
CROSS JOIN gold_totals g;
