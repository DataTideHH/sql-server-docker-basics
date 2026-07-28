# SQL Server Docker Basics

**Microsoft SQL Server 2022 · Docker Desktop · PowerShell 7 · T-SQL · relational modelling · data quality · reporting queries**

This repository is a compact SQL Server analytics lab. It provides a reproducible local database environment, a small normalized training model, synthetic seed data, reporting-oriented T-SQL queries and a PowerShell bootstrap for startup, readiness checks, ordered execution and verification.

It is part of my Data/BI portfolio during the IHK retraining program in Data and Process Analysis. The project is deliberately bounded: the current focus is a reliable relational foundation that can later support stronger business rules, integration tests and a Power BI-oriented data mart.

---

## Project at a Glance

| Area | Current evidence |
|---|---|
| SQL Server environment | SQL Server 2022 runs in Docker with an explicit host-port mapping, persistent local volume and healthcheck |
| Provisioning | PowerShell validates Docker and `.env`, starts the service, waits for readiness and executes the SQL workflow in order |
| Configuration | Local credentials are supplied through `.env`; the file is excluded from version control |
| Relational model | Four related tables with primary keys, foreign keys and uniqueness constraints |
| Sample data | Synthetic modules, learners, assessments and results inserted with repeatable `NOT EXISTS` checks |
| Analysis | Joins, grouped KPIs, average scores, pass rates and below-target flags |
| Verification | A final SQL script checks required tables and expected row counts and fails the run on deviations |
| Data quality | Standalone checks for missing values, duplicate business keys and invalid numeric ranges |
| SQL client workflow | Documented DataGrip connection and script execution process |

## Review Path

A quick technical review can follow these files in order:

1. [`docker-compose.yml`](docker-compose.yml) — pinned SQL Server image, volume, bind mount and healthcheck
2. [`scripts/Initialize-Lab.ps1`](scripts/Initialize-Lab.ps1) — end-to-end local bootstrap
3. [`scripts/SqlServerLab.Common.ps1`](scripts/SqlServerLab.Common.ps1) — shared Docker, configuration and readiness functions
4. [`sql/02_create_schema.sql`](sql/02_create_schema.sql) — relational model and constraints
5. [`sql/03_insert_sample_data.sql`](sql/03_insert_sample_data.sql) — deterministic synthetic seed data
6. [`sql/04_analysis_queries.sql`](sql/04_analysis_queries.sql) — reporting-oriented queries and KPIs
7. [`sql/05_verify_setup.sql`](sql/05_verify_setup.sql) — executable setup verification
8. [`sql/examples/03_data_quality_checks.sql`](sql/examples/03_data_quality_checks.sql) — standalone data-quality example

---

## Workflow

```text
.env configuration
        │
        ▼
PowerShell bootstrap
        │
        ├── validate Docker and Compose
        ├── validate local configuration
        ├── pull and start SQL Server
        └── wait for container health
                │
                ▼
        ordered T-SQL workflow
                │
                ├── create database
                ├── create schema
                ├── insert synthetic data
                ├── run reporting queries
                └── verify tables and row counts
```

The host connects to SQL Server through port `14333`. Using a non-default host port avoids collisions with a separate local SQL Server installation while keeping the container's internal port at `1433`.

---

## Implemented Scope

### Database environment

- SQL Server 2022 container managed through Docker Compose
- pinned SQL Server 2022 cumulative-update image
- persistent Docker volume for local development
- configurable SQL Server password, edition, image and host port
- healthcheck based on `sqlcmd`
- read-only container mount for repository SQL scripts
- connection through DataGrip or another SQL Server client

### PowerShell provisioning

The PowerShell workflow provides:

- Docker CLI and engine validation
- Docker Compose validation
- `.env` presence and value checks
- rejection of the public password placeholder
- SQL Server image pull with an optional skip switch
- container startup and health polling
- ordered execution of the core SQL scripts
- non-zero exit behaviour for Docker and SQL errors
- final verification of database objects and row counts
- safe stop and container-removal commands that preserve the named volume

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

