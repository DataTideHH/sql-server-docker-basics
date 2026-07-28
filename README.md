# SQL Server Docker Basics

[![SQL Server integration](https://github.com/DataTideHH/sql-server-docker-basics/actions/workflows/sql-server-integration.yml/badge.svg)](https://github.com/DataTideHH/sql-server-docker-basics/actions/workflows/sql-server-integration.yml)

**Microsoft SQL Server 2022 · Docker Compose · PowerShell 7 · T-SQL · data integrity · dimensional modelling · GitHub Actions**

This repository is a compact SQL Server analytics lab. It provides a reproducible database environment, a normalized training model, deterministic synthetic data, enforced integrity rules, a dimensional reporting layer and executable verification from source tables through the reporting fact.

The same PowerShell entry point runs locally and in GitHub Actions. The CI workflow provisions SQL Server on a fresh Ubuntu runner and executes the complete lab twice, proving both clean installation and repeatability.

The project is part of my Data/BI portfolio during the IHK retraining program in Data and Process Analysis. Its scope is deliberately bounded: it demonstrates a technically credible path from relational source data to a tested star schema without presenting the lab as a production data platform.

---

## Project at a Glance

| Area | Current evidence |
|---|---|
| SQL Server environment | Pinned SQL Server 2022 image, Docker healthcheck, explicit host port and persistent local volume |
| PowerShell provisioning | Docker and configuration validation, health polling, ordered SQL execution and non-zero failure behaviour |
| Relational model | Four normalized source tables with primary keys, foreign keys, uniqueness and required-value constraints |
| Derived outcome | Pass status and score percentage are derived instead of stored redundantly |
| Cross-table integrity | Set-based triggers enforce score limits that span results and assessments |
| Negative tests | Seven rollback-based tests prove invalid writes are rejected |
| Reporting model | Three dimensions and one fact table with a documented learner-assessment grain |
| Reporting load | Transaction-based upsert with preserved surrogate keys and source lineage |
| Reconciliation | Bidirectional checks compare source and reporting rows and values |
| Continuous integration | GitHub Actions runs the complete workflow twice on Ubuntu 24.04 |
| Data safety | Only synthetic data; `.env`, credentials, volumes and dumps remain excluded |

## Review Path

A technical reviewer can inspect the implementation in this order:

1. [`.github/workflows/sql-server-integration.yml`](.github/workflows/sql-server-integration.yml) — end-to-end CI execution and repeatability test
2. [`docker-compose.yml`](docker-compose.yml) — pinned SQL Server image, volume, bind mount and healthcheck
3. [`scripts/Initialize-Lab.ps1`](scripts/Initialize-Lab.ps1) — complete orchestration entry point
4. [`scripts/SqlServerLab.Common.ps1`](scripts/SqlServerLab.Common.ps1) — shared Docker, configuration and readiness functions
5. [`sql/02_create_schema.sql`](sql/02_create_schema.sql) — relational schema, constraints, triggers and derived-result view
6. [`sql/06_test_integrity_rules.sql`](sql/06_test_integrity_rules.sql) — executable negative tests
7. [`sql/07_create_reporting_model.sql`](sql/07_create_reporting_model.sql) — dimensional schema, constraints, indexes and reporting view
8. [`sql/08_load_reporting_model.sql`](sql/08_load_reporting_model.sql) — transaction-based dimensional upsert
9. [`sql/09_verify_reporting_model.sql`](sql/09_verify_reporting_model.sql) — source-to-reporting reconciliation
10. [`docs/ci-workflow.md`](docs/ci-workflow.md) — CI design, security boundaries and validation evidence

---

## End-to-End Workflow

```text
local .env or temporary CI .env
              │
              ▼
PowerShell bootstrap
              │
              ├── validate Docker and Compose
              ├── validate configuration
              ├── pull and start SQL Server
              └── wait for container health
                      │
                      ▼
relational source workflow
                      │
                      ├── create or upgrade source schema
                      ├── insert deterministic synthetic data
                      ├── enforce constraints and triggers
                      ├── verify source objects and values
                      └── run rollback-based negative tests
                      │
                      ▼
dimensional reporting workflow
                      │
                      ├── create reporting schema
                      ├── upsert dimensions and fact rows
                      ├── verify grain and key integrity
                      └── reconcile reporting with source
```

GitHub Actions executes this complete sequence twice in one job. The first run validates provisioning on a fresh runner. The second run uses the same temporary database volume and proves that the setup and load remain repeatable.

The host connection uses port `14333`, while SQL Server remains on internal port `1433` inside the container.

---

## Implemented Scope

### Database environment

- SQL Server 2022 managed through Docker Compose
- pinned cumulative-update image
- persistent named volume for local development
- configurable password, edition, image and host port
- `sqlcmd`-based healthcheck
- repository SQL directory mounted read-only inside the container
- access through DataGrip or another SQL Server client

### PowerShell provisioning

The shared PowerShell workflow provides:

- Docker CLI, engine and Compose validation
- `.env` presence and value checks
- rejection of public placeholder passwords
- optional image-pull skipping for later runs
- container startup and SQL Server health polling
- ordered execution of source and reporting scripts
- non-zero failure propagation from Docker and `sqlcmd`
- source-model verification
- rollback-based negative integrity tests
- reporting-model reconciliation
- safe stop and container removal without automatic volume deletion

The scripts require PowerShell 7 and are validated on Windows 11 locally and Ubuntu 24.04 in GitHub Actions.

### Relational source model

The `dpa_training` database contains four source tables in the `dpa` schema:

| Table | Grain |
|---|---|
| `dpa.learning_modules` | one row per learning module |
| `dpa.learners` | one row per synthetic learner |
| `dpa.assessments` | one row per assessment |
| `dpa.assessment_results` | one row per learner and assessment |

The source schema enforces:

- surrogate identity keys
- stable business codes
- primary and foreign keys
- unique module and learner codes
- unique assessment names within a module
- one result per learner and assessment
- non-empty required text values
- valid maxima and pass thresholds
- non-negative scores
- cross-table score limits through set-based triggers

### Derived result view

`dpa.v_assessment_results` derives:

- `score_percentage` from `score / max_score`
- `passed` from `score >= pass_score`

The earlier stored `passed` column was removed only after a controlled upgrade check confirmed that every existing value agreed with the underlying score and threshold.

### Executable integrity tests

`sql/06_test_integrity_rules.sql` attempts seven invalid writes:

1. set `max_score` to zero
2. set `pass_score` above `max_score`
3. set a result score below zero
4. set a result score above the assessment maximum
5. lower an assessment maximum below an existing result
6. create a duplicate learner-assessment result
7. duplicate an assessment name within one module

Each test runs in a transaction, rolls back any open transaction and checks the expected SQL Server error class. The suite fails closed when an expected error is missing.

### Dimensional reporting model

The `reporting` schema contains:

| Table | Grain |
|---|---|
| `reporting.dim_module` | one row per source learning module |
| `reporting.dim_learner` | one row per source learner |
| `reporting.dim_assessment` | one row per source assessment |
| `reporting.fact_assessment_result` | one row per learner and assessment |

The fact table uses surrogate dimension keys while retaining `source_result_id` for lineage. It contains:

- `score`
- `max_score`
- `pass_score`
- persisted `score_percentage`
- persisted `passed`
- `loaded_at_utc`

A unique `(assessment_key, learner_key)` constraint enforces the declared fact grain. Foreign keys connect every fact row to all three dimensions.

### Reporting load

`sql/08_load_reporting_model.sql` performs a transaction-based upsert:

- existing dimension attributes are refreshed
- existing surrogate keys are preserved
- new source members are inserted
- every source result must resolve to all dimension keys
- existing facts are refreshed through `source_result_id`
- new facts are inserted

The load does not silently remove reporting rows. Unexpected stale or additional rows are surfaced by reconciliation instead.

### Reporting verification

`sql/09_verify_reporting_model.sql` checks:

- presence of all reporting objects
- exact source-to-dimension and source-to-fact count parity
- bidirectional dimension equality
- absence of orphaned keys
- uniqueness of the fact grain
- bidirectional equality between source results and fact values
- enabled and trusted constraints and foreign keys
- persisted computed measures

Validated values for the included dataset are:

| Metric | Value |
|---|---:|
| modules | 5 |
| learners | 5 |
| assessments | 5 |
| source results | 25 |
| passed results | 21 |
| module dimension rows | 5 |
| learner dimension rows | 5 |
| assessment dimension rows | 5 |
| fact rows | 25 |
| passed fact rows | 21 |
| average score percentage | 68.12 |
| source reconciliation verified | 1 |
| reporting model verified | 1 |

---

## GitHub Actions Integration

The workflow at [`.github/workflows/sql-server-integration.yml`](.github/workflows/sql-server-integration.yml) runs for relevant pull requests and pushes to `main`, and can also be started manually.

It performs:

- checkout with read-only repository permission
- PowerShell, Docker and Compose version reporting
- syntax parsing of every PowerShell script
- runtime generation of a temporary CI-only `.env`
- one complete initialization on a fresh Ubuntu runner
- a second complete initialization for repeatability
- SQL Server diagnostics on failure
- unconditional container and temporary-file cleanup

The first pull-request run completed successfully on GitHub-hosted Ubuntu 24.04.4. Both complete database runs passed, including source verification, seven negative integrity tests and reporting reconciliation.

The CI workflow uses no repository secrets and receives no write permission. See [`docs/ci-workflow.md`](docs/ci-workflow.md) for details.

---

## Repository Structure

```text
sql-server-docker-basics/
├── .github/
│   └── workflows/
│       └── sql-server-integration.yml
├── README.md
├── LICENSE
├── .env.example
├── .gitignore
├── docker-compose.yml
├── docs/
│   ├── ci-workflow.md
│   ├── datagrip-workflow.md
│   ├── project-notes.md
│   └── reporting-model.md
├── scripts/
│   ├── Initialize-Lab.ps1
│   ├── Invoke-SqlScript.ps1
│   ├── SqlServerLab.Common.ps1
│   ├── Stop-Lab.ps1
│   ├── Test-DataIntegrity.ps1
│   ├── Test-LabConnection.ps1
│   └── Test-ReportingModel.ps1
└── sql/
    ├── 01_create_database.sql
    ├── 02_create_schema.sql
    ├── 03_insert_sample_data.sql
    ├── 04_analysis_queries.sql
    ├── 05_verify_setup.sql
    ├── 06_test_integrity_rules.sql
    ├── 07_create_reporting_model.sql
    ├── 08_load_reporting_model.sql
    ├── 09_verify_reporting_model.sql
    └── examples/
```

---

## Local Setup

### Prerequisites

- Windows 11 or another environment with PowerShell 7
- Docker Desktop or Docker Engine with Compose
- Git
- optional: DataGrip or another SQL Server client

### 1. Create the local environment file

```powershell
Copy-Item .env.example .env
notepad.exe .env
```

Replace the password placeholder before starting the lab. `.env` is ignored by Git and must remain local.

### 2. Initialize the complete lab

```powershell
& ".\scripts\Initialize-Lab.ps1"
```

For later runs, the image pull can be skipped:

```powershell
& ".\scripts\Initialize-Lab.ps1" -SkipImagePull
```

### 3. Run individual verification entry points

```powershell
& ".\scripts\Test-LabConnection.ps1"
& ".\scripts\Test-DataIntegrity.ps1"
& ".\scripts\Test-ReportingModel.ps1"
```

### 4. Connect with a SQL client

| Setting | Value |
|---|---|
| DBMS | Microsoft SQL Server |
| Host | `127.0.0.1` |
| Port | `14333` |
| User | `sa` |
| Password | local value from `.env` |
| Database | `dpa_training` |

See [`docs/datagrip-workflow.md`](docs/datagrip-workflow.md) for the detailed client procedure.

### 5. Stop the lab

Preserve the container and volume:

```powershell
& ".\scripts\Stop-Lab.ps1"
```

Remove the container and Compose network while preserving the named volume:

```powershell
& ".\scripts\Stop-Lab.ps1" -RemoveContainer
```

The normal workflow deliberately does not remove the named volume.

---

## Current Boundaries

This repository does not claim:

- production deployment or high availability
- production user and role design
- a general-purpose migration framework
- slowly changing dimension handling
- incremental, watermark-based or deletion-aware warehouse loading
- database backup and restore automation
- a finished Power BI report
- Azure or Microsoft Fabric deployment
- a deployment or release pipeline

The star schema is a compact reporting layer for one deterministic synthetic dataset, not a production enterprise warehouse. The GitHub Actions workflow is an integration test, not a deployment pipeline.

## Next Development Steps

1. document and validate a Power BI connection against the reporting layer
2. build a compact Power BI report with explicit KPI definitions
3. add screenshots or a short demo for portfolio review
4. evaluate versioned migrations and incremental loading when project scope creates a concrete need

---

## Data and Credential Safety

Only synthetic training data belongs in this repository. The following remain excluded:

- `.env` files and real credentials
- personal or customer data
- private database dumps
- SQL Server database volumes
- local exports and backup files

See [`docs/project-notes.md`](docs/project-notes.md), [`docs/reporting-model.md`](docs/reporting-model.md) and [`docs/ci-workflow.md`](docs/ci-workflow.md) for design details and validation evidence.
