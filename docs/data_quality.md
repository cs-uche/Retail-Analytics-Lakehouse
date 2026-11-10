# Data Quality and Reconciliation Report

**Project:** Grocery Retail Analytics Lakehouse  
**Source:** dunnhumby — The Complete Journey, original CSV release  
**Scope:** Initial batch Bronze → Silver → Gold processing of transactions and products  
**Result:** All **executed** structural and reconciliation checks reported below passed. Automated failure gates are not yet implemented.

## 1. Data contracts and interpretation

| Concept | Contract / interpretation |
|---|---|
| Receipt-line grain | Each transaction row is a purchased product line, not an entire shopping trip |
| Basket identity | `basket_id` identifies a purchase occasion; it may span multiple products and departments |
| Product identity | `product_id` identifies a product in the product master |
| Retailer revenue | `sales_value` measures revenue received by the retailer, which may differ from the consumer's net payment when manufacturer coupons are used |
| Time | `day` and `week_no` are relative source periods, not calendar dates |
| Currency | The guide uses dollar amounts but does not establish CAD; use **source currency** in public outputs |
| Monetary precision | Bronze uses inferred `DOUBLE` amounts; Silver casts amounts to `DECIMAL(18,2)` |

These results are an **initial batch snapshot**, not evidence that arbitrary future files or changes will automatically pass validation.

## 2. Bronze — source integrity

### 2.1 Transactions: `retail_analytics.bronze.transactions`

| Executed check / metric | Observed result | Outcome |
|---|---:|---|
| Transaction receipt lines | 2,595,732 | Reconciled with raw file |
| Distinct baskets | 276,484 | Informational |
| Null `basket_id` | 0 | Pass |
| Null `product_id` | 0 | Pass |
| Null `household_key` | 0 | Pass |
| Negative `quantity` | 0 | Pass for executed test |
| Negative `sales_value` | 0 | Pass for executed test |
| Rows with non-null `_rescued_data` | 0 | Pass |
| Retailer revenue with raw `DOUBLE` | 8,057,463.079999879 | Floating-point representation noted |

The Bronze table retains raw source columns plus `_source_file`, `_ingested_at`, and an automatically provided `_rescued_data` field. `_rescued_data` was null for all rows in this initial batch and remains in Bronze for future schema diagnostics.

### 2.2 Products: `retail_analytics.bronze.products`

| Executed check | Observed result | Outcome |
|---|---:|---|
| Duplicate `PRODUCT_ID` values | 0 | Pass |

A zero-row duplicate-ID query supports product natural-key uniqueness for the ingested batch. Missing department values and other product description completeness metrics have not yet been fully profiled.

## 3. Silver — transformation integrity

**Tables:** `retail_analytics.silver.transactions` and `retail_analytics.silver.products`.

### 3.1 Count reconciliation

| Bronze lines | Silver lines | Difference | Outcome |
|---:|---:|---:|---|
| 2,595,732 | 2,595,732 | 0 | **Pass** |

No transaction rows were lost or added in the initial batch transformation.

### 3.2 Revenue reconciliation

Both layers were compared using the same `DECIMAL(18,2)` conversion basis.

| Bronze decimal revenue | Silver decimal revenue | Difference | Outcome |
|---:|---:|---:|---|
| 8,057,463.08 | 8,057,463.08 | 0.00 | **Pass** |

This proves the **aggregate** totals agree; it does not yet establish that every individual row has identical monetary values after transformations.

### 3.3 Required value checks

| Checked Silver field | Invalid/null records |
|---|---:|
| `sales_value` | 0 |
| `retail_discount` | 0 |
| `coupon_discount` | 0 |
| `coupon_match_discount` | 0 |
| `product_id` | 0 |
| `basket_id` | 0 |

All six executed checks passed. This does not imply every Silver column or every domain constraint has been validated.

### 3.4 Product referential integrity

A left-anti join identified transactions without matching products:

| Unmatched receipt lines | Distinct unmatched product IDs | Outcome |
|---:|---:|---|
| 0 | 0 | **Pass** |

Every transaction references a product in the current Silver product master. This **does not** prove the product has a non-null department or that future SCD Type 2 time-valid joins will succeed.

## 4. Gold — analytics integrity

**Table:** `retail_analytics.gold.weekly_department_sales`  
**Grain:** `(week_no, department)`; measures include transaction lines, distinct baskets *within each week/department*, reported quantity, and retailer revenue.

### 4.1 Silver ↔ Gold reconciliation

| Metric | Silver | Gold (aggregated) | Difference | Outcome |
|---|---:|---:|---:|---|
| Receipt lines | 2,595,732 | 2,595,732 | 0 | **Pass** |
| Retailer revenue | 8,057,463.08 | 8,057,463.08 | 0.00 | **Pass** |

This check supports completeness of the initial Gold aggregation and confirms that aggregate receipt-line counts and retailer revenue were preserved through Gold modelling. Combined with the product-key uniqueness checks, these results support the correctness of the initial product join.

### 4.2 Dashboard-level observed results

| Metric | Value | Notes |
|---|---:|---|
| Overall unique baskets | 276,484 | `COUNT(DISTINCT basket_id)` from transactions |
| Grocery retailer revenue | 4,093,814.14 | ~50.8% of total revenue |
| Drug GM retailer revenue | 1,055,358.03 | ~13.1% of total revenue |
| Top-two share | ~63.9% | Grocery + Drug GM |

