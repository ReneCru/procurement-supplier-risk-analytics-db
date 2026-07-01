-- ============================================================
-- Procurement & Supplier Risk Analytics Database
-- Script: 04_business_views.sql
-- Purpose: Create business views for procurement analytics KPIs
-- Database: PostgreSQL
-- ============================================================

DROP VIEW IF EXISTS vw_supplier_risk_score;
DROP VIEW IF EXISTS vw_supplier_compliance_status;
DROP VIEW IF EXISTS vw_open_po_aging;
DROP VIEW IF EXISTS vw_late_delivery_performance;
DROP VIEW IF EXISTS vw_monthly_purchasing_trend;
DROP VIEW IF EXISTS vw_spend_by_category;
DROP VIEW IF EXISTS vw_supplier_spend_summary;

-- ============================================================
-- Supplier Spend Summary
-- ============================================================

CREATE VIEW vw_supplier_spend_summary AS
SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(DISTINCT po.po_id) AS total_purchase_orders,
    ROUND(SUM(po.total_amount), 2) AS total_spend,
    ROUND(AVG(po.total_amount), 2) AS average_po_amount,
    MIN(po.po_date) AS first_po_date,
    MAX(po.po_date) AS latest_po_date
FROM suppliers s
JOIN purchase_orders po
    ON po.supplier_id = s.supplier_id
GROUP BY
    s.supplier_id,
    s.supplier_name;

-- ============================================================
-- Spend by Category
-- ============================================================

CREATE VIEW vw_spend_by_category AS
SELECT
    c.category_id,
    c.category_code,
    c.category_name,
    c.category_group,
    COUNT(DISTINCT po.po_id) AS total_purchase_orders,
    COUNT(DISTINCT po.supplier_id) AS total_suppliers,
    ROUND(SUM(po.total_amount), 2) AS total_spend,
    ROUND(AVG(po.total_amount), 2) AS average_po_amount
FROM categories c
JOIN purchase_orders po
    ON po.category_id = c.category_id
GROUP BY
    c.category_id,
    c.category_code,
    c.category_name,
    c.category_group;

-- ============================================================
-- Monthly Purchasing Trend
-- ============================================================

CREATE VIEW vw_monthly_purchasing_trend AS
SELECT
    DATE_TRUNC('month', po.po_date)::DATE AS purchase_month,
    COUNT(DISTINCT po.po_id) AS total_purchase_orders,
    COUNT(DISTINCT po.supplier_id) AS total_suppliers,
    COUNT(DISTINCT po.category_id) AS total_categories,
    ROUND(SUM(po.total_amount), 2) AS total_spend,
    ROUND(AVG(po.total_amount), 2) AS average_po_amount
FROM purchase_orders po
GROUP BY
    DATE_TRUNC('month', po.po_date)::DATE;

-- ============================================================
-- Late Delivery Performance
-- ============================================================

CREATE VIEW vw_late_delivery_performance AS
SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(d.delivery_id) AS total_deliveries,
    COUNT(*) FILTER (WHERE d.delivery_status = 'delivered') AS delivered_count,
    COUNT(*) FILTER (WHERE d.delivery_status = 'late') AS late_delivery_count,
    COUNT(*) FILTER (WHERE d.delivery_status = 'pending') AS pending_delivery_count,
    ROUND(
        COUNT(*) FILTER (WHERE d.delivery_status = 'late')::NUMERIC
        / NULLIF(COUNT(d.delivery_id), 0) * 100,
        2
    ) AS late_delivery_rate_pct,
    ROUND(
        AVG(CASE WHEN d.delay_days > 0 THEN d.delay_days END),
        2
    ) AS average_late_days,
    MAX(d.delay_days) AS max_delay_days
FROM suppliers s
JOIN purchase_orders po
    ON po.supplier_id = s.supplier_id
JOIN purchase_order_lines pol
    ON pol.po_id = po.po_id
JOIN deliveries d
    ON d.po_line_id = pol.po_line_id
GROUP BY
    s.supplier_id,
    s.supplier_name;

-- ============================================================
-- Open PO Aging
-- ============================================================

