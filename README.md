# SQL Server Docker Basics

**Microsoft SQL Server 2022 · Docker Desktop · T-SQL · relational modelling · data quality · reporting queries**

This repository is a compact SQL Server analytics lab. It provides a local database environment, a small normalized training model, reproducible synthetic data and reporting-oriented T-SQL queries.

It is part of my Data/BI portfolio during the IHK retraining program in Data and Process Analysis. The project is deliberately bounded: the current focus is a clear relational foundation that can later support automated provisioning, integration tests and a Power BI-oriented data mart.

---

## Project at a Glance

| Area | Current evidence |
|---|---|
| SQL Server environment | SQL Server 2022 runs in Docker with an explicit host-port mapping and persistent local volume |
| Configuration | Local credentials are supplied through `.env`; the file is excluded from version control |
| Relational model | Four related tables with primary keys, foreign keys and uniqueness constraints |
| Sample data | Synthetic modules, learners, assessments and results inserted with repeatable `NOT EXISTS` checks |
| Analysis | Joins, grouped KPIs, average scores, pass rates and below-target flags |
| Data quality | Standalone checks for missing values, duplicate business keys and invalid numeric ranges |
| SQL client workflow | Documented DataGrip connection and script execution process |

## Review Path

A quick technical review can follow these files in order:

1. [`docker-compose.yml`](docker-compose.yml) — local SQL Server runtime and volume configuration
2. [`sql/02_create_schema.sql`](sql/02_create_schema.sql) — relational model and constraints
3. [`sql/03_insert_sample_data.sql`](sql/03_insert_sample_data.sql) — deterministic synthetic seed data
4. [`sql/04_analysis_queries.sql`](sql/04_analysis_queries.sql) — reporting-oriented queries and KPIs
5. [`sql/examples/03_data_quality_checks.sql`](sql/examples/03_data_quality_checks.sql) — documented data-quality checks
6. [`docs/datagrip-workflow.md`](docs/datagrip-workflow.md) — local connection and execution workflow

---

## Workflow

```text
.env configuration
        │
        ▼
Docker Compose
        │
        ▼
SQL Server 2022 container
        │
        ▼
dpa_training database
        │
        ├── normalized tables
        ├── synthetic seed data
        ├── validation examples
        └── reporting queries
```

The host connects to SQL Server through port `14333`. Using a non-default host port avoids collisions with a separate local SQL Server installation while keeping the container's internal port at `1433`.

---

## Implemented Scope

### Database environment

- SQL Server 2022 container managed through Docker Compose
- persistent Docker volume for local development
- configurable SQL Server password, edition and host port
- connection through DataGrip or another SQL Server client
- `sqlcmd` available inside the container for command-line verification

### Relational model

The `dpa_training` database contains four tables in the `dpa` schema:

| Table | Grain |
|---|---|
| `dpa.learning_modules` | one row per learning module |
| `dpa.learners` | one row per synthetic learner |
| `dpa.assessments` | one row per assessment |
| `dpa.assessment_results` | one row per learner and assessment |

The schema includes:

- surrogate identity keys
- stable business codes for modules and learners
- primary and foreign keys
- unique module and learner codes
- a unique learner-assessment combination

### Reporting queries

The core analysis script includes:

- a detailed assessment result view assembled through joins
- average score and pass rate by module
- learner-level performance summaries
- modules flagged below an 80 percent pass-rate target

### Data-quality examples

The standalone quality script covers:

- row-count baselines
- missing-value checks
- duplicate business-key detection
- invalid quantity and amount ranges
- a compact quality summary for reporting preparation

The quality example is currently independent from the core `dpa` model. Model-specific executable quality gates are planned as a separate extension.

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
└── sql/
    ├── 01_create_database.sql
    ├── 02_create_schema.sql
    ├── 03_insert_sample_data.sql
    ├── 04_analysis_queries.sql
    └── examples/
        ├── README.md
        ├── 01_basic_checks.sql
        ├── 02_training_queries.sql
        └── 03_data_quality_checks.sql
```

---

## Local Setup

### Prerequisites

- Docker Desktop
- Git
- a SQL Server client such as DataGrip

### 1. Create the local environment file

```bash
cp .env.example .env
```

Replace the example password before starting the container. The `.env` file is ignored by Git and must remain local.

### 2. Start SQL Server

```bash
docker compose up -d
```

### 3. Connect to the instance

| Setting | Value |
|---|---|
| DBMS | Microsoft SQL Server |
| Host | `127.0.0.1` |
| Port | `14333` |
| User | `sa` |
| Password | local value from `.env` |

The detailed DataGrip procedure is documented in [`docs/datagrip-workflow.md`](docs/datagrip-workflow.md).

### 4. Run the core scripts

Execute the scripts in this order:

```text
sql/01_create_database.sql
sql/02_create_schema.sql
sql/03_insert_sample_data.sql
sql/04_analysis_queries.sql
```

The creation and seed scripts use existence checks so the normal setup can be repeated without duplicating the included sample records.

---

## Current Boundaries

This repository does not currently claim:

- unattended database provisioning
- production deployment or high availability
- automated migrations
- CI-based SQL Server integration tests
- a dimensional data mart
- a finished Power BI report
- Azure or Microsoft Fabric deployment

Those boundaries are intentional. Each later extension should add an executable capability and a verifiable result rather than only another technology label.

## Next Development Steps

1. add a PowerShell bootstrap with readiness checks and ordered script execution
2. harden the relational model with executable business-rule and integrity tests
3. add a small dimensional reporting layer for Power BI
4. run the complete database workflow in GitHub Actions
5. document and validate a Power BI connection against the reporting layer

---

## Data and Credential Safety

Only synthetic training data belongs in this repository. The following remain excluded:

- `.env` files and real credentials
- personal or customer data
- private database dumps
- SQL Server database volumes
- local exports and backup files

See [`docs/project-notes.md`](docs/project-notes.md) for the current design decisions and scope notes.