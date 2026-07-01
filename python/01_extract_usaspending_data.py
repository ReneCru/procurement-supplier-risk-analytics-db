"""
Extract public procurement award data from USAspending.gov.

This script queries the USAspending Advanced Award Search endpoint and saves
a raw CSV file that will be transformed into the procurement analytics model.

Source:
https://api.usaspending.gov/api/v2/search/spending_by_award/
"""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

import pandas as pd
import requests


API_URL = "https://api.usaspending.gov/api/v2/search/spending_by_award/"

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DATA_DIR = PROJECT_ROOT / "data" / "raw"
RAW_DATA_DIR.mkdir(parents=True, exist_ok=True)

OUTPUT_CSV = RAW_DATA_DIR / "usaspending_awards_2025_2026.csv"
OUTPUT_JSON_SAMPLE = RAW_DATA_DIR / "usaspending_awards_2025_2026_sample.json"

START_DATE = "2025-01-01"
END_DATE = "2026-12-31"

# Contract-related award type codes.
# A/B/C/D are commonly used for procurement contract awards in USAspending filters.
AWARD_TYPE_CODES = ["A", "B", "C", "D"]

FIELDS = [
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
    "Place of Performance City Code",
    "Place of Performance State Code",
    "Place of Performance Country Code",
]

MAX_PAGES = 5
PAGE_LIMIT = 100


def build_payload(page: int) -> dict[str, Any]:
    """Build the POST payload for the USAspending API request."""
    return {
        "filters": {
            "time_period": [
                {
                    "start_date": START_DATE,
                    "end_date": END_DATE,
                }
            ],
            "award_type_codes": AWARD_TYPE_CODES,
        },
        "fields": FIELDS,
        "page": page,
        "limit": PAGE_LIMIT,
        "sort": "Award Amount",
        "order": "desc",
        "subawards": False,
    }


def fetch_page(page: int) -> dict[str, Any]:
    """Fetch one result page from USAspending."""
    payload = build_payload(page)

    response = requests.post(API_URL, json=payload, timeout=60)

    if response.status_code != 200:
        raise RuntimeError(
            f"USAspending API request failed. "
            f"Status code: {response.status_code}. "
            f"Response text: {response.text[:1000]}"
        )

    return response.json()


def extract_results(response_json: dict[str, Any]) -> list[dict[str, Any]]:
    """Extract results from the API response."""
    results = response_json.get("results", [])

    if not isinstance(results, list):
        raise ValueError("Unexpected API response format: 'results' is not a list.")

    return results


def main() -> None:
    """Run the extraction process."""
    all_results: list[dict[str, Any]] = []

    print("Starting USAspending extraction...")
    print(f"Date range: {START_DATE} to {END_DATE}")
    print(f"Max pages: {MAX_PAGES}")
    print(f"Page limit: {PAGE_LIMIT}")

    first_response: dict[str, Any] | None = None

    for page in range(1, MAX_PAGES + 1):
        print(f"Fetching page {page}...")

        response_json = fetch_page(page)

        if page == 1:
            first_response = response_json

        page_results = extract_results(response_json)

        if not page_results:
            print("No more results returned by API.")
            break

        all_results.extend(page_results)

        print(f"Page {page}: {len(page_results)} records")

        # Be polite with the public API.
        time.sleep(0.5)

    if not all_results:
        raise RuntimeError("No data was returned from USAspending.")

    df = pd.DataFrame(all_results)

    df.to_csv(OUTPUT_CSV, index=False)

    if first_response is not None:
        with OUTPUT_JSON_SAMPLE.open("w", encoding="utf-8") as file:
            json.dump(first_response, file, indent=2)

    print("\nExtraction complete.")
    print(f"Rows extracted: {len(df):,}")
    print(f"Columns extracted: {len(df.columns)}")
    print(f"CSV saved to: {OUTPUT_CSV}")
    print(f"Sample JSON saved to: {OUTPUT_JSON_SAMPLE}")
    print("\nColumns:")
    for column in df.columns:
        print(f"- {column}")


if __name__ == "__main__":
    main()
