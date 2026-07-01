-- ============================================================
-- Procurement & Supplier Risk Analytics Database
-- Script: 02_load_data.sql
-- Purpose: Load processed CSV data into the PostgreSQL schema
-- Database: PostgreSQL
-- ============================================================

BEGIN;

-- ============================================================
-- Clean target tables
-- ============================================================

TRUNCATE TABLE
    compliance_documents,
    invoices,
    deliveries,
    purchase_order_lines,
    purchase_orders,
    categories,
    buyers,
    suppliers
RESTART IDENTITY CASCADE;

-- ============================================================
-- Staging Tables
-- ============================================================

DROP TABLE IF EXISTS stg_suppliers;
CREATE TEMP TABLE stg_suppliers (
    supplier_name TEXT,
    supplier_country TEXT,
    supplier_state TEXT,
    supplier_city TEXT,
    supplier_type TEXT,
    is_active BOOLEAN,
    source_system TEXT,
    source_supplier_id TEXT
);

DROP TABLE IF EXISTS stg_buyers;
CREATE TEMP TABLE stg_buyers (
    buyer_name TEXT,
    buyer_department TEXT,
    buyer_region TEXT,
    source_system TEXT,
    source_buyer_id TEXT
);

DROP TABLE IF EXISTS stg_categories;
CREATE TEMP TABLE stg_categories (
    category_code TEXT,
    category_name TEXT,
    category_group TEXT,
    source_system TEXT
);

DROP TABLE IF EXISTS stg_purchase_orders;
CREATE TEMP TABLE stg_purchase_orders (
    po_number TEXT,
    source_supplier_id TEXT,
    source_buyer_id TEXT,
    category_code TEXT,
    po_date DATE,
    required_delivery_date DATE,
    po_status TEXT,
    currency_code CHAR(3),
    total_amount NUMERIC(14, 2),
    source_award_id TEXT,
    source_system TEXT
);

DROP TABLE IF EXISTS stg_purchase_order_lines;
CREATE TEMP TABLE stg_purchase_order_lines (
    po_number TEXT,
    line_number INTEGER,
    item_description TEXT,
    category_code TEXT,
    quantity NUMERIC(14, 2),
    unit_price NUMERIC(14, 2),
    line_amount NUMERIC(14, 2)
);

DROP TABLE IF EXISTS stg_deliveries;
CREATE TEMP TABLE stg_deliveries (
    po_number TEXT,
    line_number INTEGER,
    scheduled_delivery_date DATE,
    actual_delivery_date DATE,
    delivery_status TEXT,
    delivered_quantity NUMERIC(14, 2)
);

DROP TABLE IF EXISTS stg_invoices;
CREATE TEMP TABLE stg_invoices (
    invoice_number TEXT,
    po_number TEXT,
    invoice_date DATE,
    due_date DATE,
    payment_date DATE,
    invoice_status TEXT,
    invoice_amount NUMERIC(14, 2),
    currency_code CHAR(3)
);

DROP TABLE IF EXISTS stg_compliance_documents;
CREATE TEMP TABLE stg_compliance_documents (
    source_supplier_id TEXT,
    supplier_name TEXT,
    document_type TEXT,
    document_status TEXT,
    issue_date DATE,
    expiration_date DATE,
    reviewed_date DATE,
    reviewed_by TEXT
);

-- ============================================================
-- Load CSV files into staging tables
-- ============================================================

\copy stg_suppliers FROM 'data/processed/suppliers.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy stg_buyers FROM 'data/processed/buyers.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy stg_categories FROM 'data/processed/categories.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy stg_purchase_orders FROM 'data/processed/purchase_orders.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy stg_purchase_order_lines FROM 'data/processed/purchase_order_lines.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy stg_deliveries FROM 'data/processed/deliveries.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy stg_invoices FROM 'data/processed/invoices.csv' WITH (FORMAT csv, HEADER true, NULL '');
\copy stg_compliance_documents FROM 'data/processed/compliance_documents.csv' WITH (FORMAT csv, HEADER true, NULL '');

-- ============================================================
-- Insert Master Data
-- ============================================================

INSERT INTO suppliers (
    supplier_name,
    supplier_country,
    supplier_state,
    supplier_city,
    supplier_type,
    is_active,
    source_system,
    source_supplier_id
)
SELECT
    supplier_name,
    supplier_country,
    supplier_state,
    supplier_city,
    supplier_type,
    COALESCE(is_active, TRUE),
    source_system,
    source_supplier_id
