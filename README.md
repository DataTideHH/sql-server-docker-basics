# SQL Server Docker Basics

**Microsoft SQL Server 2022 · Docker Desktop · PowerShell 7 · T-SQL · relational modelling · data integrity · reporting queries**

This repository is a compact SQL Server analytics lab. It provides a reproducible local database environment, a normalized training model, synthetic seed data, reporting-oriented T-SQL queries and a PowerShell workflow for startup, readiness checks, ordered execution, verification and executable integrity tests.

It is part of my Data/BI portfolio during the IHK retraining program in Data and Process Analysis. The project is deliberately bounded: the current focus is a reliable relational foundation with enforced business rules that can later support a dimensional reporting layer, CI-based integration tests and Power BI.

---

## Project at a Glance

| Area | Current evidence |
|---|---|
| SQL Server environment | SQL Server 2022 runs in Docker with an explicit host-port mapping, persistent local volume and healthcheck |
| Provisioning | PowerShell validates Docker and `.env`, starts the service, waits for readiness and executes the SQL workflow in order |
| Configuration | Local credentials are supplied through `.env`; the file is excluded from version control |
| Relational model | Four related tables with primary keys, foreign keys, uniqueness constraints and validated required values |
| Derived outcome | Pass status and score percentage are derived in `dpa.v_assessment_results` rather than stored redundantly |
| Cross-table integrity | Triggers prevent scores above the assessment maximum and invalid reductions of an existing maximum |
| Sample data | Synthetic modules, learners, assessments and results inserted with repeatable `NOT EXISTS` checks |
| Analysis | Joins, percentage-based averages, pass rates, learner summaries and below-target flags |
| Verification | A final SQL script checks required objects, constraints, triggers, row counts and derived outcomes |
| Negative tests | Seven transaction-based tests prove that invalid writes are rejected and rolled back |
| SQL client workflow | Documented DataGrip connection and script execution process |

## Review Path

A quick technical review can follow these files in order:

1. [`docker-compose.yml`](docker-compose.yml) — pinned SQL Server image, volume, bind mount and healthcheck
2. [`scripts/Initialize-Lab.ps1`](scripts/Initialize-Lab.ps1) — end-to-end local bootstrap
3. [`scripts/SqlServerLab.Common.ps1`](scripts/SqlServerLab.Common.ps1) — shared Docker, configuration and readiness functions
4. [`sql/02_create_schema.sql`](sql/02_create_schema.sql) — schema, upgrade path, constraints, triggers and derived-result view
5. [`sql/03_insert_sample_data.sql`](sql/03_insert_sample_data.sql) — deterministic synthetic seed data
6. [`sql/04_analysis_queries.sql`](sql/04_analysis_queries.sql) — reporting-oriented queries based on the derived-result view
7. [`sql/05_verify_setup.sql`](sql/05_verify_setup.sql) — executable setup and integrity-object verification
8. [`sql/06_test_integrity_rules.sql`](sql/06_test_integrity_rules.sql) — negative tests for enforced database rules
9. [`scripts/Test-DataIntegrity.ps1`](scripts/Test-DataIntegrity.ps1) — PowerShell entry point for the integrity suite

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
                ├── create or upgrade schema
                ├── enforce constraints and triggers
                ├── insert synthetic data
                ├── run reporting queries
                ├── verify objects and expected data
                └── run rollback-based negative tests
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
- final verification of database objects, rules and row counts
- execution of rollback-based negative integrity tests
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
- unique assessment names within a module
- non-empty required text values
- positive assessment maxima
- pass thresholds between zero and the assessment maximum
- non-negative result scores

### Derived outcome view

`dpa.v_assessment_results` joins each result to its assessment and derives:

- `score_percentage` from `score / max_score`
- `passed` from `score >= pass_score`

The earlier stored `passed` column was removed after an upgrade check confirmed that every existing value agreed with the underlying score and threshold. This removes a redundant field that could otherwise contradict the source values.

### Cross-table integrity

A row-level check constraint cannot compare a result with values stored in another table. Two set-based triggers therefore enforce the remaining rules:

- an inserted or updated result cannot exceed its assessment's `max_score`
- an assessment's `max_score` cannot be lowered below any existing result

Both triggers evaluate all rows in the `inserted` pseudo-table and fail the complete statement on violations.

