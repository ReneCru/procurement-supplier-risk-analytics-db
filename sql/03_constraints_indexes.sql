-- ============================================================
-- Procurement & Supplier Risk Analytics Database
-- Script: 03_constraints_indexes.sql
-- Purpose: Add data quality constraints and analytical indexes
-- Database: PostgreSQL
-- ============================================================

-- ============================================================
-- Additional Data Quality Constraints
-- ============================================================

ALTER TABLE purchase_orders
DROP CONSTRAINT IF EXISTS chk_purchase_orders_required_delivery_date;

ALTER TABLE purchase_orders
ADD CONSTRAINT chk_purchase_orders_required_delivery_date
CHECK (
    required_delivery_date IS NULL
    OR required_delivery_date >= po_date
);

ALTER TABLE invoices
DROP CONSTRAINT IF EXISTS chk_invoices_due_date;

ALTER TABLE invoices
ADD CONSTRAINT chk_invoices_due_date
CHECK (due_date >= invoice_date);

ALTER TABLE invoices
DROP CONSTRAINT IF EXISTS chk_invoices_payment_date;

ALTER TABLE invoices
ADD CONSTRAINT chk_invoices_payment_date
CHECK (
    payment_date IS NULL
    OR payment_date >= invoice_date
);

ALTER TABLE compliance_documents
DROP CONSTRAINT IF EXISTS chk_compliance_documents_expiration_date;

ALTER TABLE compliance_documents
ADD CONSTRAINT chk_compliance_documents_expiration_date
CHECK (
    expiration_date IS NULL
    OR issue_date IS NULL
    OR expiration_date >= issue_date
);

-- ============================================================
-- Supplier Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_suppliers_supplier_name;
CREATE INDEX idx_suppliers_supplier_name
ON suppliers (supplier_name);

DROP INDEX IF EXISTS idx_suppliers_source_supplier_id;
CREATE INDEX idx_suppliers_source_supplier_id
ON suppliers (source_supplier_id);

DROP INDEX IF EXISTS idx_suppliers_country_state;
CREATE INDEX idx_suppliers_country_state
ON suppliers (supplier_country, supplier_state);

-- ============================================================
-- Buyer Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_buyers_buyer_name;
CREATE INDEX idx_buyers_buyer_name
ON buyers (buyer_name);

DROP INDEX IF EXISTS idx_buyers_department;
CREATE INDEX idx_buyers_department
ON buyers (buyer_department);

-- ============================================================
-- Category Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_categories_code;
CREATE INDEX idx_categories_code
ON categories (category_code);

DROP INDEX IF EXISTS idx_categories_group;
CREATE INDEX idx_categories_group
ON categories (category_group);

-- ============================================================
-- Purchase Order Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_purchase_orders_supplier_id;
CREATE INDEX idx_purchase_orders_supplier_id
ON purchase_orders (supplier_id);

DROP INDEX IF EXISTS idx_purchase_orders_buyer_id;
CREATE INDEX idx_purchase_orders_buyer_id
ON purchase_orders (buyer_id);

DROP INDEX IF EXISTS idx_purchase_orders_category_id;
CREATE INDEX idx_purchase_orders_category_id
ON purchase_orders (category_id);

DROP INDEX IF EXISTS idx_purchase_orders_po_date;
CREATE INDEX idx_purchase_orders_po_date
ON purchase_orders (po_date);

DROP INDEX IF EXISTS idx_purchase_orders_status;
CREATE INDEX idx_purchase_orders_status
ON purchase_orders (po_status);

DROP INDEX IF EXISTS idx_purchase_orders_required_delivery_date;
CREATE INDEX idx_purchase_orders_required_delivery_date
ON purchase_orders (required_delivery_date);

DROP INDEX IF EXISTS idx_purchase_orders_supplier_date;
CREATE INDEX idx_purchase_orders_supplier_date
ON purchase_orders (supplier_id, po_date);

DROP INDEX IF EXISTS idx_purchase_orders_category_date;
CREATE INDEX idx_purchase_orders_category_date
ON purchase_orders (category_id, po_date);

-- ============================================================
-- Purchase Order Line Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_po_lines_po_id;
CREATE INDEX idx_po_lines_po_id
ON purchase_order_lines (po_id);

DROP INDEX IF EXISTS idx_po_lines_category_id;
CREATE INDEX idx_po_lines_category_id
ON purchase_order_lines (category_id);

-- ============================================================
-- Delivery Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_deliveries_po_line_id;
CREATE INDEX idx_deliveries_po_line_id
ON deliveries (po_line_id);

DROP INDEX IF EXISTS idx_deliveries_status;
CREATE INDEX idx_deliveries_status
ON deliveries (delivery_status);

DROP INDEX IF EXISTS idx_deliveries_scheduled_date;
CREATE INDEX idx_deliveries_scheduled_date
ON deliveries (scheduled_delivery_date);

DROP INDEX IF EXISTS idx_deliveries_actual_date;
CREATE INDEX idx_deliveries_actual_date
ON deliveries (actual_delivery_date);

DROP INDEX IF EXISTS idx_deliveries_delay_days;
CREATE INDEX idx_deliveries_delay_days
ON deliveries (delay_days);

-- ============================================================
-- Invoice Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_invoices_po_id;
CREATE INDEX idx_invoices_po_id
ON invoices (po_id);

DROP INDEX IF EXISTS idx_invoices_status;
CREATE INDEX idx_invoices_status
ON invoices (invoice_status);

DROP INDEX IF EXISTS idx_invoices_invoice_date;
CREATE INDEX idx_invoices_invoice_date
ON invoices (invoice_date);

DROP INDEX IF EXISTS idx_invoices_due_date;
CREATE INDEX idx_invoices_due_date
ON invoices (due_date);

DROP INDEX IF EXISTS idx_invoices_payment_date;
CREATE INDEX idx_invoices_payment_date
ON invoices (payment_date);

-- ============================================================
-- Compliance Document Indexes
-- ============================================================

DROP INDEX IF EXISTS idx_compliance_documents_supplier_id;
CREATE INDEX idx_compliance_documents_supplier_id
ON compliance_documents (supplier_id);

DROP INDEX IF EXISTS idx_compliance_documents_type;
CREATE INDEX idx_compliance_documents_type
ON compliance_documents (document_type);

DROP INDEX IF EXISTS idx_compliance_documents_status;
CREATE INDEX idx_compliance_documents_status
ON compliance_documents (document_status);

DROP INDEX IF EXISTS idx_compliance_documents_expiration_date;
CREATE INDEX idx_compliance_documents_expiration_date
ON compliance_documents (expiration_date);

DROP INDEX IF EXISTS idx_compliance_documents_supplier_status;
CREATE INDEX idx_compliance_documents_supplier_status
ON compliance_documents (supplier_id, document_status);
