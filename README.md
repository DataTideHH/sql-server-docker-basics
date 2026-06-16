# SQL Server Docker Basics

**Microsoft SQL Server 2022 · Docker Desktop · SQL practice · DataGrip workflow · Data/BI learning path**

This repository documents a local Microsoft SQL Server setup for learning relational databases, SQL workflows, data modelling, data quality checks and reporting-oriented queries.

It is part of my broader **Data/BI portfolio** as an IHK retraining student in **Data and Process Analysis**. The goal is not to build a production database system, but to create a clean, reproducible foundation for practical SQL and Microsoft-oriented BI learning.

---

## Why This Project Matters for Data/BI

SQL Server is a central part of many Microsoft-based data environments. For Data/BI work, it is not enough to only write isolated SQL queries. A useful workflow also needs:

- a reproducible local database environment
- clear connection settings and documented tooling
- safe handling of credentials
- structured SQL scripts
- basic validation queries
- reporting-oriented aggregations
- a path from relational data toward Power BI, Fabric and BI-style analysis

This project demonstrates the foundation for that workflow: a local SQL Server instance running in Docker, documented DataGrip access and SQL scripts that can later feed Power BI or Python-based analysis.

---

## What This Demonstrates

This repository demonstrates:

- running Microsoft SQL Server 2022 locally in Docker
- using `.env` files for local credentials without committing secrets
- connecting to SQL Server from DataGrip
- verifying a SQL Server instance with basic checks
- organizing SQL scripts in a clear folder structure
- documenting a practical local database workflow
- preparing SQL practice for reporting, data quality and BI-style analysis

---

## Data/BI-Oriented Stack

| Layer | Tool / Concept | Purpose |
|---|---|---|
| Database | Microsoft SQL Server 2022 | Relational database practice and Microsoft data stack foundation |
| Runtime | Docker Desktop | Reproducible local SQL Server environment |
| SQL Client | DataGrip | SQL development, database inspection and query execution |
| Scripts | SQL files | Repeatable checks, training queries and reporting-oriented examples |
| Configuration | `.env` / `.env.example` | Local credential handling without committing secrets |
| BI Layer | Power BI | Planned next layer for connecting reports to SQL Server data |
| Platform Perspective | Microsoft Fabric / Azure | Longer-term Microsoft data platform context |

---

## Current Status

The local Docker-based SQL Server setup is working and documented.

Verified:

- SQL Server container starts successfully
- SQL Server listens on host port `14333`
- `sqlcmd` is available inside the container
- connection test with `SELECT @@VERSION` works
- DataGrip connection works
- DPA training database scripts are included
- SQL example scripts are organized under `sql/examples/`

Included:

- `docker-compose.yml`
- `.env.example`
- `.gitignore`
- documented DataGrip workflow
- SQL example scripts
- basic project notes
- folder structure for future notebooks and BI-related extensions

Not included:

- real passwords
- `.env` files
- database volumes
- private data
- exported local data
- personal or customer data

---

## Repository Structure

```text
sql-server-docker-basics/
├── README.md
├── LICENSE
├── .env.example
├── .gitignore
├── docker-compose.yml
├── docs/
│   ├── datagrip-workflow.md
│   └── project-notes.md
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_schema.sql
│   ├── 03_insert_sample_data.sql
│   ├── 04_analysis_queries.sql
│   └── examples/
│       ├── README.md
│       ├── 01_basic_checks.sql
│       ├── 02_training_queries.sql
│       └── 03_data_quality_checks.sql
└── notebooks/
```

---

## Environment Variables

Create a local `.env` file from `.env.example`:

```bash
cp .env.example .env
```

Then change the password in `.env`.

The `.env` file is intentionally ignored by Git.

---

## Local Connection

Default local connection settings:

| Setting | Value |
|---|---|
| DBMS | Microsoft SQL Server |
| Host | `127.0.0.1` |
| Port | `14333` |
| User | `sa` |
| Password | local value from `.env` |

---

## DataGrip Workflow

The DataGrip workflow is documented in:

```text
docs/datagrip-workflow.md
```

This includes the local connection setup and the basic workflow for working with the SQL Server container from DataGrip.

---

## SQL Examples

The repository contains two kinds of SQL scripts:

1. core SQL workflow scripts that build on each other
2. additional standalone example scripts for checks, training queries and data quality practice

### Core SQL workflow scripts

Core SQL workflow scripts are available directly under:

```text
sql/
```

These scripts document a small end-to-end SQL learning workflow:

- `01_create_database.sql` creates the local training database in an idempotent way
- `02_create_schema.sql` defines a small relational schema with primary keys, foreign keys and uniqueness constraints
- `03_insert_sample_data.sql` inserts reproducible synthetic sample data
- `04_analysis_queries.sql` contains reporting-oriented SQL queries, including joins, averages, pass-rate calculations and a simple below-target flag

The sample data is synthetic and does not contain real personal or customer data.

### Additional standalone example scripts

Additional standalone example scripts are available in:

```text
sql/examples/
```

Current examples:

- `01_basic_checks.sql`
- `02_training_queries.sql`
- `03_data_quality_checks.sql`

The `sql/examples/` scripts are intended as a practical starting point for SQL Server checks, training queries, basic data quality checks and later reporting-oriented SQL examples.

Together, the core workflow scripts and the standalone examples show database setup, relational schema design, reproducible sample data, analysis queries and basic data quality checks.

---

## Roadmap: From SQL Server to BI Workflow

Planned improvements are intentionally incremental:

1. add a small synthetic training database
2. add data quality checks and validation queries
3. add reporting-oriented aggregation queries
4. add a simple star-schema example for BI learning
5. document a Power BI connection workflow
6. optionally add a Python/pandas notebook for SQL Server data access
7. connect the project conceptually to Microsoft Fabric/Azure as the next platform layer

Power BI and Microsoft Fabric are not treated as finished parts of this repository yet. They are the planned next layers after the SQL Server foundation is clean, documented and reproducible.

---

## Notes and Limitations

This repository is a local learning setup, not a production database project.

It should not contain:

- real credentials
- private dumps
- personal data
- customer data
- SQL Server database volumes
- generated local exports

The purpose is to document a realistic learning workflow for SQL Server, relational data practice and Data/BI preparation.