- a detailed assessment result set assembled through joins
- average score and pass rate by module
- learner-level performance summaries
- modules flagged below an 80 percent pass-rate target

### Verification

`sql/05_verify_setup.sql` stops the workflow if a required table is missing or the expected synthetic-data counts differ from:

| Object | Expected rows |
|---|---:|
| learning modules | 5 |
| learners | 5 |
| assessments | 5 |
| assessment results | 25 |

The normal setup can be executed repeatedly. Existing objects remain in place and the seed script does not duplicate the included records.

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
├── scripts/
│   ├── Initialize-Lab.ps1
│   ├── Invoke-SqlScript.ps1
│   ├── SqlServerLab.Common.ps1
│   ├── Stop-Lab.ps1
│   └── Test-LabConnection.ps1
└── sql/
    ├── 01_create_database.sql
    ├── 02_create_schema.sql
    ├── 03_insert_sample_data.sql
    ├── 04_analysis_queries.sql
    ├── 05_verify_setup.sql
    └── examples/
        ├── README.md
        ├── 01_basic_checks.sql
        ├── 02_training_queries.sql
        └── 03_data_quality_checks.sql
```

---

## Local Setup

### Prerequisites

- Windows 11
- PowerShell 7
- Docker Desktop with the Linux engine running
- Git
- optional: a SQL Server client such as DataGrip

### 1. Create the local environment file

```powershell
Copy-Item .env.example .env
notepad.exe .env
```

Replace the password placeholder before starting the lab. The `.env` file is ignored by Git and must remain local.

### 2. Initialize the complete lab

```powershell
& ".\scripts\Initialize-Lab.ps1"
```

The script pulls the configured image, starts SQL Server, waits for a healthy container, executes the numbered SQL scripts and verifies the resulting database state.

For later runs, the image pull can be skipped:

```powershell
& ".\scripts\Initialize-Lab.ps1" -SkipImagePull
```

### 3. Verify the current database state

```powershell
& ".\scripts\Test-LabConnection.ps1"
```

### 4. Run selected SQL scripts

```powershell
& ".\scripts\Invoke-SqlScript.ps1" -Path @(
    "sql/03_insert_sample_data.sql",
    "sql/04_analysis_queries.sql"
)
```

Only SQL files inside the repository's `sql/` directory are accepted.

### 5. Connect with a SQL client

| Setting | Value |
|---|---|
| DBMS | Microsoft SQL Server |
| Host | `127.0.0.1` |
| Port | `14333` |
| User | `sa` |
| Password | local value from `.env` |
| Database | `dpa_training` |

The detailed DataGrip procedure is documented in [`docs/datagrip-workflow.md`](docs/datagrip-workflow.md).

### 6. Stop the lab

Stop the running container while preserving it and the database volume:

```powershell
& ".\scripts\Stop-Lab.ps1"
```

Remove the container and Compose network while preserving the named database volume:

```powershell
& ".\scripts\Stop-Lab.ps1" -RemoveContainer
```

The workflow deliberately does not remove the named volume.

---

## Current Boundaries

This repository does not currently claim:

- production deployment or high availability
- production user and role design
- automated schema migrations
- CI-based SQL Server integration tests
- a dimensional data mart
- a finished Power BI report
- Azure or Microsoft Fabric deployment
- a macOS or Linux bootstrap equivalent to the PowerShell workflow

Those boundaries are intentional. Each later extension should add an executable capability and a verifiable result rather than only another technology label.

## Next Development Steps

1. harden the relational model with executable business-rule and integrity tests
2. add a small dimensional reporting layer for Power BI
3. run the complete database workflow in GitHub Actions
4. document and validate a Power BI connection against the reporting layer

---

## Data and Credential Safety

Only synthetic training data belongs in this repository. The following remain excluded:

- `.env` files and real credentials
- personal or customer data
- private database dumps
- SQL Server database volumes
- local exports and backup files

See [`docs/project-notes.md`](docs/project-notes.md) for the current design decisions and scope notes.