CREATE VIEW vw_open_po_aging AS
SELECT
    po.po_id,
    po.po_number,
    s.supplier_name,
    b.buyer_name,
    b.buyer_department,
    c.category_name,
    po.po_date,
    po.required_delivery_date,
    po.po_status,
    po.total_amount,
    DATE '2026-07-01' AS analysis_reference_date,
    DATE '2026-07-01' - po.po_date AS po_age_days,
    CASE
        WHEN po.po_date > DATE '2026-07-01' THEN 'Future-dated'
        WHEN DATE '2026-07-01' - po.po_date <= 30 THEN '0-30 days'
        WHEN DATE '2026-07-01' - po.po_date <= 60 THEN '31-60 days'
        WHEN DATE '2026-07-01' - po.po_date <= 90 THEN '61-90 days'
        WHEN DATE '2026-07-01' - po.po_date <= 180 THEN '91-180 days'
        WHEN DATE '2026-07-01' - po.po_date <= 365 THEN '181-365 days'
        ELSE '365+ days'
    END AS aging_bucket
FROM purchase_orders po
JOIN suppliers s
    ON s.supplier_id = po.supplier_id
JOIN buyers b
    ON b.buyer_id = po.buyer_id
LEFT JOIN categories c
    ON c.category_id = po.category_id
WHERE po.po_status = 'open';

-- ============================================================
-- Supplier Compliance Status
-- ============================================================

CREATE VIEW vw_supplier_compliance_status AS
SELECT
    s.supplier_id,
    s.supplier_name,
    COUNT(cd.document_id) AS total_documents,
    COUNT(*) FILTER (WHERE cd.document_status = 'valid') AS valid_documents,
    COUNT(*) FILTER (WHERE cd.document_status = 'expired') AS expired_documents,
    COUNT(*) FILTER (WHERE cd.document_status = 'missing') AS missing_documents,
    COUNT(*) FILTER (WHERE cd.document_status = 'pending_review') AS pending_review_documents,
    MIN(cd.expiration_date) FILTER (WHERE cd.expiration_date IS NOT NULL) AS next_expiration_date,
    CASE
        WHEN COUNT(*) FILTER (WHERE cd.document_status = 'missing') > 0
          OR COUNT(*) FILTER (WHERE cd.document_status = 'expired') > 0
            THEN 'Requires Review'
        WHEN COUNT(*) FILTER (WHERE cd.document_status = 'pending_review') > 0
            THEN 'Pending Review'
        ELSE 'Compliant'
    END AS compliance_risk_status
FROM suppliers s
LEFT JOIN compliance_documents cd
    ON cd.supplier_id = s.supplier_id
GROUP BY
    s.supplier_id,
    s.supplier_name;

-- ============================================================
-- Supplier Risk Score
-- ============================================================

CREATE VIEW vw_supplier_risk_score AS
WITH spend_base AS (
    SELECT
        s.supplier_id,
        s.supplier_name,
        COUNT(DISTINCT po.po_id) AS total_purchase_orders,
        COALESCE(SUM(po.total_amount), 0) AS total_spend
    FROM suppliers s
    LEFT JOIN purchase_orders po
        ON po.supplier_id = s.supplier_id
    GROUP BY
        s.supplier_id,
        s.supplier_name
),

delivery_base AS (
    SELECT
        s.supplier_id,
        COUNT(d.delivery_id) AS total_deliveries,
        COUNT(*) FILTER (WHERE d.delivery_status = 'late') AS late_deliveries,
        COALESCE(
            COUNT(*) FILTER (WHERE d.delivery_status = 'late')::NUMERIC
            / NULLIF(COUNT(d.delivery_id), 0),
            0
        ) AS late_delivery_rate
    FROM suppliers s
    LEFT JOIN purchase_orders po
        ON po.supplier_id = s.supplier_id
    LEFT JOIN purchase_order_lines pol
        ON pol.po_id = po.po_id
    LEFT JOIN deliveries d
        ON d.po_line_id = pol.po_line_id
    GROUP BY
        s.supplier_id
),

compliance_base AS (
    SELECT
        s.supplier_id,
        COUNT(cd.document_id) AS total_documents,
        COUNT(*) FILTER (WHERE cd.document_status = 'expired') AS expired_documents,
        COUNT(*) FILTER (WHERE cd.document_status = 'missing') AS missing_documents,
        COUNT(*) FILTER (WHERE cd.document_status = 'pending_review') AS pending_review_documents,
        COALESCE(
            (
                COUNT(*) FILTER (WHERE cd.document_status = 'expired') * 1.0
                + COUNT(*) FILTER (WHERE cd.document_status = 'missing') * 1.25
                + COUNT(*) FILTER (WHERE cd.document_status = 'pending_review') * 0.5
            ) / NULLIF(COUNT(cd.document_id), 0),
            0
        ) AS compliance_risk_rate
    FROM suppliers s
    LEFT JOIN compliance_documents cd
        ON cd.supplier_id = s.supplier_id
    GROUP BY
        s.supplier_id
),

