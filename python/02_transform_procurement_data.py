"""
Transform raw USAspending award data into processed procurement model CSV files.

This script creates processed CSV files for:

- suppliers
- buyers
- categories
- purchase_orders

Public procurement award data is used as the source foundation.
Some procurement model fields are derived or normalized to make the dataset
usable for portfolio-grade procurement analytics.
"""

from __future__ import annotations

import hashlib
from pathlib import Path

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]

RAW_CSV = PROJECT_ROOT / "data" / "raw" / "usaspending_awards_2025_2026.csv"
PROCESSED_DIR = PROJECT_ROOT / "data" / "processed"
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

SUPPLIERS_CSV = PROCESSED_DIR / "suppliers.csv"
BUYERS_CSV = PROCESSED_DIR / "buyers.csv"
CATEGORIES_CSV = PROCESSED_DIR / "categories.csv"
PURCHASE_ORDERS_CSV = PROCESSED_DIR / "purchase_orders.csv"

REFERENCE_DATE = pd.Timestamp("2026-07-01")
ANALYSIS_START_DATE = pd.Timestamp("2025-01-01")
ANALYSIS_END_DATE = pd.Timestamp("2026-12-31")


def clean_text(value: object) -> str:
    """Return a clean string value."""
    if pd.isna(value):
        return ""

    return str(value).strip()


def clean_code(value: object) -> str:
    """Clean codes that may be read as numeric values."""
    text = clean_text(value)

    if not text:
        return ""

    if text.endswith(".0"):
        text = text[:-2]

    return text.strip()


def stable_id(prefix: str, *values: object) -> str:
    """Create a stable deterministic source identifier."""
    joined_values = "|".join(clean_text(value).upper() for value in values)
    digest = hashlib.md5(joined_values.encode("utf-8")).hexdigest()[:12]
    return f"{prefix}-{digest}"


