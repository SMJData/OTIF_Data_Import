# SMJ BI Pipeline

**S.M. Jaleel & Company Limited — Business Intelligence Department**

This repository contains the data pipeline infrastructure for the SMJ BI stack.

---

## Stack

| Layer | Tool |
|---|---|
| Data Warehouse | Supabase (PostgreSQL) |
| Transformation | dbt Core |
| Orchestration | Python + GitHub Actions |
| Reporting | Power BI |

---

## Repo Structure

```
smj-bi-pipeline/
├── .github/
│   └── workflows/
│       └── epicor_extract.yml   # Nightly GitHub Actions pipeline
├── pipelines/
│   └── extract_product_listing.py  # Epicor OData → Supabase
├── dbt/
│   ├── dbt_project.yml
│   ├── models/
│   │   ├── sources.yml
│   │   └── marts/
│   │       └── product_listing.sql
├── requirements.txt
├── .gitignore
└── README.md
```

---

## Implementation Steps

### Step 1 — Create schemas in Supabase

In the Supabase SQL Editor run:

```sql
create schema if not exists raw;
create schema if not exists marts;
```

### Step 2 — Add GitHub Secrets

Go to **Settings → Secrets and variables → Actions** in this repo and add:

| Secret | Value |
|---|---|
| `EPICOR_USER` | Your Epicor username |
| `EPICOR_PASS` | Your Epicor password |
| `SUPABASE_CONN` | `postgresql://postgres:[YOUR-PASSWORD]@db.rnlkdxwlvguvrmhapfmv.supabase.co:5432/postgres` |

> **Note:** `SUPABASE_CONN` is only stored in GitHub Secrets — never in code or committed to the repo.
> The `.env` file for local development is excluded by `.gitignore`.

### Step 3 — Trigger the pipeline manually

1. Go to the **Actions** tab in this repo
2. Click **Epicor Product Listing Extract**
3. Click **Run workflow → Run workflow**
4. Confirm the run completes with a green tick

### Step 4 — Verify data in Supabase

1. Go to your Supabase project
2. Click **Table Editor**
3. Confirm `product_listing` exists under the `raw` schema with rows populated

### Step 5 — Connect Power BI to Supabase

1. Open Power BI Desktop
2. **Get Data → PostgreSQL database**
3. Server: `db.rnlkdxwlvguvrmhapfmv.supabase.co`
4. Database: `postgres`
5. Select `raw.product_listing` for now — switch to `marts.product_listing` after dbt is configured

---

## Pipeline Schedule

The GitHub Actions workflow runs nightly at **3 AM UTC**.
It can also be triggered manually from the **Actions** tab in GitHub.

---

## Local Development (Codespaces)

Create a `.env` file in the root — this is excluded by `.gitignore` and must never be committed:

```
EPICOR_USER=your_epicor_username
EPICOR_PASS=your_epicor_password
SUPABASE_CONN=postgresql://postgres:[YOUR-PASSWORD]@db.rnlkdxwlvguvrmhapfmv.supabase.co:5432/postgres
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the pipeline manually:

```bash
python pipelines/extract_product_listing.py
```

---

## Security Notes

| Location | Safe? | Reason |
|---|---|---|
| GitHub Secrets | Yes | Encrypted, never exposed in logs or code |
| `.env` file locally | Yes | Excluded by `.gitignore` |
| Hardcoded in Python script | Never | Would be visible in repo |
| Committed to Git | Never | `.gitignore` prevents this |
