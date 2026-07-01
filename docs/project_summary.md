# Project Summary: Procurement & Supplier Risk Analytics Database

## One-Line Summary

A PostgreSQL procurement analytics database that uses public procurement data and synthetic operational records to analyze supplier spend, late deliveries, compliance status, invoices, open purchase orders, and supplier risk.

## Business Context

Procurement and supply chain teams need visibility into supplier performance, spend exposure, open purchase orders, invoice status, and compliance risk.

This project models a realistic procurement analytics environment without using confidential company data.

## What the Project Solves

The database answers questions such as:

- Which suppliers represent the highest spend exposure?
- Which suppliers have the most late deliveries?
- Which purchase orders are open and aging?
- Which suppliers have expired or missing compliance documents?
- Which procurement categories drive the most spend?
- How is purchasing activity trending month over month?
- Which suppliers should be prioritized for risk review?

## Data Sources

The project uses public procurement award data from USAspending.gov as the source foundation.

Public data is used for:

- supplier names;
- buyer or agency names;
- award identifiers;
- award amounts;
- public award descriptions;
- contract-related dates.

Synthetic data is generated for:

- purchase order lines;
- deliveries;
- invoices;
- compliance documents.

## Why Synthetic Operational Data Was Used

Private-sector delivery records, invoice data, and compliance documentation usually live inside ERP systems such as SAP, Oracle, Coupa, Ariba, or NetSuite.

Those records are not publicly available and should not be extracted from an employer without authorization.

Synthetic operational data allows the project to demonstrate realistic procurement analytics while avoiding confidential data.

## Technical Scope

The project includes:

- relational database design;
- primary keys and foreign keys;
- data quality constraints;
- analytical indexes;
- CSV extraction and transformation;
- synthetic data generation;
- PostgreSQL data loading;
- SQL business views;
- KPI queries;
- ERD documentation;
- saved KPI outputs.

## Core Database Tables

- suppliers
- buyers
- categories
- purchase_orders
- purchase_order_lines
- deliveries
- invoices
- compliance_documents

## Key Business Views

- vw_supplier_spend_summary
- vw_spend_by_category
- vw_monthly_purchasing_trend
- vw_late_delivery_performance
- vw_open_po_aging
- vw_supplier_compliance_status
- vw_supplier_risk_score

## Main KPIs

- Top suppliers by total spend
- Suppliers with most late deliveries
- Open purchase orders by aging bucket
- Suppliers with expired or missing compliance documents
- Spend by category
- Monthly purchasing trend
- Supplier risk score
- Overdue invoice exposure
- Buyer spend summary
- Executive procurement summary

## Dataset Size

| Table | Rows |
|---|---:|
| suppliers | 165 |
| buyers | 24 |
| categories | 9 |
| purchase_orders | 500 |
| purchase_order_lines | 1,982 |
| deliveries | 1,982 |
| invoices | 500 |
| compliance_documents | 990 |

## Tools Used

- PostgreSQL
- SQL
- Python
- Pandas
- Requests
- GitHub Codespaces
- GitHub
- Graphviz

## Resume Bullet

Designed a PostgreSQL relational database using public procurement data to analyze supplier spend, purchase orders, delivery performance, invoices, compliance document status, and supplier risk scoring. Built SQL views and KPI queries for spend analysis, late deliveries, open PO aging, expired documents, monthly trends, and supplier risk prioritization.

## Interview Explanation

I built this project to show how procurement data can be modeled, cleaned, loaded, and analyzed in a relational database. The project uses real public procurement award data as the foundation and synthetic operational data to simulate private-sector workflows such as deliveries, invoices, and compliance document tracking.

The result is a portfolio-ready database that connects SQL, procurement analytics, supplier performance, and compliance risk.
