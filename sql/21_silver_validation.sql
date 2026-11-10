-- =========================================
-- Check 1 — Row-count and revenue reconciliation
-- =========================================

-- Transaction Table
-- Raw versus Silver row count
SELECT
    (SELECT COUNT(*)
     FROM retail_analytics.bronze.transactions)
        AS bronze_rows

    ,(SELECT COUNT(*)
     FROM retail_analytics.silver.transactions)
        AS silver_rows
    
    , silver_rows - bronze_rows rows_diff
;


-- Revenue reconciliation after decimal conversion
SELECT
    SUM(TRY_CAST(SALES_VALUE AS DECIMAL(18,2)))
        AS bronze_revenue

    ,(SELECT SUM(sales_value)
     FROM retail_analytics.silver.transactions)
        AS silver_revenue
    
    , silver_revenue - bronze_revenue revenue_diff

FROM retail_analytics.bronze.transactions;


-- =========================================
-- Check 2 — Detect any invalid transformations
-- =========================================

SELECT
    COUNT_IF(sales_value IS NULL)
        AS invalid_sales_values,

    COUNT_IF(retail_discount IS NULL)
        AS invalid_retail_discounts,

    COUNT_IF(coupon_discount IS NULL)
        AS invalid_coupon_discounts,

    COUNT_IF(coupon_match_discount IS NULL)
        AS invalid_match_discounts,

    COUNT_IF(product_id IS NULL)
        AS invalid_product_ids,

    COUNT_IF(basket_id IS NULL)
        AS invalid_basket_ids

FROM retail_analytics.silver.transactions;


-- =========================================
-- Check 3 — Referential integrity
-- =========================================

SELECT
    COUNT(*) AS unmatched_transaction_lines,
    COUNT(DISTINCT t.product_id) AS unmatched_products
FROM retail_analytics.silver.transactions t
LEFT ANTI JOIN retail_analytics.silver.products p
    ON t.product_id = p.product_id;
