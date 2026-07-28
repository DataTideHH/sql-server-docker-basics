# Project Notes

## Purpose

This project provides a small, inspectable SQL Server environment for practical Data/BI work. It combines a Docker-based runtime with a normalized training database, synthetic data, enforced integrity rules, a dimensional reporting layer, PowerShell-based provisioning and end-to-end GitHub Actions integration.

The repository is not a production deployment template or enterprise data warehouse. Its implemented parts are intended to be reproducible, understandable, testable and safe to publish.

## Current Implementation

The repository includes:

- SQL Server 2022 managed with Docker Compose
- a pinned cumulative-update image
- a persistent named volume for local use
- runtime configuration through `.env`
- a `sqlcmd`-based healthcheck
- a PowerShell bootstrap for validation, startup, readiness and ordered execution
- a normalized `dpa` source schema
- a derived-result view for percentages and pass status
- named constraints and set-based cross-table triggers
- seven rollback-based negative integrity tests
- a `reporting` star schema with three dimensions and one fact table
- a transaction-based reporting upsert
- executable source-to-reporting reconciliation
- a GitHub Actions workflow that executes the complete lab twice
- documentation for DataGrip, the reporting model and CI

## Design Decisions

### Pinned SQL Server image

The Compose file uses an explicit SQL Server 2022 cumulative-update image instead of the floating `2022-latest` tag.

This keeps image changes reviewable and makes local and CI runs more predictable. Updating the image remains a deliberate maintenance task.

### Non-default host port

The container exposes SQL Server on host port `14333` while retaining internal port `1433`.

This avoids collisions with another local SQL Server installation and makes the Docker instance easy to identify in client configurations.

### Local credentials

The SQL Server password is supplied through `.env`. The repository contains only `.env.example`; `.env` is excluded through `.gitignore`.

The bootstrap verifies that the password exists and rejects public example values. Credentials must not be copied into scripts, documentation, screenshots or committed client settings.

### Container-side SQL execution

The repository's `sql/` directory is mounted read-only at `/workspace/sql`. PowerShell invokes the container's `sqlcmd` binary rather than requiring a host installation.

This reduces host prerequisites and ensures that setup and verification use the SQL tooling included in the selected container image.

### Readiness before execution

A running container is not necessarily ready to accept SQL connections. Docker Compose therefore uses a `SELECT 1` healthcheck, and the PowerShell bootstrap waits for the container to become healthy before executing database scripts.

An unhealthy, exited, dead or timed-out container causes a non-zero failure and prints recent service logs.

### Synthetic data

All learner, module, assessment and result data is synthetic. Stable codes support repeatable joins and inserts without exposing personal information.

### Derived pass status

The first source model stored `passed` even though the value was completely determined by `score` and the related `pass_score`.

The hardened model removes that redundancy. `dpa.v_assessment_results` derives both `passed` and `score_percentage`. Before the stored column is removed, the controlled upgrade checks that every existing value agrees with the source score and threshold.

### Check constraints and cross-table rules

Rules that depend on one row are implemented as named and trusted check constraints:

- required text cannot be blank
- `max_score` must be positive
- `pass_score` must be between zero and `max_score`
- result scores cannot be negative

Rules that compare values across tables require set-based triggers:

- a result cannot exceed its assessment maximum
- an assessment maximum cannot be reduced below an existing result

The triggers evaluate all rows in the `inserted` pseudo-table and fail the complete statement on a violation.

### Business-key uniqueness

The source model enforces:

- unique learner codes
- unique module codes
- one result per learner and assessment
- one assessment name per module

The last rule permits the same descriptive assessment name in different modules while preventing ambiguous duplicates within one module.

### Executable negative tests

`sql/06_test_integrity_rules.sql` attempts seven invalid writes and confirms the expected SQL Server error class for each one.

Every test uses a transaction and rolls back any open transaction before evaluating the outcome. The suite fails closed: missing or unexpected errors cause the script to throw.

### Dimensional grain

The declared fact grain is:

> one row per learner and assessment

`reporting.fact_assessment_result` references:

- `reporting.dim_module`
- `reporting.dim_learner`
- `reporting.dim_assessment`

A unique constraint on `(assessment_key, learner_key)` enforces the grain. `source_result_id` provides lineage back to the normalized source.

### Surrogate keys and source lineage

Each dimension uses an identity-based surrogate key while retaining its source identifier.

This separates reporting relationships from source primary keys without losing traceability. Unique constraints on source identifiers prevent duplicate dimension members.

### Reporting measures

The fact table stores:

- `score`
- `max_score`
- `pass_score`

It derives and persists:

- `score_percentage`
- `passed`

Persisted computed columns make the definitions explicit and allow reporting indexes to include the results. The required SQL session options are set explicitly in schema and load scripts.

### Transaction-based upsert

`sql/08_load_reporting_model.sql` updates existing reporting rows and inserts new rows inside one transaction.

The load:

- refreshes dimension attributes
- preserves surrogate keys
- inserts new source members
- resolves every source result to all three dimensions
- refreshes or inserts facts through `source_result_id`

The load does not automatically delete reporting rows. Exact reconciliation exposes stale or additional rows instead of silently removing them.

### Bidirectional reconciliation

`sql/09_verify_reporting_model.sql` combines row counts with bidirectional `EXCEPT` checks.

The verification covers:

- all dimensions
- fact measures and lineage
- learner-assessment grain
- orphaned foreign keys
- trusted constraints and foreign keys
- persisted computed measures

