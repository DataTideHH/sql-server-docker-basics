# SQL Server Docker Basics

**Microsoft SQL Server 2022 · Docker Desktop · PowerShell 7 · T-SQL · relational modelling · data integrity · dimensional modelling · reporting verification**

This repository is a compact SQL Server analytics lab. It provides a reproducible local database environment, a normalized training model, synthetic seed data, enforced integrity rules, a dimensional reporting layer and a PowerShell workflow for startup, readiness checks, ordered execution and verification.

It is part of my Data/BI portfolio during the IHK retraining program in Data and Process Analysis. The project is deliberately bounded: it demonstrates a reliable path from relational source data to a verified star schema that can later support Power BI and CI-based integration tests.

---

## Project at a Glance

| Area | Current evidence |
|---|---|
| SQL Server environment | SQL Server 2022 runs in Docker with an explicit host-port mapping, persistent local volume and healthcheck |
| Provisioning | PowerShell validates Docker and `.env`, starts the service, waits for readiness and executes the SQL workflow in order |
| Relational model | Four related tables with primary keys, foreign keys, uniqueness constraints and validated required values |
| Derived outcome | Pass status and score percentage are derived in `dpa.v_assessment_results` rather than stored redundantly |
| Cross-table integrity | Triggers prevent scores above the assessment maximum and invalid reductions of an existing maximum |
| Negative tests | Seven transaction-based tests prove that invalid writes are rejected and rolled back |
| Reporting model | Three dimensions and one fact table implement a documented star-schema grain |
| Reporting load | A transaction-based upsert synchronizes source values without silently deleting reporting rows |
| Reconciliation | Executable checks compare dimensions and facts with the relational source in both directions |
| SQL client workflow | Documented DataGrip connection and script execution process |

## Review Path

A quick technical review can follow these files in order:

1. [`docker-compose.yml`](docker-compose.yml) — pinned SQL Server image, volume, bind mount and healthcheck
2. [`scripts/Initialize-Lab.ps1`](scripts/Initialize-Lab.ps1) — end-to-end local bootstrap
3. [`scripts/SqlServerLab.Common.ps1`](scripts/SqlServerLab.Common.ps1) — shared Docker, configuration and readiness functions
4. [`sql/02_create_schema.sql`](sql/02_create_schema.sql) — relational schema, constraints, triggers and derived-result view
5. [`sql/06_test_integrity_rules.sql`](sql/06_test_integrity_rules.sql) — negative tests for enforced database rules
6. [`sql/07_create_reporting_model.sql`](sql/07_create_reporting_model.sql) — dimensional schema, constraints, indexes and reporting view
7. [`sql/08_load_reporting_model.sql`](sql/08_load_reporting_model.sql) — transaction-based dimensional upsert
8. [`sql/09_verify_reporting_model.sql`](sql/09_verify_reporting_model.sql) — source-to-reporting reconciliation
9. [`docs/reporting-model.md`](docs/reporting-model.md) — grain, dimensions, measures, load behaviour and boundaries

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
        relational workflow
                │
                ├── create or upgrade source schema
                ├── insert deterministic synthetic data
                ├── enforce constraints and triggers
                ├── verify source objects and values
                └── run rollback-based negative tests
                │
                ▼
        dimensional workflow
                │
                ├── create reporting schema
                ├── upsert dimensions and fact rows
                ├── verify grain and key integrity
                └── reconcile reporting data with source data
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

- Docker CLI, engine and Compose validation
- `.env` presence and value checks
- rejection of the public password placeholder
- SQL Server image pull with an optional skip switch
- container startup and health polling
- ordered execution of relational and dimensional SQL scripts
- non-zero exit behaviour for Docker and SQL errors
- source-model verification
- rollback-based negative integrity tests
- reporting-model reconciliation
- safe stop and container-removal commands that preserve the named volume

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
- stable business codes for modules and learners
- primary and foreign keys
- unique module and learner codes
- unique assessment names within a module
- one result per learner and assessment
- non-empty required text values
- valid assessment maxima and pass thresholds
- non-negative result scores
- cross-table score limits through set-based triggers

### Derived outcome view

`dpa.v_assessment_results` joins each result to its assessment and derives:

- `score_percentage` from `score / max_score`
- `passed` from `score >= pass_score`

