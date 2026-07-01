"""
Generate synthetic operational procurement data.

This script creates realistic operational records for:

- purchase_order_lines
- deliveries
- invoices
- compliance_documents

These records are synthetic and are generated from processed public procurement
award data. They are used only for portfolio demonstration and analytics.
"""

from __future__ import annotations

import hashlib
import random
from datetime import timedelta
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"

PURCHASE_ORDERS_CSV = PROCESSED_DIR / "purchase_orders.csv"
SUPPLIERS_CSV = PROCESSED_DIR / "suppliers.csv"

PO_LINES_CSV = PROCESSED_DIR / "purchase_order_lines.csv"
DELIVERIES_CSV = PROCESSED_DIR / "deliveries.csv"
INVOICES_CSV = PROCESSED_DIR / "invoices.csv"
COMPLIANCE_DOCUMENTS_CSV = PROCESSED_DIR / "compliance_documents.csv"

REFERENCE_DATE = pd.Timestamp("2026-07-01")


CATEGORY_ITEM_DESCRIPTIONS = {
    "CAT-AEROSPACE-DEFENSE": [
        "Aircraft systems support",
        "Defense platform components",
        "Aerospace engineering services",
        "Mission systems equipment",
        "Military program support",
    ],
    "CAT-LOGISTICS-TRANSPORTATION": [
        "Freight and logistics services",
        "Transportation support",
        "Warehouse and distribution services",
        "Fleet operations support",
        "Delivery and shipping services",
    ],
    "CAT-ENERGY-UTILITIES": [
        "Energy services",
        "Utility infrastructure support",
        "Power systems maintenance",
        "Environmental and energy operations",
        "Fuel and utility services",
    ],
    "CAT-HEALTHCARE-MEDICAL": [
        "Medical supplies",
        "Healthcare support services",
        "Clinical operations support",
        "Pharmaceutical supply services",
        "Laboratory services",
    ],
    "CAT-CONSTRUCTION-FACILITIES": [
        "Facility maintenance",
        "Construction services",
        "Building renovation support",
        "Infrastructure repair services",
        "Site operations support",
    ],
    "CAT-PROFESSIONAL-SERVICES": [
        "Consulting services",
        "Program management support",
        "Technical advisory services",
        "Business analysis support",
        "Project management services",
    ],
    "CAT-IT": [
        "Software services",
        "Cloud infrastructure support",
        "Cybersecurity services",
        "Data systems support",
        "IT operations support",
    ],
    "CAT-BPA-CALL-GENERAL": [
        "Blanket purchase agreement support",
        "General procurement support",
        "BPA service order",
    ],
    "CAT-DEFINITIVE-CONTRACT-GENERAL": [
        "General contract services",
        "Contract execution support",
        "General procurement services",
    ],
}


DOCUMENT_TYPES = [
    "NDA",
    "Insurance Certificate",
    "Quality Certification",
    "Sanctions Screening",
    "Supplier Onboarding Form",
    "Tax Document",
]


def deterministic_seed(*values: object) -> int:
    """Create a deterministic integer seed from input values."""
    joined_values = "|".join(str(value) for value in values)
    digest = hashlib.md5(joined_values.encode("utf-8")).hexdigest()
    return int(digest[:8], 16)


def get_rng(*values: object) -> random.Random:
    """Create a deterministic random generator."""
    return random.Random(deterministic_seed(*values))


def load_inputs() -> tuple[pd.DataFrame, pd.DataFrame]:
    """Load processed purchase orders and suppliers."""
    if not PURCHASE_ORDERS_CSV.exists():
        raise FileNotFoundError(
            f"Missing {PURCHASE_ORDERS_CSV}. Run python/02_transform_procurement_data.py first."
        )

    if not SUPPLIERS_CSV.exists():
        raise FileNotFoundError(
            f"Missing {SUPPLIERS_CSV}. Run python/02_transform_procurement_data.py first."
        )

    purchase_orders = pd.read_csv(PURCHASE_ORDERS_CSV)
    suppliers = pd.read_csv(SUPPLIERS_CSV)

    purchase_orders["po_date"] = pd.to_datetime(purchase_orders["po_date"])
    purchase_orders["required_delivery_date"] = pd.to_datetime(
        purchase_orders["required_delivery_date"]
    )
    purchase_orders["total_amount"] = pd.to_numeric(
        purchase_orders["total_amount"], errors="coerce"
    ).fillna(0)

    return purchase_orders, suppliers


