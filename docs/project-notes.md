# Project Notes

## Purpose

This project provides a small, inspectable SQL Server environment for practical Data/BI work. It combines a Docker-based runtime with a normalized training database, synthetic data, reporting queries, PowerShell-based provisioning, enforced integrity rules and documented client access.

The repository is intentionally limited to one local SQL Server workflow. It is not a production deployment template, but the implemented parts should still be reproducible, understandable and safe to publish.

## Current Implementation

The repository currently includes:

- a SQL Server 2022 container managed with Docker Compose
- a pinned SQL Server cumulative-update image
- a persistent local Docker volume
- configurable credentials, image and host port through `.env`
- a Docker healthcheck based on `sqlcmd`
- a PowerShell bootstrap for validation, startup, readiness and ordered SQL execution
- a final SQL verification step for required objects, integrity rules and expected data
- a rollback-based negative integrity test suite
- a documented DataGrip connection workflow
- the `dpa_training` database and `dpa` schema
- four related tables for modules, learners, assessments and results
- a derived-result view for score percentages and pass status
- repeatable synthetic seed data
- reporting queries for average scores, pass rates and learner performance
- standalone examples for environment checks and data-quality analysis

## Design Decisions

### Pinned SQL Server image

The Compose file uses a named SQL Server 2022 cumulative-update image rather than the floating `2022-latest` tag.

This makes local runs more predictable and keeps image changes explicit in version control. Updating the image remains a deliberate maintenance task.

### Non-default host port

The container exposes SQL Server on host port `14333` while keeping the standard internal port `1433`.

This avoids conflicts with another local SQL Server installation and makes the Docker-based instance easier to identify in client configurations.

### Local credentials

The SQL Server password is supplied through a local `.env` file. The repository contains only `.env.example`; `.env` is excluded through `.gitignore`.

The bootstrap checks that the password value exists and rejects the public placeholder. Credentials must not be copied into SQL scripts, documentation, screenshots or committed client configuration.

### Container-side SQL execution

The repository's `sql/` directory is mounted read-only at `/workspace/sql` inside the container. PowerShell invokes the container's `sqlcmd` installation rather than requiring a separate host installation.

This reduces host prerequisites and ensures that setup and verification use the SQL tooling shipped with the selected container image.

### Readiness before execution

Docker reporting a running container does not guarantee that SQL Server is ready to accept connections. The Compose healthcheck executes `SELECT 1`, and the PowerShell bootstrap waits for a healthy state before running any setup script.

An unhealthy, exited or timed-out container causes the workflow to stop and print recent service logs.

### Synthetic data

The included learner and assessment data is synthetic. Stable learner and module codes make joins and repeatable inserts easier to inspect without using personal information.

### Derived pass status

The first model stored `passed` in `dpa.assessment_results` even though it was completely determined by `score` and the related assessment's `pass_score`.

The hardened model removes that redundancy. `dpa.v_assessment_results` now derives both `passed` and `score_percentage`. Before dropping the old column, the schema upgrade checks that every stored value agrees with the source score and threshold. A mismatch stops the upgrade instead of silently discarding contradictory data.

### Check constraints and cross-table rules

Rules that depend on columns from the same row are implemented as named and trusted check constraints:

- required text values cannot be blank
- `max_score` must be positive
- `pass_score` must be between zero and `max_score`
- result scores cannot be negative

Rules that compare values across tables cannot be expressed as ordinary SQL Server check constraints. Two set-based triggers therefore enforce that:

- a result score cannot exceed its assessment maximum
- an assessment maximum cannot be reduced below an existing result

The triggers inspect all affected rows through the `inserted` pseudo-table rather than assuming one-row statements.

### Business-key uniqueness

In addition to unique learner and module codes, the model enforces:

- one result per learner and assessment
- one assessment name per module

The second rule deliberately allows the same descriptive assessment name in different modules while preventing ambiguous duplicates inside one module.

### Executable negative tests

`sql/06_test_integrity_rules.sql` attempts seven invalid writes and confirms the expected database error for each one. Every test uses a transaction and rolls back any open transaction before checking the outcome.

The suite is designed to fail closed. A missing error code or an unexpected error code causes the script to throw instead of treating an unverified write as success.

### Idempotent setup where practical

Database, schema, table and seed scripts use existence checks or `CREATE OR ALTER` where appropriate. Re-running the normal setup does not recreate existing records or duplicate the included sample rows.

The verification and negative tests run after every complete initialization. This remains a bounded local workflow, not a general-purpose migration framework.

### Controlled schema upgrade

The schema script contains one explicit upgrade from the earlier stored `passed` column to the derived-result view. The upgrade preserves the existing database volume and data, validates consistency first and only then removes the redundant column.

This controlled upgrade was tested against an existing persistent database volume. A second complete run after migration confirmed that the new schema remains repeatable. Future non-trivial schema evolution should use a versioned migration approach rather than accumulating ad hoc upgrade blocks indefinitely.

### Separation of core workflow and examples

The numbered scripts in `sql/` form one connected database workflow:

1. create the database
2. create or upgrade the relational schema
3. insert synthetic records
4. run reporting queries
5. verify required objects, rules and expected data
6. test integrity rules with rollback-based invalid writes

The scripts in `sql/examples/` remain standalone learning and diagnostic examples. The core model now has its own executable integrity suite, so the temporary sales-order quality example is no longer the repository's only data-quality evidence.

### Safe stop behaviour

The stop script preserves the named SQL Server data volume. Its optional removal mode removes the container and Compose network, but it deliberately does not add Docker's volume-removal flag.

Destroying the local database volume remains a separate manual action and is not part of the normal workflow.

## Validation Evidence

The integrity increment was validated locally on Windows 11 with PowerShell 7 and Docker Desktop using the Linux engine.

Observed results after upgrading the existing database:

- all seed statements reported `0 rows affected`
- 5 modules, 5 learners, 5 assessments and 25 results remained present
- 21 passed results were derived from score and threshold
- setup verification returned `1`
- integrity-rule verification returned `1`
- seven invalid writes were rejected with their expected error classes
- the derived-outcome test returned `1`
- the complete integrity suite returned `1`

The complete initialization was then executed a second time with the same successful results, confirming repeatability after the schema change.

## Data Handling Rules

Allowed content:

- schema and setup scripts
- synthetic records
- public training examples
- documentation
- reproducible query results that contain no private data

Excluded content:

- real credentials or `.env` files
- personal or customer data
- private database dumps
- Docker database volumes
- local exports and backup files
- screenshots that expose local credentials or unrelated private information

## Current Boundaries

The repository does not currently include:

- production deployment or high availability
- production user and role design
- a general-purpose automated migration framework
- SQL Server integration tests in CI
- cloud deployment
- a dimensional reporting model
- a finished Power BI report
- equivalent bootstrap scripts for macOS or Linux

These are scope boundaries, not implied completed features.

## Planned Extensions

The next useful increments are:

1. a small dimensional reporting layer with documented grain and KPI definitions
2. end-to-end SQL Server integration tests in GitHub Actions
3. a reviewed Power BI connection and report based on the reporting layer
4. a versioned migration approach when further schema evolution creates a real need

Each increment should remain separately reviewable and should include a concrete verification step.