**Do not sum per-department `distinct_baskets` across departments** to compute overall unique purchase occasions: a single basket can contain products from several departments. For a department-level detail table, baskets are distinct within each department, which is a different measure from the overall total.

## 5. Key Findings and Interpretation

**1. Source integrity and completeness**  
The initial batch successfully ingested 2,595,732 transaction records into Bronze without row-count discrepancies. The validation checks identified no null transaction business keys, negative quantities, negative sales values or rescued records.

Bronze preserves source records and ingestion metadata for traceability. No business-level deduplication or filtering was applied during the initial load.

**2. Product master integrity**  
All product identifiers in the Bronze product table were unique. In addition, every transaction's product_id matched a product in the Silver product master.

These results support the reliability of product-based analytical joins, although product descriptions and department completeness require further validation.

**3. Transformation accuracy**  
The Bronze-to-Silver transformation preserved all 2,595,732 transaction records.

Converting monetary fields from DOUBLE to DECIMAL(18,2) produced a reconciled retailer revenue total of 8,057,463.08, with no aggregate difference between Bronze and Silver.

No null values were introduced into the six tested monetary and identifier fields.

**4. Gold analytical integrity**  
The Silver-to-Gold reconciliation confirmed identical aggregate receipt-line counts and retailer revenue totals across both layers.

The results are consistent with the validated product relationships and support using gold.weekly_department_sales for the initial retail performance dashboard.

**5. Business insights supported by the data**  
Grocery generated approximately 50.8% of retailer revenue, while Grocery and Drug GM together accounted for approximately 63.9%.

The data also revealed potential measurement inconsistencies in reported quantities for Kiosk-Gas and Misc Sales Transactions. These warrant investigation before presenting cross-department units-sold comparisons.

**6. Reliability limitations**  
The validation results establish the correctness of the executed checks for the initial batch. They do not yet demonstrate incremental processing, idempotent updates, historical dimension accuracy, automated quality enforcement or recovery from pipeline failures.

## 6. Open data-quality investigations

### 6.1 Cross-department quantity comparability

The department revenue query reported:

| Department | Sum of reported `quantity` | Retailer revenue |
|---|---:|---:|
| `KIOSK-GAS` | 221,254,887 | 544,222.28 |
| `MISC SALES TRAN` | 36,080,860 | 119,960.04 |

These large quantity totals are inconsistent with a simple interpretation of interchangeable physical product units. They **might** reflect special units of measure or transaction coding, but the available dictionary does not establish the cause. Therefore, the dashboard does **not** use a retailer-wide sum-of-quantity KPI. Investigate by `product_id` and `commodity_desc` before making units-sold comparisons.

### 6.2 `UNMAPPED` department

The Gold department ranking contained an `UNMAPPED` group with `0.00` revenue and `0` units. Since product-ID anti-join checks returned zero unmatched lines, missing/blank department descriptions are a plausible explanation, **not yet verified**. Determine the number of affected receipt lines and products before deciding whether to retain, label, or separately report this group.

### 6.3 Other work outstanding

- Null/missing descriptive attributes and uniqueness of **Silver** product identifiers.
- Stable source receipt-line identity; do not assume `(basket_id, product_id)` is unique.
- Duplicate-line, out-of-range-week, malformed time and other domain checks.
- Row-level reconciliation (current monetary tests are aggregate).
- Historical SCD2 effective-date overlaps and time-valid joins.
- CDC replays, deletions, corrections, unexpected schema changes and quarantine routing.
- Automated assertion-based quality gates, scheduled jobs, alerts, backfills and runbooks.

## 7. Version-controlled checks and next steps

| Script | Purpose |
|---|---|
| `sql/11_bronze_validation.sql` | Bronze rescue, null, negativity and product uniqueness checks |
| `sql/21_silver_validation.sql` | Bronze/Silver counts, revenue conversion, null checks, product referential integrity |
| `sql/31_gold_validation.sql` | Silver/Gold line-count and revenue reconciliation |

These are manually executed SQL **checks**, not yet automatic pass/fail gates. The next release should add explicit failure assertions to Databricks Jobs, with audit logging and a replay-safe ingestion strategy.

### Proposed short follow-up queries

```sql
-- Characterize department-mapping gaps without dropping revenue
SELECT
  COUNT(*) AS unmapped_receipt_lines,
  COUNT(DISTINCT t.product_id) AS affected_products,
  SUM(t.sales_value) AS unmapped_revenue
FROM retail_analytics.silver.transactions t
LEFT JOIN retail_analytics.silver.products p
  ON t.product_id = p.product_id
WHERE p.product_id IS NULL
   OR NULLIF(TRIM(p.department), '') IS NULL;
```

```sql
-- Check receipt-line natural-key candidates; repeated combinations require investigation
SELECT basket_id, product_id, COUNT(*) AS lines
FROM retail_analytics.silver.transactions
GROUP BY basket_id, product_id
HAVING COUNT(*) > 1
ORDER BY lines DESC
LIMIT 20;
```

## Conclusion

The **initial batch Bronze–Silver–Gold pipeline passes the executed structural and aggregate reconciliation checks**, preserving all 2,595,732 transaction lines and reconciling 8,057,463.08 in retailer revenue without a Silver-to-Gold difference. This is a sound basis for the first analytics dashboard, while incremental reliability, historical modelling and automated controls remain future work.