def generate_purchase_order_lines(purchase_orders: pd.DataFrame) -> pd.DataFrame:
    """Generate synthetic purchase order line records."""
    records: list[dict[str, object]] = []

    for _, po in purchase_orders.iterrows():
        po_number = po["po_number"]
        category_code = po["category_code"]
        total_amount = float(po["total_amount"])

        rng = get_rng("po_lines", po_number)

        if total_amount <= 0:
            continue

        if total_amount >= 1_000_000_000:
            number_of_lines = rng.randint(3, 5)
        elif total_amount >= 100_000_000:
            number_of_lines = rng.randint(2, 4)
        else:
            number_of_lines = rng.randint(1, 3)

        weights = [rng.uniform(0.5, 2.0) for _ in range(number_of_lines)]
        weight_total = sum(weights)

        remaining_amount = round(total_amount, 2)

        item_pool = CATEGORY_ITEM_DESCRIPTIONS.get(
            category_code,
            ["General procurement item"],
        )

        for line_number in range(1, number_of_lines + 1):
            if line_number == number_of_lines:
                line_amount = remaining_amount
            else:
                line_amount = round(total_amount * (weights[line_number - 1] / weight_total), 2)
                remaining_amount = round(remaining_amount - line_amount, 2)

            quantity = rng.randint(1, 500)
            unit_price = round(line_amount / quantity, 2) if quantity else line_amount

            records.append(
                {
                    "po_number": po_number,
                    "line_number": line_number,
                    "item_description": rng.choice(item_pool),
                    "category_code": category_code,
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "line_amount": line_amount,
                }
            )

    return pd.DataFrame(records)


def generate_deliveries(po_lines: pd.DataFrame, purchase_orders: pd.DataFrame) -> pd.DataFrame:
    """Generate synthetic delivery records from purchase order lines."""
    po_lookup = purchase_orders.set_index("po_number").to_dict("index")
    records: list[dict[str, object]] = []

    for _, line in po_lines.iterrows():
        po_number = line["po_number"]
        line_number = int(line["line_number"])
        po = po_lookup[po_number]

        rng = get_rng("delivery", po_number, line_number)

        po_date = pd.Timestamp(po["po_date"])
        required_delivery_date = pd.Timestamp(po["required_delivery_date"])
        po_status = po["po_status"]

        scheduled_offset_days = rng.randint(15, 120)
        scheduled_delivery_date = po_date + timedelta(days=scheduled_offset_days)

        if scheduled_delivery_date > required_delivery_date:
            scheduled_delivery_date = required_delivery_date

        delivered_quantity = float(line["quantity"])

        late_probability = 0.18

        if po["category_code"] in ["CAT-AEROSPACE-DEFENSE", "CAT-ENERGY-UTILITIES"]:
            late_probability += 0.08

        if float(po["total_amount"]) >= 1_000_000_000:
            late_probability += 0.06

        is_late = rng.random() < late_probability

        if po_status == "closed":
            if is_late:
                actual_delivery_date = scheduled_delivery_date + timedelta(days=rng.randint(1, 45))
                delivery_status = "late"
            else:
                actual_delivery_date = scheduled_delivery_date - timedelta(days=rng.randint(0, 10))
                delivery_status = "delivered"

        else:
            pending_probability = 0.25

            if scheduled_delivery_date > REFERENCE_DATE:
                pending_probability += 0.35

            if rng.random() < pending_probability:
                actual_delivery_date = None
                delivery_status = "pending"
                delivered_quantity = 0
            else:
                if is_late:
                    actual_delivery_date = scheduled_delivery_date + timedelta(days=rng.randint(1, 45))
                    delivery_status = "late"
                else:
                    actual_delivery_date = scheduled_delivery_date - timedelta(days=rng.randint(0, 10))
                    delivery_status = "delivered"

        records.append(
            {
                "po_number": po_number,
                "line_number": line_number,
                "scheduled_delivery_date": scheduled_delivery_date.date(),
                "actual_delivery_date": (
                    actual_delivery_date.date() if actual_delivery_date is not None else ""
                ),
                "delivery_status": delivery_status,
                "delivered_quantity": round(delivered_quantity, 2),
            }
        )

    return pd.DataFrame(records)


