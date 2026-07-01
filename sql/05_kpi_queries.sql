-- ============================================================
-- Procurement & Supplier Risk Analytics Database
-- Script: 05_kpi_queries.sql
-- Purpose: Final KPI queries for procurement analytics portfolio
-- Database: PostgreSQL
-- ============================================================

\pset pager off

-- ============================================================
-- KPI 1: Top Suppliers by Total Spend
-- Business Question:
-- Which suppliers represent the highest spend exposure?
-- ============================================================

\echo 'KPI 1: Top Suppliers by Total Spend'

SELECT
    supplier_name,
    total_purchase_orders,
    total_spend,
    average_po_amount,
    first_po_date,
    latest_po_date
FROM vw_supplier_spend_summary
ORDER BY total_spend DESC
LIMIT 10;

-- ============================================================
-- KPI 2: Suppliers with Most Late Deliveries
-- Business Question:
-- Which suppliers have the highest late delivery exposure?
-- ============================================================

\echo 'KPI 2: Suppliers with Most Late Deliveries'

SELECT
    supplier_name,
    total_deliveries,
    delivered_count,
    late_delivery_count,
    pending_delivery_count,
    late_delivery_rate_pct,
    average_late_days,
    max_delay_days
FROM vw_late_delivery_performance
WHERE late_delivery_count > 0
ORDER BY late_delivery_count DESC, late_delivery_rate_pct DESC
LIMIT 10;

-- ============================================================
-- KPI 3: Open Purchase Orders by Aging Bucket
-- Business Question:
-- What is the value of open purchase orders by age?
-- ============================================================

\echo 'KPI 3: Open Purchase Orders by Aging Bucket'

SELECT
    aging_bucket,
    COUNT(*) AS open_po_count,
    ROUND(SUM(total_amount), 2) AS open_po_value,
    ROUND(AVG(total_amount), 2) AS average_open_po_value
FROM vw_open_po_aging
GROUP BY aging_bucket
ORDER BY open_po_value DESC;

-- ============================================================
-- KPI 4: Suppliers with Expired or Missing Compliance Documents
-- Business Question:
-- Which suppliers require compliance review?
-- ============================================================

\echo 'KPI 4: Suppliers with Expired or Missing Compliance Documents'

SELECT
    supplier_name,
    total_documents,
    valid_documents,
    expired_documents,
    missing_documents,
    pending_review_documents,
    next_expiration_date,
    compliance_risk_status
FROM vw_supplier_compliance_status
WHERE expired_documents > 0
   OR missing_documents > 0
   OR pending_review_documents > 0
ORDER BY expired_documents DESC, missing_documents DESC, pending_review_documents DESC
LIMIT 20;

-- ============================================================
-- KPI 5: Spend by Category
-- Business Question:
-- Which procurement categories drive the most spend?
-- ============================================================

\echo 'KPI 5: Spend by Category'

SELECT
    category_name,
    category_group,
    total_purchase_orders,
    total_suppliers,
    total_spend,
    average_po_amount
FROM vw_spend_by_category
ORDER BY total_spend DESC;

-- ============================================================
-- KPI 6: Monthly Purchasing Trend
-- Business Question:
-- How is procurement activity trending month over month?
-- ============================================================

\echo 'KPI 6: Monthly Purchasing Trend'

SELECT
    purchase_month,
    total_purchase_orders,
    total_suppliers,
    total_categories,
    total_spend,
    average_po_amount
FROM vw_monthly_purchasing_trend
ORDER BY purchase_month;

-- ============================================================
-- KPI 7: Supplier Risk Score
-- Business Question:
-- Which suppliers should be prioritized for supplier risk review?
-- ============================================================

\echo 'KPI 7: Supplier Risk Score'

SELECT
    supplier_name,
    total_purchase_orders,
    total_spend,
    total_deliveries,
    late_deliveries,
    late_delivery_rate_pct,
    expired_documents,
    missing_documents,
    overdue_invoices,
    spend_exposure_score,
    delivery_risk_score,
    compliance_risk_score,
    invoice_risk_score,
    supplier_risk_score,
    risk_level
FROM vw_supplier_risk_score
ORDER BY supplier_risk_score DESC
LIMIT 15;

-- ============================================================
-- KPI 8: Overdue Invoice Exposure
-- Business Question:
-- Which suppliers have overdue invoice exposure?
-- ============================================================

\echo 'KPI 8: Overdue Invoice Exposure'

SELECT
    s.supplier_name,
    COUNT(i.invoice_id) AS total_invoices,
    COUNT(*) FILTER (WHERE i.invoice_status = 'overdue') AS overdue_invoices,
    ROUND(SUM(i.invoice_amount) FILTER (WHERE i.invoice_status = 'overdue'), 2) AS overdue_invoice_value,
    ROUND(SUM(i.invoice_amount), 2) AS total_invoice_value
FROM suppliers s
JOIN purchase_orders po
    ON po.supplier_id = s.supplier_id
JOIN invoices i
    ON i.po_id = po.po_id
GROUP BY
    s.supplier_name
HAVING COUNT(*) FILTER (WHERE i.invoice_status = 'overdue') > 0
ORDER BY overdue_invoice_value DESC NULLS LAST;

-- ============================================================
-- KPI 9: Buyer Spend Summary
-- Business Question:
-- Which buyers or agencies manage the highest procurement spend?
-- ============================================================

\echo 'KPI 9: Buyer Spend Summary'

SELECT
    b.buyer_name,
    b.buyer_department,
    COUNT(DISTINCT po.po_id) AS total_purchase_orders,
    COUNT(DISTINCT po.supplier_id) AS total_suppliers,
    ROUND(SUM(po.total_amount), 2) AS total_spend,
    ROUND(AVG(po.total_amount), 2) AS average_po_amount
FROM buyers b
JOIN purchase_orders po
    ON po.buyer_id = b.buyer_id
GROUP BY
    b.buyer_name,
    b.buyer_department
ORDER BY total_spend DESC
LIMIT 10;

-- ============================================================
-- KPI 10: Executive Procurement Summary
-- Business Question:
-- What are the overall procurement portfolio totals?
-- ============================================================

\echo 'KPI 10: Executive Procurement Summary'

SELECT
    COUNT(DISTINCT s.supplier_id) AS total_suppliers,
    COUNT(DISTINCT b.buyer_id) AS total_buyers,
    COUNT(DISTINCT c.category_id) AS total_categories,
    COUNT(DISTINCT po.po_id) AS total_purchase_orders,
    COUNT(DISTINCT pol.po_line_id) AS total_po_lines,
    COUNT(DISTINCT d.delivery_id) AS total_deliveries,
    COUNT(DISTINCT i.invoice_id) AS total_invoices,
    COUNT(DISTINCT cd.document_id) AS total_compliance_documents,
    ROUND(SUM(DISTINCT po.total_amount), 2) AS total_po_spend
FROM purchase_orders po
JOIN suppliers s
    ON s.supplier_id = po.supplier_id
JOIN buyers b
    ON b.buyer_id = po.buyer_id
LEFT JOIN categories c
    ON c.category_id = po.category_id
LEFT JOIN purchase_order_lines pol
    ON pol.po_id = po.po_id
LEFT JOIN deliveries d
    ON d.po_line_id = pol.po_line_id
LEFT JOIN invoices i
    ON i.po_id = po.po_id
LEFT JOIN compliance_documents cd
    ON cd.supplier_id = s.supplier_id;