### Reporting queries

The core analysis script reads from `dpa.v_assessment_results` and includes:

- a detailed assessment result set with score percentage and pass status
- average score percentage and pass rate by module
- learner-level performance summaries
- modules flagged below an 80 percent pass-rate target

### Verification

`sql/05_verify_setup.sql` stops the workflow when required tables, the view, named constraints or triggers are missing. It also verifies the expected synthetic data:

| Metric | Expected value |
|---|---:|
| learning modules | 5 |
| learners | 5 |
| assessments | 5 |
| assessment results | 25 |
| passed results | 21 |

The verification also checks that:

- no score is negative or above its assessment maximum
- every pass status in the view matches `score >= pass_score`
- every score percentage matches the underlying score and maximum
- all expected constraints and triggers are enabled and trusted

### Executable integrity tests

`sql/06_test_integrity_rules.sql` deliberately attempts invalid writes and expects the database to reject them:

1. set `max_score` to zero
2. set `pass_score` above `max_score`
3. set a result score below zero
4. set a result score above the assessment maximum
5. lower an assessment maximum below an existing result
6. create a duplicate learner-assessment result
7. duplicate an assessment name within the same module

Each test runs inside a transaction and rolls back any open transaction before evaluating the expected error number. The script fails closed: a write that unexpectedly succeeds causes the suite to throw an error.

The complete workflow was validated locally on Windows 11 with PowerShell 7 and Docker Desktop against an existing persistent database volume. The upgrade completed without data loss, and a second complete run confirmed repeatability with unchanged counts and all integrity tests passing again.

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
│   ├── Test-DataIntegrity.ps1
│   └── Test-LabConnection.ps1
└── sql/
    ├── 01_create_database.sql
    ├── 02_create_schema.sql
    ├── 03_insert_sample_data.sql
    ├── 04_analysis_queries.sql
    ├── 05_verify_setup.sql
    ├── 06_test_integrity_rules.sql
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

The script pulls the configured image, starts SQL Server, waits for a healthy container, executes the numbered workflow, verifies the database state and runs the negative integrity tests.

For later runs, the image pull can be skipped:

```powershell
& ".\scripts\Initialize-Lab.ps1" -SkipImagePull
```

### 3. Verify the current database state

```powershell
& ".\scripts\Test-LabConnection.ps1"
```

### 4. Run the integrity suite separately

```powershell
& ".\scripts\Test-DataIntegrity.ps1"
```

A successful result reports seven passed negative tests, one derived-outcome test and an overall suite result of `1`.

### 5. Run selected SQL scripts

```powershell
& ".\scripts\Invoke-SqlScript.ps1" -Path @(
    "sql/03_insert_sample_data.sql",
    "sql/04_analysis_queries.sql"
)
```

Only SQL files inside the repository's `sql/` directory are accepted.

### 6. Connect with a SQL client

| Setting | Value |
|---|---|
| DBMS | Microsoft SQL Server |
| Host | `127.0.0.1` |
| Port | `14333` |
| User | `sa` |
| Password | local value from `.env` |
| Database | `dpa_training` |

The detailed DataGrip procedure is documented in [`docs/datagrip-workflow.md`](docs/datagrip-workflow.md).

### 7. Stop the lab

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
- CI-based SQL Server integration tests
- a dimensional data mart
- a finished Power BI report
- Azure or Microsoft Fabric deployment
- a macOS or Linux bootstrap equivalent to the PowerShell workflow

The schema script contains one controlled in-place upgrade for the earlier `passed` column, but this is not presented as a replacement for a versioned migration tool.

Those boundaries are intentional. Each later extension should add an executable capability and a verifiable result rather than only another technology label.

## Next Development Steps

1. add a small dimensional reporting layer for Power BI
2. run the complete database workflow in GitHub Actions
3. document and validate a Power BI connection against the reporting layer
4. evaluate a versioned migration approach when the schema begins to evolve further

---

## Data and Credential Safety

Only synthetic training data belongs in this repository. The following remain excluded:

- `.env` files and real credentials
- personal or customer data
- private database dumps
- SQL Server database volumes
- local exports and backup files

See [`docs/project-notes.md`](docs/project-notes.md) for the current design decisions and scope notes.
