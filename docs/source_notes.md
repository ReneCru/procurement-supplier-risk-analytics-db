# Source Notes

## Primary Data Source

The primary public data source for this project is USAspending.gov.

USAspending.gov is the official open data source for U.S. federal spending information. The project uses public procurement award data as the foundation for supplier, buyer, category, award date, and spend fields.

Official source:
https://www.usaspending.gov/

Official API documentation:
https://api.usaspending.gov/docs/

Advanced award search endpoint:
https://api.usaspending.gov/api/v2/search/spending_by_award/

## Why Public Procurement Data Is Used

Private-sector procurement systems usually store detailed purchase orders, delivery records, invoices, and compliance documents inside ERP platforms such as SAP, Oracle, Coupa, Ariba, or NetSuite.

Those operational records are not publicly available and should not be extracted from an employer without explicit authorization.

This project avoids confidential company information by using public procurement award data as the source of truth for:

- suppliers;
- buyers/agencies;
- categories;
- contract or award dates;
- award amounts;
- public procurement descriptions.

## Synthetic Operational Data

The following tables contain synthetic operational records generated for portfolio demonstration:

- purchase_order_lines;
- deliveries;
- invoices;
- compliance_documents.

These records are generated using documented business rules to simulate a realistic procurement analytics environment.

## Important Data Ethics Statement

This project does not use confidential employer data.

Any operational performance fields such as late deliveries, invoice status, or internal compliance document status are synthetic and generated only for demonstration purposes.

## Planned Future Extension

A future version may include Mexico or Chihuahua public procurement data as a regional sourcing extension. This would make the project more relevant for Mexico-based procurement and compliance analytics while preserving the same relational database model.
