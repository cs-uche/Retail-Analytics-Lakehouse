-- ==========================================
-- Bronze Layer: Data Validation
-- Source: dunnhumby The Complete Journey
-- ==========================================

-- Transacion Data Ingestion
SELECT
    COUNT(*) AS total_rows,

    COUNT_IF(_rescued_data IS NOT NULL)
        AS rescued_rows,

    COUNT_IF(BASKET_ID IS NULL)
        AS null_basket_ids,

    COUNT_IF(PRODUCT_ID IS NULL)
        AS null_product_ids,

    COUNT_IF(household_key IS NULL)
        AS null_households,

    COUNT_IF(QUANTITY < 0)
        AS negative_quantities,

    COUNT_IF(SALES_VALUE < 0)
        AS negative_sales,

    COUNT(DISTINCT BASKET_ID)
        AS distinct_baskets,

    SUM(SALES_VALUE)
        AS total_retailer_revenue

FROM retail_analytics.bronze.transactions;


-- Products Data Ingestion
SELECT
    PRODUCT_ID,
    COUNT(*) AS occurrences
FROM retail_analytics.bronze.products
GROUP BY PRODUCT_ID
HAVING COUNT(*) > 1;