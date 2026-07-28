# Project Notes

## Purpose

This project provides a small, inspectable SQL Server environment for practical Data/BI work. It combines a Docker-based runtime with a normalized training database, synthetic data, enforced integrity rules, reporting queries, a dimensional reporting layer, PowerShell-based provisioning and documented client access.

The repository is intentionally limited to one local SQL Server workflow. It is not a production deployment template or a general-purpose data warehouse, but the implemented parts should still be reproducible, understandable and safe to publish.

## Current Implementation

The repository currently includes:

- a SQL Server 2022 container managed with Docker Compose
- a pinned SQL Server cumulative-update image
- a persistent local Docker volume
- configurable credentials, image and host port through `.env`
- a Docker healthcheck based on `sqlcmd`
- a PowerShell bootstrap for validation, startup, readiness and ordered SQL execution
- source-model verification and rollback-based negative integrity tests
- the `dpa_training` database and normalized `dpa` source schema
- a derived-result view for score percentages and pass status
- a `reporting` star schema with three dimensions and one fact table
- a transaction-based reporting upsert
- executable source-to-reporting reconciliation
- documented DataGrip and reporting-model workflows

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

Docker reporting a running container does not guarantee that SQL Server is ready to accept connections. The Compose healthcheck executes `SELECT 1`, and the PowerShell bootstrap waits for a healthy state before running setup scripts.

An unhealthy, exited or timed-out container causes the workflow to stop and print recent service logs.

### Synthetic data

The included learner and assessment data is synthetic. Stable learner and module codes make joins and repeatable inserts easier to inspect without using personal information.

### Derived pass status

The first model stored `passed` in `dpa.assessment_results` even though it was completely determined by `score` and the related assessment's `pass_score`.

The hardened source model removes that redundancy. `dpa.v_assessment_results` derives both `passed` and `score_percentage`. Before dropping the old column, the schema upgrade checks that every stored value agrees with the source score and threshold. A mismatch stops the upgrade instead of silently discarding contradictory data.

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

The source model enforces:

- unique learner and module codes
- one result per learner and assessment
- one assessment name per module

The last rule allows the same descriptive assessment name in different modules while preventing ambiguous duplicates inside one module.

### Executable negative tests

`sql/06_test_integrity_rules.sql` attempts seven invalid writes and confirms the expected database error for each one. Every test uses a transaction and rolls back any open transaction before checking the outcome.

The suite is designed to fail closed. A missing or unexpected error code causes the script to throw instead of treating an unverified write as success.

### Dimensional grain

The reporting model uses this declared fact grain:

> one row per learner and assessment

`reporting.fact_assessment_result` references:

- `reporting.dim_module`
- `reporting.dim_learner`
- `reporting.dim_assessment`

A unique constraint on `(assessment_key, learner_key)` enforces the grain. `source_result_id` is retained as a lineage key back to the normalized source.

### Surrogate keys and source lineage

Each dimension uses an identity-based surrogate key for star-schema relationships while also retaining its source identifier.

This separates reporting relationships from source primary keys without losing traceability. Unique constraints on the source identifiers prevent one source member from being loaded more than once.

### Reporting measures

The fact table stores the additive source measures:

- `score`
- `max_score`
- `pass_score`

It derives and persists:

- `score_percentage`
- `passed`

Persisting the computed values makes their definitions explicit in SQL Server and allows them to be included in reporting-oriented indexes. Required SQL session options are set explicitly in the schema and load scripts because indexed persisted computed columns depend on those settings.

### Transaction-based upsert

`sql/08_load_reporting_model.sql` updates existing reporting rows and inserts new ones inside one transaction.

The load:

- refreshes dimension attributes from the source
- preserves existing surrogate keys
- inserts new source members
- resolves every source result to all three dimension keys
- refreshes or inserts fact rows through `source_result_id`

The load does not automatically delete reporting rows that no longer exist in the source. This is deliberate: silent deletion is inappropriate for the current learning workflow. Exact reconciliation detects stale or additional rows and fails the run instead.

### Bidirectional reconciliation

`sql/09_verify_reporting_model.sql` uses row counts and bidirectional `EXCEPT` comparisons to prove that source and reporting values agree.

The verification covers:

- all three dimensions
- fact measures and lineage identifiers
- learner-assessment grain
- orphaned foreign keys
- trusted constraints and foreign keys
- persisted computed measures

Checking both directions matters. A source-minus-reporting comparison alone would detect missing rows but not unexpected additional reporting rows.

### Idempotent setup where practical

Database, schema, table and seed scripts use existence checks or `CREATE OR ALTER` where appropriate. Re-running the normal setup does not recreate existing source records or duplicate reporting rows.

The reporting upsert updates timestamps and values but preserves the star-schema row counts and surrogate-key relationships for the included dataset.

### Controlled schema evolution

The source schema contains one explicit upgrade from the earlier stored `passed` column to the derived-result view. The reporting schema was introduced as an additive extension.

This remains a bounded local workflow, not a general-purpose migration framework. Future non-trivial schema evolution should use a versioned migration approach rather than accumulating ad hoc upgrade blocks indefinitely.

### Separation of workflow and examples

The numbered scripts in `sql/` form one connected database workflow:

1. create the database
2. create or upgrade the relational source schema
3. insert synthetic source records
4. create the dimensional reporting schema
5. load the reporting model
6. run reporting-oriented source queries
7. verify the source model
8. test source integrity rules
9. reconcile the reporting model with the source

The scripts in `sql/examples/` remain standalone learning and diagnostic examples.

### Safe stop behaviour

The stop script preserves the named SQL Server data volume. Its optional removal mode removes the container and Compose network, but it deliberately does not add Docker's volume-removal flag.

Destroying the local database volume remains a separate manual action and is not part of the normal workflow.

## Validation Evidence

### Source-model integrity increment

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

The complete initialization was executed a second time with the same successful results.

### Dimensional reporting increment

The reporting increment was validated locally on Windows 11 with PowerShell 7.6.4 and Docker Desktop using the Linux engine against the existing persistent database volume.

The first successful load produced:

- 5 module dimension rows
- 5 learner dimension rows
- 5 assessment dimension rows
- 25 fact rows
- 21 passed fact rows
- average score percentage `68.12`
- source reconciliation result `1`
- reporting-model verification result `1`

The full initialization was then executed again. The second run produced the same counts and verification results without duplicate source or reporting rows.

This confirms repeatability for the included deterministic dataset and current upsert strategy.

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
- slowly changing dimension handling
- incremental, watermark-based or deletion-aware loading
- SQL Server integration tests in CI
- cloud deployment
- a finished Power BI report
- equivalent bootstrap scripts for macOS or Linux

The reporting model is a compact dimensional layer for one synthetic dataset, not a production enterprise warehouse.

## Planned Extensions

The next useful increments are:

1. end-to-end SQL Server integration tests in GitHub Actions
2. a reviewed Power BI connection based on the reporting layer
3. a compact Power BI report with explicit KPI definitions
4. a versioned migration and incremental-load approach when further project scope creates a real need

Each increment should remain separately reviewable and include a concrete verification step.