def derive_category(
    description: str,
    award_type: str,
    naics_description: str,
    recipient_name: str,
    awarding_agency: str,
    awarding_sub_agency: str,
) -> tuple[str, str, str]:
    """Derive a portfolio-friendly procurement category from available text fields."""
    combined_text = (
        f"{description} {award_type} {naics_description} "
        f"{recipient_name} {awarding_agency} {awarding_sub_agency}"
    ).lower()

    category_rules = [
        (
            "CAT-AEROSPACE-DEFENSE",
            "Aerospace & Defense",
            "Aerospace, defense, weapons systems, aircraft, missiles, and military platforms",
            [
                "aircraft",
                "aerospace",
                "missile",
                "rocket",
                "defense",
                "navy",
                "army",
                "air force",
                "weapon",
                "weapons",
                "radar",
                "submarine",
                "space",
                "satellite",
                "munition",
            ],
        ),
        (
            "CAT-IT",
            "Information Technology",
            "Software, cloud, cybersecurity, telecommunications, and IT services",
            [
                "software",
                "information technology",
                "cyber",
                "cloud",
                "computer",
                "network",
                "data",
                "database",
                "telecommunication",
                "digital",
                "it ",
                "systems",
            ],
        ),
        (
            "CAT-CONSTRUCTION-FACILITIES",
            "Construction & Facilities",
            "Construction, renovation, maintenance, and facility services",
            [
                "construction",
                "building",
                "facility",
                "facilities",
                "renovation",
                "repair",
                "maintenance",
                "infrastructure",
                "civil",
                "engineering services",
            ],
        ),
        (
            "CAT-HEALTHCARE-MEDICAL",
            "Healthcare & Medical",
            "Medical supplies, healthcare services, pharmaceuticals, and clinical support",
            [
                "medical",
                "health",
                "hospital",
                "pharmaceutical",
                "vaccine",
                "clinical",
                "patient",
                "dental",
                "laboratory",
                "medicare",
                "medicaid",
            ],
        ),
        (
            "CAT-PROFESSIONAL-SERVICES",
            "Professional Services",
            "Consulting, program management, technical assistance, and advisory services",
            [
                "consulting",
                "professional",
                "advisory",
                "technical assistance",
                "program management",
                "project management",
                "management support",
                "analysis",
                "research",
                "engineering",
            ],
        ),
        (
            "CAT-LOGISTICS-TRANSPORTATION",
            "Logistics & Transportation",
            "Transportation, freight, logistics, warehousing, and distribution",
            [
                "transportation",
                "logistics",
                "freight",
                "shipping",
                "warehouse",
                "warehousing",
                "distribution",
                "delivery",
                "vehicle",
                "fleet",
            ],
        ),
        (
            "CAT-ENERGY-UTILITIES",
            "Energy & Utilities",
            "Energy, electricity, fuel, utilities, and environmental services",
            [
                "energy",
                "electric",
                "electricity",
                "fuel",
                "utility",
                "utilities",
                "power",
                "environmental",
                "water",
                "gas",
                "nuclear",
            ],
        ),
        (
            "CAT-MANUFACTURING-INDUSTRIAL",
            "Manufacturing & Industrial",
            "Manufacturing, industrial equipment, machinery, parts, and materials",
            [
                "manufacturing",
                "industrial",
                "machinery",
                "equipment",
                "parts",
                "materials",
                "components",
                "production",
                "tooling",
                "fabrication",
            ],
        ),
        (
            "CAT-ADMIN-SERVICES",
            "Administrative Services",
            "Administrative, staffing, office, records, and general support services",
            [
                "administrative",
                "staffing",
                "office",
                "clerical",
                "records",
                "document",
                "support services",
                "call center",
            ],
        ),
    ]

    for category_code, category_name, category_group, keywords in category_rules:
        if any(keyword in combined_text for keyword in keywords):
            return category_code, category_name, category_group

    if "delivery order" in combined_text:
        return (
            "CAT-DELIVERY-ORDER-GENERAL",
            "Delivery Order - General",
            "General delivery order contracts without specific category detail",
        )

    if "definitive contract" in combined_text:
        return (
            "CAT-DEFINITIVE-CONTRACT-GENERAL",
            "Definitive Contract - General",
            "General definitive contracts without specific category detail",
        )

    if "bpa call" in combined_text:
        return (
            "CAT-BPA-CALL-GENERAL",
            "BPA Call - General",
            "General blanket purchase agreement calls",
        )

    return (
        "CAT-OTHER",
        "Other / Uncategorized",
        "Other or uncategorized procurement",
    )


def deterministic_analysis_date(source_value: str) -> pd.Timestamp:
    """
    Generate a deterministic portfolio analysis date between 2025-01-01 and 2026-12-31.

    The raw public award may have an old start date while still having activity in the
    selected analysis period. This normalized date is used as the modeled PO date for
    procurement analytics.
    """
    digest = hashlib.md5(source_value.encode("utf-8")).hexdigest()
    day_offset = int(digest[:8], 16) % ((ANALYSIS_END_DATE - ANALYSIS_START_DATE).days + 1)
    return ANALYSIS_START_DATE + pd.Timedelta(days=day_offset)


def load_raw_data() -> pd.DataFrame:
    """Load and validate the raw USAspending CSV."""
    if not RAW_CSV.exists():
        raise FileNotFoundError(
            f"Raw data file not found: {RAW_CSV}. "
            "Run python/01_extract_usaspending_data.py first."
        )

    df = pd.read_csv(RAW_CSV, dtype=str)

    required_columns = [
        "Award ID",
        "Recipient Name",
        "Start Date",
        "End Date",
        "Award Amount",
        "Awarding Agency",
        "Awarding Sub Agency",
        "Contract Award Type",
        "Award Description",
        "NAICS Code",
        "NAICS Description",
    ]

    missing_columns = [column for column in required_columns if column not in df.columns]

    if missing_columns:
        raise ValueError(f"Missing required columns: {missing_columns}")

    return df


