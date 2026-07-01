-- ============================================================
-- Procurement & Supplier Risk Analytics Database
-- Script: 01_create_tables.sql
-- Purpose: Create the core relational database schema
-- Database: PostgreSQL
-- ============================================================

DROP TABLE IF EXISTS compliance_documents CASCADE;
DROP TABLE IF EXISTS invoices CASCADE;
DROP TABLE IF EXISTS deliveries CASCADE;
DROP TABLE IF EXISTS purchase_order_lines CASCADE;
DROP TABLE IF EXISTS purchase_orders CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS buyers CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;

-- ============================================================
-- Suppliers
-- Stores supplier master data.
-- ============================================================

CREATE TABLE suppliers (
    supplier_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name TEXT NOT NULL,
    supplier_country TEXT,
    supplier_state TEXT,
    supplier_city TEXT,
    supplier_type TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    source_system TEXT DEFAULT 'USAspending',
    source_supplier_id TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Buyers
-- Stores buyer, agency, department, or purchasing owner data.
-- ============================================================

CREATE TABLE buyers (
    buyer_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    buyer_name TEXT NOT NULL,
    buyer_department TEXT,
    buyer_region TEXT,
    source_system TEXT DEFAULT 'USAspending',
    source_buyer_id TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Categories
-- Stores procurement category data such as NAICS, PSC, or internal categories.
-- ============================================================

CREATE TABLE categories (
    category_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_code TEXT,
    category_name TEXT NOT NULL,
    category_group TEXT,
    source_system TEXT DEFAULT 'USAspending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Purchase Orders
-- Stores purchase order header data.
-- Public procurement awards will be mapped to purchase orders.
-- ============================================================

CREATE TABLE purchase_orders (
    po_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    po_number TEXT NOT NULL UNIQUE,
    supplier_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    category_id BIGINT,
    po_date DATE NOT NULL,
    required_delivery_date DATE,
    po_status TEXT NOT NULL DEFAULT 'open',
    currency_code CHAR(3) NOT NULL DEFAULT 'USD',
    total_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    source_award_id TEXT,
    source_system TEXT DEFAULT 'USAspending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_purchase_orders_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers (supplier_id),

    CONSTRAINT fk_purchase_orders_buyer
        FOREIGN KEY (buyer_id)
        REFERENCES buyers (buyer_id),

    CONSTRAINT fk_purchase_orders_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id),

    CONSTRAINT chk_purchase_orders_amount
        CHECK (total_amount >= 0),

    CONSTRAINT chk_purchase_orders_status
        CHECK (po_status IN ('open', 'closed', 'cancelled'))
);

-- ============================================================
-- Purchase Order Lines
-- Stores line-level purchasing detail.
-- ============================================================

CREATE TABLE purchase_order_lines (
    po_line_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    po_id BIGINT NOT NULL,
    line_number INTEGER NOT NULL,
    item_description TEXT NOT NULL,
    category_id BIGINT,
    quantity NUMERIC(14, 2) NOT NULL DEFAULT 1,
    unit_price NUMERIC(14, 2) NOT NULL DEFAULT 0,
    line_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_po_lines_po
        FOREIGN KEY (po_id)
        REFERENCES purchase_orders (po_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_po_lines_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id),

    CONSTRAINT uq_po_line_number
        UNIQUE (po_id, line_number),

    CONSTRAINT chk_po_lines_quantity
        CHECK (quantity > 0),

    CONSTRAINT chk_po_lines_unit_price
        CHECK (unit_price >= 0),

    CONSTRAINT chk_po_lines_line_amount
        CHECK (line_amount >= 0)
);

-- ============================================================
-- Deliveries
-- Stores delivery performance by PO line.
-- ============================================================

CREATE TABLE deliveries (
    delivery_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    po_line_id BIGINT NOT NULL,
    scheduled_delivery_date DATE NOT NULL,
    actual_delivery_date DATE,
    delivery_status TEXT NOT NULL DEFAULT 'pending',
    delivered_quantity NUMERIC(14, 2) NOT NULL DEFAULT 0,
    delay_days INTEGER GENERATED ALWAYS AS (
        CASE
            WHEN actual_delivery_date IS NULL THEN NULL
            ELSE actual_delivery_date - scheduled_delivery_date
        END
    ) STORED,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_deliveries_po_line
        FOREIGN KEY (po_line_id)
        REFERENCES purchase_order_lines (po_line_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_deliveries_status
        CHECK (delivery_status IN ('pending', 'delivered', 'late', 'cancelled')),

    CONSTRAINT chk_deliveries_quantity
        CHECK (delivered_quantity >= 0)
);

-- ============================================================
-- Invoices
-- Stores invoice data related to purchase orders.
-- ============================================================

CREATE TABLE invoices (
    invoice_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_number TEXT NOT NULL UNIQUE,
    po_id BIGINT NOT NULL,
    invoice_date DATE NOT NULL,
    due_date DATE NOT NULL,
    payment_date DATE,
    invoice_status TEXT NOT NULL DEFAULT 'open',
    invoice_amount NUMERIC(14, 2) NOT NULL DEFAULT 0,
    currency_code CHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_invoices_po
        FOREIGN KEY (po_id)
        REFERENCES purchase_orders (po_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_invoices_status
        CHECK (invoice_status IN ('open', 'paid', 'overdue', 'cancelled')),

    CONSTRAINT chk_invoices_amount
        CHECK (invoice_amount >= 0)
);

-- ============================================================
-- Compliance Documents
-- Stores supplier compliance documentation such as NDA, insurance,
-- certifications, sanctions screening, or quality documents.
-- ============================================================

CREATE TABLE compliance_documents (
    document_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_id BIGINT NOT NULL,
    document_type TEXT NOT NULL,
    document_status TEXT NOT NULL DEFAULT 'valid',
    issue_date DATE,
    expiration_date DATE,
    reviewed_date DATE,
    reviewed_by TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_compliance_documents_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers (supplier_id)
        ON DELETE CASCADE,

    CONSTRAINT chk_compliance_documents_status
        CHECK (document_status IN ('valid', 'expired', 'missing', 'pending_review'))
);