Checking both directions detects both missing reporting rows and unexpected additional reporting rows.

### Idempotent setup where practical

Database, schema, table and seed scripts use existence checks or `CREATE OR ALTER` where appropriate. Re-running the complete workflow does not duplicate source records or reporting facts.

The reporting upsert refreshes values and timestamps while preserving dimension keys and row counts for the current dataset.

### Controlled schema evolution

The source schema contains one explicit upgrade from a stored `passed` column to the derived-result view. The reporting schema was introduced as an additive extension.

This remains a bounded lab workflow, not a general-purpose migration framework. Future non-trivial evolution should use versioned migrations rather than accumulating ad hoc upgrade blocks.

### GitHub Actions runner choice

The integration workflow uses `ubuntu-24.04` rather than a floating runner label.

This makes the operating-system generation explicit while still using a supported GitHub-hosted image. The same PowerShell scripts used locally run directly on the Linux runner; SQL execution remains inside the SQL Server container.

### Restricted CI permissions

The workflow declares:

```yaml
permissions:
  contents: read
```

No write permission or repository secret is required. The workflow only checks out source code and runs the local lab.

### Temporary CI configuration

CI generates a fresh SQL Server administrator password and writes a temporary `.env` at runtime.

The password is not committed, and the temporary file is removed during cleanup. This avoids storing a reusable database credential in GitHub repository secrets for a disposable integration-test database.

### Fresh-run and repeatability coverage

The CI job invokes the complete `Initialize-Lab.ps1` workflow twice:

1. first run with image pull on a fresh runner
2. second run against the same temporary database with `-SkipImagePull`

The first run proves clean provisioning. The second proves that schema creation, seed logic, reporting upsert and all verification steps remain repeatable.

### Failure diagnostics

When the job fails, GitHub Actions prints:

- Compose service and container state
- the latest 200 SQL Server log lines

The diagnostics step precedes unconditional cleanup so failure evidence remains available in the Actions log.

### CI cleanup

The final workflow step always attempts to remove the Compose containers and network and then deletes the temporary `.env`.

The command deliberately does not use the Docker volume-removal option. GitHub discards the hosted runner after the job, while the repository's normal safety rule remains explicit.

### Separation of workflow and examples

The numbered scripts in `sql/` form one connected database workflow:

1. create the database
2. create or upgrade the source schema
3. insert synthetic source data
4. create the dimensional schema
5. load the reporting model
6. run reporting-oriented source queries
7. verify the source model
8. test source integrity rules
9. reconcile reporting with source

Scripts under `sql/examples/` remain standalone learning and diagnostic examples.

### Safe local stop behaviour

The local stop script preserves the named SQL Server volume. Its optional removal mode removes only the container and Compose network.

Destroying the local volume remains a separate manual operation and is not part of the normal workflow.

## Validation Evidence

### Source-model integrity increment

The source integrity increment was validated locally on Windows 11 with PowerShell 7 and Docker Desktop using the Linux engine.

Observed results:

- all repeated seed statements returned `0 rows affected`
- 5 modules
- 5 learners
- 5 assessments
- 25 results
- 21 derived passed results
- setup verification `1`
- integrity-rule verification `1`
- seven rejected invalid writes
- derived-outcome test `1`
- complete integrity suite `1`

A second complete run produced the same results.

### Dimensional reporting increment

The reporting increment was validated locally on Windows 11 with PowerShell 7.6.4 and Docker Desktop against the existing persistent database volume.

Both complete runs produced:

- 5 module dimension rows
- 5 learner dimension rows
- 5 assessment dimension rows
- 25 fact rows
- 21 passed fact rows
- average score percentage `68.12`
- source reconciliation `1`
- reporting-model verification `1`
- no duplicate source or reporting rows

### GitHub Actions integration increment

The first pull-request CI run completed successfully on 28 July 2026.

Observed runner and permission evidence:

- GitHub-hosted Ubuntu 24.04.4
- repository token limited to `contents: read`
- `actions/checkout@v6`
- every PowerShell script parsed successfully

Observed execution evidence:

- fresh-run initialization succeeded
- source verification succeeded
- all seven negative integrity tests succeeded
- reporting reconciliation succeeded
- second complete initialization succeeded
- failure diagnostics were skipped because no failure occurred
- cleanup succeeded

This provides an independent clean-machine check in addition to the local Windows validation.

## Data Handling Rules

Allowed content:

- schema and setup scripts
- synthetic records
- public training examples
- workflow definitions
- documentation
- reproducible outputs containing no private data

Excluded content:

- real credentials or `.env` files
- personal or customer data
- private database dumps
- Docker database volumes
- local exports and backups
- screenshots exposing credentials or unrelated private information

## Current Boundaries

The repository does not include:

- production deployment or high availability
- production user and role design
- a general-purpose automated migration framework
- slowly changing dimensions
- incremental, watermark-based or deletion-aware loading
- backup and restore automation
- cloud deployment
- a finished Power BI report
- a release or deployment pipeline

The reporting model remains a compact dimensional layer for one synthetic dataset. The GitHub Actions workflow is an integration test for that lab, not a production deployment mechanism.

## Planned Extensions

The next useful increments are:

1. a reviewed Power BI connection based on the reporting layer
2. a compact Power BI report with explicit KPI definitions
3. portfolio screenshots or a short demo
4. versioned migrations and incremental loading when additional scope creates a real need

Each increment should remain separately reviewable and include concrete verification evidence.