def prepare_clean_awards(raw_df: pd.DataFrame) -> pd.DataFrame:
    """Clean and enrich raw award records."""
    df = raw_df.copy()

    df["recipient_name_clean"] = df["Recipient Name"].apply(clean_text)
    df["award_id_clean"] = df["Award ID"].apply(clean_text)
    df["awarding_agency_clean"] = df["Awarding Agency"].apply(clean_text)
    df["awarding_sub_agency_clean"] = df["Awarding Sub Agency"].apply(clean_text)
    df["contract_award_type_clean"] = df["Contract Award Type"].apply(clean_text)
    df["award_description_clean"] = df["Award Description"].apply(clean_text)
    df["naics_code_clean"] = df["NAICS Code"].apply(clean_code)
    df["naics_description_clean"] = df["NAICS Description"].apply(clean_text)

    df["award_amount_numeric"] = pd.to_numeric(df["Award Amount"], errors="coerce").fillna(0)

    df["raw_start_date"] = pd.to_datetime(df["Start Date"], errors="coerce")
    df["raw_end_date"] = pd.to_datetime(df["End Date"], errors="coerce")

    df = df[df["recipient_name_clean"] != ""].copy()
    df = df[df["award_id_clean"] != ""].copy()
    df = df[df["awarding_agency_clean"] != ""].copy()
    df = df[df["award_amount_numeric"] > 0].copy()

    df["source_supplier_id"] = df["recipient_name_clean"].apply(
        lambda value: stable_id("SUP", value)
    )

    df["source_buyer_id"] = df.apply(
        lambda row: stable_id(
            "BUY",
            row["awarding_agency_clean"],
            row["awarding_sub_agency_clean"],
        ),
        axis=1,
    )

    derived_categories = df.apply(
        lambda row: derive_category(
            row["award_description_clean"],
            row["contract_award_type_clean"],
            row["naics_description_clean"],
            row["recipient_name_clean"],
            row["awarding_agency_clean"],
            row["awarding_sub_agency_clean"],
        ),
        axis=1,
    )

    df["category_code_final"] = [item[0] for item in derived_categories]
    df["category_name_final"] = [item[1] for item in derived_categories]
    df["category_group_final"] = [item[2] for item in derived_categories]

    df["po_number_base"] = df["award_id_clean"]
    duplicate_mask = df["po_number_base"].duplicated(keep=False)
    df["po_duplicate_rank"] = df.groupby("po_number_base").cumcount() + 1
    df["po_number"] = df["po_number_base"]

    df.loc[duplicate_mask, "po_number"] = (
        df.loc[duplicate_mask, "po_number_base"]
        + "-"
        + df.loc[duplicate_mask, "po_duplicate_rank"].astype(str)
    )

    df["po_date_normalized"] = df["po_number"].apply(deterministic_analysis_date)

    df["required_delivery_date_normalized"] = (
        df["po_date_normalized"]
        + pd.to_timedelta(
            30 + (df["po_number"].apply(lambda value: int(hashlib.md5(value.encode("utf-8")).hexdigest()[8:10], 16) % 150)),
            unit="D",
        )
    )

    df["po_status"] = "open"
    df.loc[df["required_delivery_date_normalized"] < REFERENCE_DATE, "po_status"] = "closed"

    df = df.sort_values(
        by=["award_amount_numeric", "po_date_normalized"],
        ascending=[False, False],
    ).reset_index(drop=True)

    return df


def build_suppliers(clean_df: pd.DataFrame) -> pd.DataFrame:
    """Build suppliers table data."""
    suppliers = clean_df[
        [
            "source_supplier_id",
            "recipient_name_clean",
        ]
    ].drop_duplicates()

    suppliers = suppliers.rename(
        columns={
            "recipient_name_clean": "supplier_name",
        }
    )

    suppliers["supplier_country"] = ""
    suppliers["supplier_state"] = ""
    suppliers["supplier_city"] = ""
    suppliers["supplier_type"] = "Public Procurement Recipient"
    suppliers["is_active"] = True
    suppliers["source_system"] = "USAspending"

    suppliers = suppliers[
        [
            "supplier_name",
            "supplier_country",
            "supplier_state",
            "supplier_city",
            "supplier_type",
            "is_active",
            "source_system",
            "source_supplier_id",
        ]
    ].sort_values("supplier_name")

    return suppliers


