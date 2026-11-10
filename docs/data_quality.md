# Data Quality Report

**Project:** Grocery Retail & Loyalty Lakehouse  
**Source:** dunnhumby — The Complete Journey (original CSV release)  
**Pipeline stage:** Initial batch ingestion and Bronze-to-Silver transformation  
**Validation status:** All executed checks reported below passed. Incremental processing and automated quality gates are not yet implemented.

## 1. Scope and Data Contracts

This report covers the initial processing of `transaction_data.csv` and `product.csv` into Delta tables in the `retail_analytics` catalog.

- **Transaction grain:** Each row represents a receipt line. `basket_id` identifies a purchase occasion, not an individual receipt line.
- **Product grain:** `product_id` is the natural key of the product master.
- **Revenue definition:** `sales_value` represents retailer receipts, not necessarily the customer's out-of-pocket expenditure.
- **Monetary precision:** Bronze retains source-inferred `DOUBLE` values; Silver converts monetary fields to `DECIMAL(18,2)`.
- **Demographic coverage:** Household demographic records are available only for a subset of households.

## 2. Bronze Layer — Source Integrity

### 2.1 Transaction Table

**Table:** `retail_analytics.bronze.transactions`

| Metric | Result |
|---|---:|
| Total transaction rows | 2,595,732 |
| Distinct baskets | 276,484 |
| Null basket identifiers | 0 |
| Null product identifiers | 0 |
| Null household identifiers | 0 |
| Negative quantities | 0 |
| Negative sales values | 0 |
| Rows containing rescued data | 0 |
| Revenue using Bronze `DOUBLE` | 8,057,463.079999879 |

**Findings**

The initial source-to-Bronze transaction counts reconciled, and all executed structural checks passed.

The `_rescued_data` column contained no non-null values. It remains in Bronze to preserve the ability to investigate schema changes or incompatible records during future ingestion.

The monetary sum exhibits floating-point representation effects because `SALES_VALUE` was inferred as `DOUBLE`.

### 2.2 Product Table

**Table:** `retail_analytics.bronze.products`

| Check | Result |
|---|---|
| Duplicate `PRODUCT_ID` values | 0 duplicate IDs |

The ingested product records satisfy the expected natural-key uniqueness constraint.

Product attribute completeness and descriptive-field quality require additional profiling.

## 3. Silver Layer — Transformation Integrity

**Tables:** `retail_analytics.silver.transactions` and `retail_analytics.silver.products`

### 3.1 Transaction Row Reconciliation

| Bronze rows | Silver rows | Difference |
|---:|---:|---:|
| 2,595,732 | 2,595,732 | 0 |

**Result: PASS**

All transaction rows were preserved during the initial Bronze-to-Silver batch transformation.

### 3.2 Revenue Reconciliation

| Bronze revenue after decimal conversion | Silver revenue | Difference |
|---:|---:|---:|
| $8,057,463.08 | $8,057,463.08 | $0.00 |

**Result: PASS**

Aggregate retailer revenue reconciles to the cent after consistent decimal conversion. Row-level monetary comparisons remain a potential additional check.

### 3.3 Transformation Null Checks

| Validation check | Invalid records |
|---|---:|
| Null sales values | 0 |
| Null retail discounts | 0 |
| Null coupon discounts | 0 |
| Null coupon-match discounts | 0 |
| Null product identifiers | 0 |
| Null basket identifiers | 0 |

**Result: PASS**

No nulls were found in the six tested Silver fields. This confirms the executed checks, but does not establish that every possible domain constraint has been tested.

### 3.4 Referential Integrity

The transaction table was checked against the product master using a left-anti join.

| Metric | Result |
|---|---:|
| Unmatched transaction lines | 0 |
| Distinct unmatched product IDs | 0 |

**Result: PASS**

Every transaction references a product present in the current Silver product table.

Historical product relationships will need further validation when SCD Type 2 is implemented.

## 4. Findings and Known Limitations

**Validated findings**

- Raw and Bronze transaction row counts reconcile.
- Product identifiers are unique in the Bronze product table.
- Bronze and Silver transaction row counts match.
- Aggregate revenue reconciles exactly after consistent decimal conversion.
- All six tested Silver key and monetary fields contain no nulls.
- Every transaction references an existing Silver product.

**Remaining limitations**

- No stable receipt-line identifier has been established for incremental processing.
- Product descriptive attributes and Silver product-key uniqueness require additional validation.
- Household demographic coverage has not been validated.
- Incremental ingestion, CDC, SCD Type 2 and replay safety have not been implemented.
- Quality checks are currently executed manually rather than enforced as automated pipeline gates.
- Quarantine handling, monitoring and alerting are not yet implemented.

## 5. Next Validation Targets

1. **Silver products:** Confirm unique and non-null product IDs; profile missing departments, brands and commodity descriptions.
2. **Transaction grain:** Investigate repeated basket/product combinations before designing a stable, replay-safe receipt-line identifier.
3. **Gold reconciliation:** Build `gold.weekly_department_sales` and reconcile aggregated revenue to Silver.
4. **Automated validation:** Introduce tests that fail a Databricks job when critical data-quality invariants are violated.

## 6. Reproducibility

Executable checks should remain in version-controlled SQL scripts:

- `sql/11_bronze_validation.sql`
- `sql/21_silver_validation.sql`

This document captures the observed outcomes, interpretations and limitations of those checks. It is not a replacement for executable validation.

**Overall conclusion:** The initial Bronze and Silver transaction-processing stages passed the executed structural, transformation and referential-integrity checks. The dataset is ready for initial Gold modelling, subject to ongoing validation as the pipeline evolves.