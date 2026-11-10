
-- =========================================
-- SILVER: Cleaned Products
-- =========================================

CREATE OR REPLACE TABLE retail_analytics.silver.products
USING DELTA
AS
SELECT
    PRODUCT_ID AS product_id,
    MANUFACTURER AS manufacturer,

    NULLIF(TRIM(DEPARTMENT), '') AS department,
    NULLIF(TRIM(BRAND), '') AS brand,
    NULLIF(TRIM(COMMODITY_DESC), '') AS commodity_desc,
    NULLIF(TRIM(SUB_COMMODITY_DESC), '') AS sub_commodity_desc,
    NULLIF(TRIM(CURR_SIZE_OF_PRODUCT), '') AS product_size,

    _source_file,
    _ingested_at

FROM retail_analytics.bronze.products;


-- =========================================
-- SILVER: Cleaned Transactions
-- =========================================

CREATE OR REPLACE TABLE retail_analytics.silver.transactions
USING DELTA
AS
SELECT
    household_key,
    BASKET_ID AS basket_id,
    PRODUCT_ID AS product_id,
    STORE_ID AS store_id,

    DAY AS transaction_day,
    WEEK_NO AS week_no,
    TRANS_TIME AS transaction_time,

    QUANTITY AS quantity,

    TRY_CAST(SALES_VALUE AS DECIMAL(18,2))
        AS sales_value,

    TRY_CAST(RETAIL_DISC AS DECIMAL(18,2))
        AS retail_discount,

    TRY_CAST(COUPON_DISC AS DECIMAL(18,2))
        AS coupon_discount,

    TRY_CAST(COUPON_MATCH_DISC AS DECIMAL(18,2))
        AS coupon_match_discount,

    _source_file,
    _ingested_at

FROM retail_analytics.bronze.transactions;
