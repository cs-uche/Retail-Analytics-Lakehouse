
-- ==========================================
-- Bronze Layer: Transaction Ingestion
-- Source: dunnhumby The Complete Journey
-- ==========================================

-- Transacion Data Ingestion
-- Preview the source file before ingestion
SELECT *
FROM read_files(
    '/Volumes/retail_analytics/landing/raw/transaction_data.csv'
    ,format => 'csv'
    ,header => true
)
LIMIT 10;

-- Create a Delta table preserving the raw columns
CREATE OR REPLACE TABLE retail_analytics.bronze.transactions
USING DELTA
AS
SELECT
    *
    ,_metadata.file_path AS _source_file
    ,current_timestamp() AS _ingested_at
FROM read_files(
    '/Volumes/retail_analytics/landing/raw/transaction_data.csv'
    ,format => 'csv'
    ,header => true
);

-- Validate the Bronze table
SELECT 
    *
FROM retail_analytics.bronze.transactions
LIMIT 10;

-- Confirm the row count in the bronze table and raw data files
SELECT 
    COUNT(*) AS total_rows
FROM retail_analytics.bronze.transactions;

SELECT
    COUNT(*) AS total_rows
FROM read_files(
    '/Volumes/retail_analytics/landing/raw/transaction_data.csv'
    ,format => 'csv'
    ,header => true
);

-- Inspect the resulting schema
DESCRIBE TABLE retail_analytics.bronze.transactions;


-- Products Data Ingestion
-- Preview the source file before ingestion
SELECT *
FROM read_files(
    '/Volumes/retail_analytics/landing/raw/product.csv'
    ,format => 'csv'
    ,header => true
)
LIMIT 10;

-- Create a Delta table preserving the raw columns
CREATE OR REPLACE TABLE retail_analytics.bronze.products
USING DELTA
AS
SELECT
    *
    ,_metadata.file_path AS _source_file
    ,current_timestamp() AS _ingested_at
FROM read_files(
    '/Volumes/retail_analytics/landing/raw/product.csv'
    ,format => 'csv'
    ,header => true
);

-- Validate the Bronze table
SELECT 
    *
FROM retail_analytics.bronze.products
LIMIT 10;

-- Confirm the row count in the bronze table and raw data files
SELECT 
    COUNT(*) AS total_rows
FROM retail_analytics.bronze.products;

SELECT
    COUNT(*) AS total_rows
FROM read_files(
    '/Volumes/retail_analytics/landing/raw/product.csv'
    ,format => 'csv'
    ,header => true
);

-- Inspect the resulting schema
DESCRIBE TABLE retail_analytics.bronze.products;
