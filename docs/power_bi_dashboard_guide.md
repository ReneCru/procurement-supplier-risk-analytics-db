# Power BI Dashboard Guide

## Dashboard Name

Procurement & Supplier Risk Analytics Dashboard

## Data Source

Use the CSV files located in:

data/dashboard_exports/

Files:

- supplier_risk_score.csv
- supplier_spend_summary.csv
- spend_by_category.csv
- monthly_purchasing_trend.csv
- late_delivery_performance.csv
- open_po_aging.csv
- supplier_compliance_status.csv

## Recommended Dashboard Pages

### 1. Executive Summary

Purpose:
Give a high-level view of procurement spend, supplier base, purchase order volume, delivery risk, and compliance exposure.

Recommended visuals:

- Card: Total Spend
- Card: Total Suppliers
- Card: Total Purchase Orders
- Card: Total Deliveries
- Card: Total Compliance Documents
- Bar chart: Spend by Category
- Line chart: Monthly Purchasing Trend
- Table: Top 10 Supplier Risk Score

Main tables:

- supplier_risk_score
- spend_by_category
- monthly_purchasing_trend

### 2. Supplier Risk

Purpose:
Identify suppliers that should be prioritized for review.

Recommended visuals:

- Table: Supplier Risk Score
- Bar chart: Top 10 suppliers by supplier risk score
- Scatter chart: Total Spend vs Late Delivery Rate
- Donut chart: Risk Level distribution

Main table:

- supplier_risk_score

Important fields:

- supplier_name
- total_spend
- late_delivery_rate_pct
- expired_documents
- missing_documents
- overdue_invoices
- supplier_risk_score
- risk_level

### 3. Spend Analysis

Purpose:
Analyze procurement spend by supplier and category.

Recommended visuals:

- Bar chart: Spend by Category
- Bar chart: Top Suppliers by Total Spend
- Matrix: Category by Supplier
- Card: Average PO Amount

Main tables:

- spend_by_category
- supplier_spend_summary

Important fields:

- category_name
- total_spend
- total_purchase_orders
- total_suppliers
- average_po_amount
- supplier_name

### 4. Delivery Performance

Purpose:
Analyze supplier delivery reliability.

Recommended visuals:

- Bar chart: Suppliers with most late deliveries
- Table: Late Delivery Performance
- Card: Total Late Deliveries
- Card: Average Late Days
- Bar chart: Late Delivery Rate by Supplier

Main table:

- late_delivery_performance

Important fields:

- supplier_name
- total_deliveries
- late_delivery_count
- pending_delivery_count
- late_delivery_rate_pct
- average_late_days
- max_delay_days

### 5. Compliance Risk

Purpose:
Identify suppliers with expired, missing, or pending compliance documents.

Recommended visuals:

- Table: Supplier Compliance Status
- Bar chart: Expired Documents by Supplier
- Bar chart: Missing Documents by Supplier
- Donut chart: Compliance Risk Status

Main table:

- supplier_compliance_status

Important fields:

- supplier_name
- total_documents
- valid_documents
- expired_documents
- missing_documents
- pending_review_documents
- next_expiration_date
- compliance_risk_status

### 6. Open PO Aging

Purpose:
Analyze open purchase orders by aging bucket and value.

Recommended visuals:

- Bar chart: Open PO Value by Aging Bucket
- Table: Open Purchase Orders
- Card: Open PO Value
- Card: Open PO Count

Main table:

- open_po_aging

Important fields:

- aging_bucket
- po_number
- supplier_name
- buyer_name
- category_name
- po_date
- required_delivery_date
- total_amount
- po_age_days

## Recommended Power BI Theme

Use a clean professional theme:

- Background: white or very light gray
- Main color: dark blue
- Accent color: orange or teal
- Font: Segoe UI
- Use cards at the top
- Use charts in the middle
- Use detail tables at the bottom

## Suggested Report Title

Procurement & Supplier Risk Analytics Dashboard

## Suggested Subtitle

Supplier spend, delivery performance, open PO aging, compliance risk, and supplier risk scoring.