The earlier stored `passed` column was removed only after a controlled upgrade check confirmed that every existing value agreed with the underlying score and threshold.

### Executable integrity tests

`sql/06_test_integrity_rules.sql` deliberately attempts invalid writes and expects SQL Server to reject them:

1. set `max_score` to zero
2. set `pass_score` above `max_score`
3. set a result score below zero
4. set a result score above the assessment maximum
5. lower an assessment maximum below an existing result
6. create a duplicate learner-assessment result
7. duplicate an assessment name within the same module

Each test runs inside a transaction and rolls back any open transaction before evaluating the expected error. The suite fails closed when an expected error is missing.

### Dimensional reporting model

The `reporting` schema contains:

| Table | Grain |
|---|---|
| `reporting.dim_module` | one row per source learning module |
| `reporting.dim_learner` | one row per source learner |
| `reporting.dim_assessment` | one row per source assessment |
| `reporting.fact_assessment_result` | one row per learner and assessment |

The fact table uses surrogate dimension keys and retains `source_result_id` for lineage. Its measures include:

- `score`
- `max_score`
- `pass_score`
- persisted `score_percentage`
- persisted `passed`
- `loaded_at_utc`

The learner-assessment grain is enforced by a unique constraint. Foreign keys connect every fact row to all three dimensions.

### Reporting load behaviour

`sql/08_load_reporting_model.sql` performs a transaction-based upsert:

- existing dimension values are updated from the source
- new source members are inserted
- existing fact rows are refreshed through `source_result_id`
- new fact rows are inserted
- every source result must resolve to all dimension keys

The load does not silently delete reporting rows. Unexpected stale or additional rows are surfaced by verification instead of being removed automatically.

### Reporting verification

`sql/09_verify_reporting_model.sql` checks:

- presence of all reporting tables and the reporting view
- exact source-to-dimension and source-to-fact row-count parity
- bidirectional value equality for all dimensions
- absence of orphaned dimension keys
- uniqueness of the learner-assessment fact grain
- bidirectional equality between source results and fact values
- enabled and trusted reporting constraints and foreign keys
- presence of both persisted computed measures

A successful verification reports:

| Metric | Validated value |
|---|---:|
| module dimension rows | 5 |
| learner dimension rows | 5 |
| assessment dimension rows | 5 |
| fact rows | 25 |
| passed fact rows | 21 |
| average score percentage | 68.12 |
| source reconciliation verified | 1 |
| reporting model verified | 1 |

### Validation evidence

The reporting increment was validated locally on Windows 11 with PowerShell 7.6.4 and Docker Desktop using the Linux engine.

The first successful run created and loaded the reporting model on the existing persistent database volume. The complete initialization was then executed a second time. Both runs produced:

- `5 / 5 / 5` dimension rows
- `25` fact rows
- `21` passed fact rows
- average score percentage `68.12`
- source reconciliation result `1`
- reporting-model verification result `1`
- no duplicated source or reporting rows

The repeated run confirms that the reporting schema and upsert load are repeatable for the included dataset.

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

### 4. Run selected SQL scripts

```powershell
& ".\scripts\Invoke-SqlScript.ps1" -Path @(
    "sql/08_load_reporting_model.sql",
    "sql/09_verify_reporting_model.sql"
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
- a general-purpose automated migration framework
- slowly changing dimension handling
- incremental or deletion-aware warehouse loading
- CI-based SQL Server integration tests
- a finished Power BI report
- Azure or Microsoft Fabric deployment
- a macOS or Linux bootstrap equivalent to the PowerShell workflow

The dimensional model is a compact reporting layer for the synthetic training dataset, not a production data warehouse.

## Next Development Steps

1. run the complete database workflow in GitHub Actions
2. document and validate a Power BI connection against the reporting layer
3. build a compact Power BI report with explicit KPI definitions
4. evaluate versioned migrations and incremental load strategies when the project scope creates a real need

---

## Data and Credential Safety

Only synthetic training data belongs in this repository. The following remain excluded:

- `.env` files and real credentials
- personal or customer data
- private database dumps
- SQL Server database volumes
- local exports and backup files

See [`docs/project-notes.md`](docs/project-notes.md) for design decisions and [`docs/reporting-model.md`](docs/reporting-model.md) for the dimensional model specification.