FROM stg_suppliers;

INSERT INTO buyers (
    buyer_name,
    buyer_department,
    buyer_region,
    source_system,
    source_buyer_id
)
SELECT
    buyer_name,
    buyer_department,
    buyer_region,
    source_system,
    source_buyer_id
FROM stg_buyers;

INSERT INTO categories (
    category_code,
    category_name,
    category_group,
    source_system
)
SELECT
    category_code,
    category_name,
    category_group,
    source_system
FROM stg_categories;

-- ============================================================
-- Insert Purchase Orders
-- ============================================================

INSERT INTO purchase_orders (
    po_number,
    supplier_id,
    buyer_id,
    category_id,
    po_date,
    required_delivery_date,
    po_status,
    currency_code,
    total_amount,
    source_award_id,
    source_system
)
SELECT
    po.po_number,
    s.supplier_id,
    b.buyer_id,
    c.category_id,
    po.po_date,
    po.required_delivery_date,
    po.po_status,
    po.currency_code,
    po.total_amount,
    po.source_award_id,
    po.source_system
FROM stg_purchase_orders po
JOIN suppliers s
    ON s.source_supplier_id = po.source_supplier_id
JOIN buyers b
    ON b.source_buyer_id = po.source_buyer_id
LEFT JOIN categories c
    ON c.category_code = po.category_code;

-- ============================================================
-- Insert Purchase Order Lines
-- ============================================================

INSERT INTO purchase_order_lines (
    po_id,
    line_number,
    item_description,
    category_id,
    quantity,
    unit_price,
    line_amount
)
SELECT
    po.po_id,
    line.line_number,
    line.item_description,
    c.category_id,
    line.quantity,
    line.unit_price,
    line.line_amount
FROM stg_purchase_order_lines line
JOIN purchase_orders po
    ON po.po_number = line.po_number
LEFT JOIN categories c
    ON c.category_code = line.category_code;

-- ============================================================
-- Insert Deliveries
-- ============================================================

INSERT INTO deliveries (
    po_line_id,
    scheduled_delivery_date,
    actual_delivery_date,
    delivery_status,
    delivered_quantity
)
SELECT
    pol.po_line_id,
    d.scheduled_delivery_date,
    d.actual_delivery_date,
    d.delivery_status,
    d.delivered_quantity
FROM stg_deliveries d
JOIN purchase_orders po
    ON po.po_number = d.po_number
JOIN purchase_order_lines pol
    ON pol.po_id = po.po_id
   AND pol.line_number = d.line_number;

-- ============================================================
-- Insert Invoices
-- ============================================================

INSERT INTO invoices (
    invoice_number,
    po_id,
    invoice_date,
    due_date,
    payment_date,
    invoice_status,
    invoice_amount,
    currency_code
)
SELECT
    i.invoice_number,
    po.po_id,
    i.invoice_date,
    i.due_date,
    i.payment_date,
    i.invoice_status,
    i.invoice_amount,
    i.currency_code
FROM stg_invoices i
JOIN purchase_orders po
    ON po.po_number = i.po_number;

-- ============================================================
-- Insert Compliance Documents
-- ============================================================

INSERT INTO compliance_documents (
    supplier_id,
    document_type,
    document_status,
    issue_date,
    expiration_date,
    reviewed_date,
    reviewed_by
)
SELECT
    s.supplier_id,
    cd.document_type,
    cd.document_status,
    cd.issue_date,
    cd.expiration_date,
    cd.reviewed_date,
    cd.reviewed_by
FROM stg_compliance_documents cd
JOIN suppliers s
    ON s.source_supplier_id = cd.source_supplier_id;

-- ============================================================
-- Final Load Validation
-- ============================================================

SELECT 'suppliers' AS table_name, COUNT(*) AS row_count FROM suppliers
UNION ALL
SELECT 'buyers', COUNT(*) FROM buyers
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'purchase_orders', COUNT(*) FROM purchase_orders
UNION ALL
SELECT 'purchase_order_lines', COUNT(*) FROM purchase_order_lines
UNION ALL
SELECT 'deliveries', COUNT(*) FROM deliveries
UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL
SELECT 'compliance_documents', COUNT(*) FROM compliance_documents
ORDER BY table_name;

COMMIT;
