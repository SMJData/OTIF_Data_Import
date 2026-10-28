# SMJ Export Orders BI Pipeline

**S.M. Jaleel & Company Limited — Business Intelligence Department**

Extracts three Epicor BAQs for **export orders**, loads their results into Supabase (PostgreSQL), and provides dbt models for Power BI reporting.

## BAQ list

| Epicor BAQ | Purpose | Supabase table | dbt reporting table |
|---|---|---|---|
| `OntimeDelivery` | OTIF tracking: Late, Early, Ontime | `public.ontime_delivery` | `gold.ontime_delivery` |
| `SupplyChain` | Tracking: Ready to Invoice, All Orders, Cancelled Orders, Invoiced Orders, Shipped Orders but not invoiced, Open Orders | `public.supply_chain` | `gold.supply_chain` |
| `z_SO02-SC` | Week-wise sales orders by part, description, brand, pack size, and case configuration | `public.z_so02_sc` | `gold.z_so02_sc` |

BAQ names are sent to Epicor exactly as listed, including case and the hyphen in `z_SO02-SC`. Destination table names use lowercase snake_case. All three BAQs must be scoped to export orders in Epicor; the extractor loads every returned row without adding an export-order filter.

## Repository structure

```text
GRR_Data_Import/
├── .github/workflows/extract_export_orders.yml
├── pipelines/extract_export_orders.py
├── dbt/
│   ├── dbt_project.yml
│   ├── macros/generate_schema_name.sql
│   └── models/
│       ├── sources.yml
│       ├── staging/
│       │   ├── stg_ontime_delivery.sql
│       │   ├── stg_supply_chain.sql
│       │   └── stg_z_so02_sc.sql
│       └── marts/
│           ├── ontime_delivery.sql
│           ├── supply_chain.sql
│           └── z_so02_sc.sql
├── requirements.txt
├── .gitignore
└── README.md
```

## Setup and extraction

1. Ensure the Epicor account can access all three export-order BAQs.
2. Add these repository secrets under **Settings → Secrets and variables → Actions**:

   | Secret | Value |
   |---|---|
   | `EPICOR_USER` | Epicor username |
   | `EPICOR_PASS` | Epicor password |
   | `SUPABASE_CONN` | PostgreSQL connection URL for your Supabase database |

3. Ensure the database account can create and replace tables in the `public` schema.
4. Open **Actions → Epicor Export Orders Extract → Run workflow**.
5. Verify the three `public` tables listed above in Supabase's Table Editor.

The workflow is **manual only** (`workflow_dispatch`); no recurring schedule is configured.

The extractor fetches all OData pages and processes up to three BAQs concurrently. For each BAQ it normalizes column names to lowercase snake_case, loads a temporary staging table, checks row counts, and replaces the destination table in a transaction. Empty BAQ results or failed staging validation leave that BAQ's existing destination table intact. A failure in one BAQ does not roll back successful loads of other BAQs; the workflow reports failure if any BAQ fails.

The new table names do not rename or delete previously loaded tables. Update downstream reports to use the export-order tables above.

## Local development

Create a root `.env` file (excluded by `.gitignore`):

```dotenv
EPICOR_USER=your_epicor_username
EPICOR_PASS=your_epicor_password
SUPABASE_CONN=postgresql://postgres:YOUR_PASSWORD@YOUR_SUPABASE_HOST:5432/postgres
```

Install dependencies and run the extractor:

```bash
pip install -r requirements.txt
python pipelines/extract_export_orders.py
```

Keep credentials in GitHub Secrets or the local `.env` file; never commit them.

## dbt and Power BI

The dbt sources point to the extractor's `public` tables. Staging models create views in `silver`; reporting models create tables in `gold`. These models currently pass through BAQ columns without calculating OTIF, reclassifying order statuses, or aggregating weekly sales. Those transformations require confirmed BAQ fields and business rules.

Install dbt separately (`pip install dbt-postgres`), configure a local `smj_bi` profile in `~/.dbt/profiles.yml` for the same database, and ensure its database account can create schemas and build models in `silver` and `gold`. Then run:

```bash
cd dbt
dbt build
```

The GitHub Actions workflow runs extraction only; it does not run dbt. Generated dbt output and logs are excluded from version control.

In Power BI Desktop, use **Get Data → PostgreSQL database**, enter your Supabase host and database, and select the three `gold` reporting tables after building dbt. The `public` tables can be used directly before dbt is configured.