def build_buyers(clean_df: pd.DataFrame) -> pd.DataFrame:
    """Build buyers table data."""
    buyers = clean_df[
        [
            "source_buyer_id",
            "awarding_agency_clean",
            "awarding_sub_agency_clean",
        ]
    ].drop_duplicates()

    buyers = buyers.rename(
        columns={
            "awarding_agency_clean": "buyer_name",
            "awarding_sub_agency_clean": "buyer_department",
        }
    )

    buyers["buyer_region"] = "United States Federal Government"
    buyers["source_system"] = "USAspending"

    buyers = buyers[
        [
            "buyer_name",
            "buyer_department",
            "buyer_region",
            "source_system",
            "source_buyer_id",
        ]
    ].sort_values(["buyer_name", "buyer_department"])

    return buyers


def build_categories(clean_df: pd.DataFrame) -> pd.DataFrame:
    """Build categories table data."""
    categories = clean_df[
        [
            "category_code_final",
            "category_name_final",
            "category_group_final",
        ]
    ].drop_duplicates()

    categories = categories.rename(
        columns={
            "category_code_final": "category_code",
            "category_name_final": "category_name",
            "category_group_final": "category_group",
        }
    )

    categories["source_system"] = "Derived from USAspending text fields"

    categories = categories[
        [
            "category_code",
            "category_name",
            "category_group",
            "source_system",
        ]
    ].sort_values(["category_group", "category_name"])

    return categories


def build_purchase_orders(clean_df: pd.DataFrame) -> pd.DataFrame:
    """Build purchase order header data."""
    purchase_orders = pd.DataFrame(
        {
            "po_number": clean_df["po_number"],
            "source_supplier_id": clean_df["source_supplier_id"],
            "source_buyer_id": clean_df["source_buyer_id"],
            "category_code": clean_df["category_code_final"],
            "po_date": clean_df["po_date_normalized"].dt.date,
            "required_delivery_date": clean_df["required_delivery_date_normalized"].dt.date,
            "po_status": clean_df["po_status"],
            "currency_code": "USD",
            "total_amount": clean_df["award_amount_numeric"].round(2),
            "source_award_id": clean_df["award_id_clean"],
            "source_system": "USAspending + derived procurement model",
        }
    )

    return purchase_orders


def main() -> None:
    """Run transformation pipeline."""
    print("Starting procurement data transformation...")

    raw_df = load_raw_data()
    print(f"Raw rows loaded: {len(raw_df):,}")

    clean_df = prepare_clean_awards(raw_df)
    print(f"Clean award rows retained: {len(clean_df):,}")

    suppliers = build_suppliers(clean_df)
    buyers = build_buyers(clean_df)
    categories = build_categories(clean_df)
    purchase_orders = build_purchase_orders(clean_df)

    suppliers.to_csv(SUPPLIERS_CSV, index=False)
    buyers.to_csv(BUYERS_CSV, index=False)
    categories.to_csv(CATEGORIES_CSV, index=False)
    purchase_orders.to_csv(PURCHASE_ORDERS_CSV, index=False)

    print("\nTransformation complete.")
    print(f"Suppliers: {len(suppliers):,} -> {SUPPLIERS_CSV}")
    print(f"Buyers: {len(buyers):,} -> {BUYERS_CSV}")
    print(f"Categories: {len(categories):,} -> {CATEGORIES_CSV}")
    print(f"Purchase orders: {len(purchase_orders):,} -> {PURCHASE_ORDERS_CSV}")

    print("\nCategory distribution:")
    print(purchase_orders["category_code"].value_counts().to_string())

    print("\nPO date range:")
    print(f"Min PO date: {purchase_orders['po_date'].min()}")
    print(f"Max PO date: {purchase_orders['po_date'].max()}")


if __name__ == "__main__":
    main()
