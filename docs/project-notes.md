# Project Notes

## Purpose

This project provides a small, inspectable SQL Server environment for practical Data/BI work. It combines a Docker-based runtime with a normalized training database, synthetic data, analysis queries, PowerShell-based provisioning and documented client access.

The repository is intentionally limited to one local SQL Server workflow. It is not a production deployment template, but the implemented parts should still be reproducible, understandable and safe to publish.

## Current Implementation

The repository currently includes:

- a SQL Server 2022 container managed with Docker Compose
- a pinned SQL Server cumulative-update image
- a persistent local Docker volume
- configurable credentials, image and host port through `.env`
- a Docker healthcheck based on `sqlcmd`
- a PowerShell bootstrap for validation, startup, readiness and ordered SQL execution
- a final SQL verification step for required tables and expected row counts
- a documented DataGrip connection workflow
- the `dpa_training` database and `dpa` schema
- four related tables for modules, learners, assessments and results
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

### Idempotent setup where practical

Database, schema, table and seed scripts use existence checks. Re-running the normal setup does not recreate existing objects or duplicate the included sample rows.

The verification script checks the resulting data state after every complete run. This is not a migration framework; later schema changes will need an explicit migration strategy rather than relying only on `IF NOT EXISTS` checks.

### Separation of core workflow and examples

The numbered scripts in `sql/` form one connected database workflow:

1. create the database
2. create the relational schema
3. insert synthetic records
4. run reporting queries
5. verify required objects and row counts

The scripts in `sql/examples/` are standalone learning and diagnostic examples. In particular, the current data-quality example uses a temporary sales-order table and does not yet validate the core `dpa` model.

### Safe stop behaviour

The stop script preserves the named SQL Server data volume. Its optional removal mode removes the container and Compose network, but it deliberately does not add Docker's volume-removal flag.

Destroying the local database volume remains a separate manual action and is not part of the normal workflow.

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
- automated schema migrations
- SQL Server integration tests in CI
- cloud deployment
- a dimensional reporting model
- a finished Power BI report
- equivalent bootstrap scripts for macOS or Linux

These are scope boundaries, not implied completed features.

## Planned Extensions

The next useful increments are:

1. model-specific constraints and executable data-quality assertions
2. a small dimensional reporting layer with documented grain and KPI definitions
3. end-to-end SQL Server integration tests in GitHub Actions
4. a reviewed Power BI connection and report based on the reporting layer

Each increment should remain separately reviewable and should include a concrete verification step.