def generate_invoices(purchase_orders: pd.DataFrame) -> pd.DataFrame:
    """Generate synthetic invoice records from purchase orders."""
    records: list[dict[str, object]] = []

    for _, po in purchase_orders.iterrows():
        po_number = po["po_number"]
        rng = get_rng("invoice", po_number)

        po_date = pd.Timestamp(po["po_date"])
        required_delivery_date = pd.Timestamp(po["required_delivery_date"])
        total_amount = round(float(po["total_amount"]), 2)

        invoice_date = po_date + timedelta(days=rng.randint(5, 45))
        due_date = invoice_date + timedelta(days=rng.choice([30, 45, 60]))

        invoice_number = f"INV-{po_number}"

        if po["po_status"] == "closed":
            if rng.random() < 0.88:
                payment_date = due_date - timedelta(days=rng.randint(0, 10))
                invoice_status = "paid"
            else:
                payment_date = due_date + timedelta(days=rng.randint(1, 45))
                invoice_status = "paid"
        else:
            if due_date < REFERENCE_DATE and rng.random() < 0.30:
                payment_date = ""
                invoice_status = "overdue"
            elif due_date < REFERENCE_DATE:
                payment_date = due_date - timedelta(days=rng.randint(0, 10))
                invoice_status = "paid"
            else:
                payment_date = ""
                invoice_status = "open"

        records.append(
            {
                "invoice_number": invoice_number,
                "po_number": po_number,
                "invoice_date": invoice_date.date(),
                "due_date": due_date.date(),
                "payment_date": payment_date.date() if hasattr(payment_date, "date") else "",
                "invoice_status": invoice_status,
                "invoice_amount": total_amount,
                "currency_code": "USD",
            }
        )

    return pd.DataFrame(records)


def generate_compliance_documents(suppliers: pd.DataFrame) -> pd.DataFrame:
    """Generate synthetic supplier compliance documents."""
    records: list[dict[str, object]] = []

    for _, supplier in suppliers.iterrows():
        source_supplier_id = supplier["source_supplier_id"]
        supplier_name = supplier["supplier_name"]

        for document_type in DOCUMENT_TYPES:
            rng = get_rng("compliance", source_supplier_id, document_type)

            status_roll = rng.random()

            if status_roll < 0.72:
                document_status = "valid"
            elif status_roll < 0.84:
                document_status = "expired"
            elif status_roll < 0.93:
                document_status = "pending_review"
            else:
                document_status = "missing"

            if document_status == "missing":
                issue_date = ""
                expiration_date = ""
                reviewed_date = ""
            else:
                issue_date_value = REFERENCE_DATE - timedelta(days=rng.randint(60, 900))

                if document_status == "expired":
                    expiration_date_value = REFERENCE_DATE - timedelta(days=rng.randint(1, 365))
                else:
                    expiration_date_value = REFERENCE_DATE + timedelta(days=rng.randint(30, 730))

                reviewed_date_value = REFERENCE_DATE - timedelta(days=rng.randint(0, 180))

                issue_date = issue_date_value.date()
                expiration_date = expiration_date_value.date()
                reviewed_date = reviewed_date_value.date()

            reviewed_by = rng.choice(
                [
                    "Procurement Compliance",
                    "Supplier Quality",
                    "Supply Chain Risk",
                    "Legal Department",
                    "Vendor Management",
                ]
            )

            records.append(
                {
                    "source_supplier_id": source_supplier_id,
                    "supplier_name": supplier_name,
                    "document_type": document_type,
                    "document_status": document_status,
                    "issue_date": issue_date,
                    "expiration_date": expiration_date,
                    "reviewed_date": reviewed_date,
                    "reviewed_by": reviewed_by,
                }
            )

    return pd.DataFrame(records)


def main() -> None:
    """Run synthetic operational data generation."""
    print("Starting synthetic operational data generation...")

    purchase_orders, suppliers = load_inputs()

    print(f"Purchase orders loaded: {len(purchase_orders):,}")
    print(f"Suppliers loaded: {len(suppliers):,}")

    po_lines = generate_purchase_order_lines(purchase_orders)
    deliveries = generate_deliveries(po_lines, purchase_orders)
    invoices = generate_invoices(purchase_orders)
    compliance_documents = generate_compliance_documents(suppliers)

    po_lines.to_csv(PO_LINES_CSV, index=False)
    deliveries.to_csv(DELIVERIES_CSV, index=False)
    invoices.to_csv(INVOICES_CSV, index=False)
    compliance_documents.to_csv(COMPLIANCE_DOCUMENTS_CSV, index=False)

    print("\nSynthetic data generation complete.")
    print(f"Purchase order lines: {len(po_lines):,} -> {PO_LINES_CSV}")
    print(f"Deliveries: {len(deliveries):,} -> {DELIVERIES_CSV}")
    print(f"Invoices: {len(invoices):,} -> {INVOICES_CSV}")
    print(f"Compliance documents: {len(compliance_documents):,} -> {COMPLIANCE_DOCUMENTS_CSV}")

    print("\nDelivery status distribution:")
    print(deliveries["delivery_status"].value_counts().to_string())

    print("\nInvoice status distribution:")
    print(invoices["invoice_status"].value_counts().to_string())

    print("\nCompliance status distribution:")
    print(compliance_documents["document_status"].value_counts().to_string())


if __name__ == "__main__":
    main()