invoice_base AS (
    SELECT
        s.supplier_id,
        COUNT(i.invoice_id) AS total_invoices,
        COUNT(*) FILTER (WHERE i.invoice_status = 'overdue') AS overdue_invoices,
        COALESCE(
            COUNT(*) FILTER (WHERE i.invoice_status = 'overdue')::NUMERIC
            / NULLIF(COUNT(i.invoice_id), 0),
            0
        ) AS overdue_invoice_rate
    FROM suppliers s
    LEFT JOIN purchase_orders po
        ON po.supplier_id = s.supplier_id
    LEFT JOIN invoices i
        ON i.po_id = po.po_id
    GROUP BY
        s.supplier_id
),

combined AS (
    SELECT
        sb.supplier_id,
        sb.supplier_name,
        sb.total_purchase_orders,
        sb.total_spend,
        db.total_deliveries,
        db.late_deliveries,
        db.late_delivery_rate,
        cb.total_documents,
        cb.expired_documents,
        cb.missing_documents,
        cb.pending_review_documents,
        cb.compliance_risk_rate,
        ib.total_invoices,
        ib.overdue_invoices,
        ib.overdue_invoice_rate,
        MAX(sb.total_spend) OVER () AS max_total_spend
    FROM spend_base sb
    LEFT JOIN delivery_base db
        ON db.supplier_id = sb.supplier_id
    LEFT JOIN compliance_base cb
        ON cb.supplier_id = sb.supplier_id
    LEFT JOIN invoice_base ib
        ON ib.supplier_id = sb.supplier_id
)

SELECT
    supplier_id,
    supplier_name,
    total_purchase_orders,
    ROUND(total_spend, 2) AS total_spend,
    total_deliveries,
    late_deliveries,
    ROUND(late_delivery_rate * 100, 2) AS late_delivery_rate_pct,
    total_documents,
    expired_documents,
    missing_documents,
    pending_review_documents,
    total_invoices,
    overdue_invoices,
    ROUND(
        CASE
            WHEN max_total_spend = 0 THEN 0
            ELSE total_spend / max_total_spend * 100
        END,
        2
    ) AS spend_exposure_score,
    ROUND(late_delivery_rate * 100, 2) AS delivery_risk_score,
    ROUND(LEAST(compliance_risk_rate * 100, 100), 2) AS compliance_risk_score,
    ROUND(overdue_invoice_rate * 100, 2) AS invoice_risk_score,
    ROUND(
        (
            CASE
                WHEN max_total_spend = 0 THEN 0
                ELSE total_spend / max_total_spend * 100
            END * 0.40
        )
        + (late_delivery_rate * 100 * 0.30)
        + (LEAST(compliance_risk_rate * 100, 100) * 0.20)
        + (overdue_invoice_rate * 100 * 0.10),
        2
    ) AS supplier_risk_score,
    CASE
        WHEN (
            (
                CASE
                    WHEN max_total_spend = 0 THEN 0
                    ELSE total_spend / max_total_spend * 100
                END * 0.40
            )
            + (late_delivery_rate * 100 * 0.30)
            + (LEAST(compliance_risk_rate * 100, 100) * 0.20)
            + (overdue_invoice_rate * 100 * 0.10)
        ) >= 70 THEN 'High'
        WHEN (
            (
                CASE
                    WHEN max_total_spend = 0 THEN 0
                    ELSE total_spend / max_total_spend * 100
                END * 0.40
            )
            + (late_delivery_rate * 100 * 0.30)
            + (LEAST(compliance_risk_rate * 100, 100) * 0.20)
            + (overdue_invoice_rate * 100 * 0.10)
        ) >= 40 THEN 'Medium'
        WHEN (
            (
                CASE
                    WHEN max_total_spend = 0 THEN 0
                    ELSE total_spend / max_total_spend * 100
                END * 0.40
            )
            + (late_delivery_rate * 100 * 0.30)
            + (LEAST(compliance_risk_rate * 100, 100) * 0.20)
            + (overdue_invoice_rate * 100 * 0.10)
        ) >= 20 THEN 'Low'
        ELSE 'Monitor'
    END AS risk_level
FROM combined;
