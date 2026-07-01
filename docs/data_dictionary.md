# Data Dictionary

## suppliers

Stores supplier master data.

| Column | Type | Description |
|---|---|---|
| supplier_id | BIGINT | Primary key |
| supplier_name | TEXT | Supplier legal or display name |
| supplier_country | TEXT | Supplier country |
| supplier_state | TEXT | Supplier state or region |
| supplier_city | TEXT | Supplier city |
| supplier_type | TEXT | Supplier classification |
| is_active | BOOLEAN | Indicates whether supplier is active |
| source_system | TEXT | Source system name |
| source_supplier_id | TEXT | Supplier identifier from source system |
| created_at | TIMESTAMP | Record creation timestamp |

## buyers

Stores buyer, agency, department, or purchasing owner data.

| Column | Type | Description |
|---|---|---|
| buyer_id | BIGINT | Primary key |
| buyer_name | TEXT | Buyer or agency name |
| buyer_department | TEXT | Department or sub-agency |
| buyer_region | TEXT | Buyer region |
| source_system | TEXT | Source system name |
| source_buyer_id | TEXT | Buyer identifier from source system |
| created_at | TIMESTAMP | Record creation timestamp |

## categories

Stores procurement category data.

| Column | Type | Description |
|---|---|---|
| category_id | BIGINT | Primary key |
| category_code | TEXT | Category code such as NAICS or PSC |
| category_name | TEXT | Category description |
| category_group | TEXT | Higher-level category grouping |
| source_system | TEXT | Source system name |
| created_at | TIMESTAMP | Record creation timestamp |

## purchase_orders

Stores purchase order header data.

| Column | Type | Description |
|---|---|---|
| po_id | BIGINT | Primary key |
| po_number | TEXT | Unique purchase order number |
| supplier_id | BIGINT | Foreign key to suppliers |
| buyer_id | BIGINT | Foreign key to buyers |
| category_id | BIGINT | Foreign key to categories |
| po_date | DATE | Purchase order date |
| required_delivery_date | DATE | Expected delivery date |
| po_status | TEXT | Purchase order status: open, closed, or cancelled |
| currency_code | CHAR(3) | Currency code |
| total_amount | NUMERIC | Total purchase order amount |
| source_award_id | TEXT | Public award identifier |
| source_system | TEXT | Source system name |
| created_at | TIMESTAMP | Record creation timestamp |

## purchase_order_lines

Stores line-level purchase order detail.

| Column | Type | Description |
|---|---|---|
| po_line_id | BIGINT | Primary key |
| po_id | BIGINT | Foreign key to purchase_orders |
| line_number | INTEGER | Line number within the purchase order |
| item_description | TEXT | Purchased item or service description |
| category_id | BIGINT | Foreign key to categories |
| quantity | NUMERIC | Ordered quantity |
| unit_price | NUMERIC | Unit price |
| line_amount | NUMERIC | Line amount |
| created_at | TIMESTAMP | Record creation timestamp |

## deliveries

Stores delivery performance by purchase order line.

| Column | Type | Description |
|---|---|---|
| delivery_id | BIGINT | Primary key |
| po_line_id | BIGINT | Foreign key to purchase_order_lines |
| scheduled_delivery_date | DATE | Planned delivery date |
| actual_delivery_date | DATE | Actual delivery date |
| delivery_status | TEXT | Delivery status: pending, delivered, late, or cancelled |
| delivered_quantity | NUMERIC | Delivered quantity |
| delay_days | INTEGER | Generated field: actual date minus scheduled date |
| created_at | TIMESTAMP | Record creation timestamp |

## invoices

Stores invoice data related to purchase orders.

| Column | Type | Description |
|---|---|---|
| invoice_id | BIGINT | Primary key |
| invoice_number | TEXT | Unique invoice number |
| po_id | BIGINT | Foreign key to purchase_orders |
| invoice_date | DATE | Invoice issue date |
| due_date | DATE | Invoice due date |
| payment_date | DATE | Payment date |
| invoice_status | TEXT | Invoice status: open, paid, overdue, or cancelled |
| invoice_amount | NUMERIC | Invoice amount |
| currency_code | CHAR(3) | Currency code |
| created_at | TIMESTAMP | Record creation timestamp |

## compliance_documents

Stores supplier compliance documentation.

| Column | Type | Description |
|---|---|---|
| document_id | BIGINT | Primary key |
| supplier_id | BIGINT | Foreign key to suppliers |
| document_type | TEXT | Compliance document type |
| document_status | TEXT | Document status: valid, expired, missing, or pending_review |
| issue_date | DATE | Document issue date |
| expiration_date | DATE | Document expiration date |
| reviewed_date | DATE | Last review date |
| reviewed_by | TEXT | Reviewer name or role |
| created_at | TIMESTAMP | Record creation timestamp |
