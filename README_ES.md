# Base de Datos de Procurement y Riesgo de Proveedores

## Resumen del Proyecto

Este proyecto construye una base de datos relacional en PostgreSQL para analizar procurement, desempeño de proveedores y riesgo de compliance.

El modelo analiza proveedores, órdenes de compra, líneas de órdenes de compra, entregas, facturas, compradores, categorías, documentos de compliance y score de riesgo de proveedores.

El proyecto usa datos públicos de USAspending.gov como base y genera datos operativos sintéticos para simular entregas, facturas y documentos de compliance que normalmente no están disponibles públicamente.

## Problema de Negocio

Los equipos de compras, supply chain y compliance necesitan visibilidad sobre:

- gasto por proveedor;
- riesgo de entregas tardías;
- órdenes de compra abiertas por antigüedad;
- facturas abiertas o vencidas;
- documentos de compliance vencidos o faltantes;
- gasto por categoría;
- tendencias mensuales de compra;
- priorización de proveedores por nivel de riesgo.

Este proyecto convierte datos públicos de procurement en indicadores de negocio útiles para análisis de proveedores, planeación de compras, monitoreo de compliance y reportes ejecutivos.

## Estrategia de Datos

Los datos públicos de USAspending se usan para:

- proveedores;
- compradores/agencias;
- identificadores de contratos;
- montos;
- descripciones;
- fechas;
- categorías derivadas de campos públicos.

Las siguientes tablas operativas son sintéticas:

- purchase_order_lines
- deliveries
- invoices
- compliance_documents

Estos datos son sintéticos porque en una empresa real normalmente viven dentro de sistemas ERP como SAP, Oracle, Coupa, Ariba o NetSuite.

## Uso Ético de Datos

Este proyecto no utiliza información confidencial de ninguna empresa.

Los datos de entregas, facturas, compliance y riesgo de proveedores son sintéticos y se generaron únicamente para demostración de portafolio.

## Tablas Principales

- suppliers
- buyers
- categories
- purchase_orders
- purchase_order_lines
- deliveries
- invoices
- compliance_documents

## Vistas de Negocio

- vw_supplier_spend_summary
- vw_spend_by_category
- vw_monthly_purchasing_trend
- vw_late_delivery_performance
- vw_open_po_aging
- vw_supplier_compliance_status
- vw_supplier_risk_score

## Consultas KPI

El proyecto incluye consultas para:

1. Proveedores con mayor gasto total
2. Proveedores con más entregas tardías
3. Órdenes de compra abiertas por antigüedad
4. Proveedores con documentos vencidos o faltantes
5. Gasto por categoría
6. Tendencia mensual de compras
7. Score de riesgo de proveedor
8. Facturas vencidas
9. Gasto por comprador/agencia
10. Resumen ejecutivo de procurement

## Tecnologías

- PostgreSQL
- SQL
- Python
- Pandas
- Requests
- GitHub Codespaces
- GitHub

## Cómo Ejecutar el Proyecto

Instalar dependencias:

python -m pip install -r requirements.txt

Extraer datos públicos:

python python/01_extract_usaspending_data.py

Transformar datos raw:

python python/02_transform_procurement_data.py

Generar datos operativos sintéticos:

python python/03_generate_synthetic_operations.py

Crear tablas en PostgreSQL:

psql postgresql://procurement_user:procurement_pass@db:5432/procurement_analytics -f sql/01_create_tables.sql

Agregar restricciones e índices:

psql postgresql://procurement_user:procurement_pass@db:5432/procurement_analytics -f sql/03_constraints_indexes.sql

Cargar datos procesados:

psql postgresql://procurement_user:procurement_pass@db:5432/procurement_analytics -f sql/02_load_data.sql

Crear vistas de negocio:

psql postgresql://procurement_user:procurement_pass@db:5432/procurement_analytics -f sql/04_business_views.sql

Ejecutar consultas KPI:

psql postgresql://procurement_user:procurement_pass@db:5432/procurement_analytics -f sql/05_kpi_queries.sql

## Resumen del Dataset

| Tabla | Filas |
|---|---:|
| suppliers | 165 |
| buyers | 24 |
| categories | 9 |
| purchase_orders | 500 |
| purchase_order_lines | 1,982 |
| deliveries | 1,982 |
| invoices | 500 |
| compliance_documents | 990 |

## Resumen para CV

Diseñé una base de datos relacional en PostgreSQL usando datos públicos de procurement para analizar gasto por proveedor, órdenes de compra, desempeño de entregas, facturas, documentos de compliance y score de riesgo de proveedores. Construí vistas SQL y consultas KPI para análisis de gasto, entregas tardías, aging de órdenes abiertas, documentos vencidos, tendencias mensuales y priorización de riesgo de proveedores.

## Explicación para Entrevista

Este proyecto demuestra capacidad para diseñar una base de datos relacional, transformar datos públicos en un modelo de negocio, generar datos operativos sintéticos realistas, aplicar restricciones de calidad, optimizar consultas con índices y construir KPIs de procurement orientados a análisis de riesgo de proveedores.
