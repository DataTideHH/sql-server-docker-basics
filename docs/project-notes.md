# Project Notes

## Purpose

This project provides a small, inspectable SQL Server environment for practical Data/BI work. It combines a Docker-based runtime with a normalized training database, synthetic data, analysis queries and documented client access.

The repository is intentionally limited to one local SQL Server workflow. It is not a production deployment template, but the implemented parts should still be reproducible, understandable and safe to publish.

## Current Implementation

The repository currently includes:

- a SQL Server 2022 container managed with Docker Compose
- a persistent local Docker volume
- configurable credentials and host port through `.env`
- a documented DataGrip connection workflow
- the `dpa_training` database and `dpa` schema
- four related tables for modules, learners, assessments and results
- repeatable synthetic seed data
- reporting queries for average scores, pass rates and learner performance
- standalone examples for environment checks and data-quality analysis

## Design Decisions

### Non-default host port

The container exposes SQL Server on host port `14333` while keeping the standard internal port `1433`.

This avoids conflicts with another local SQL Server installation and makes the Docker-based instance easier to identify in client configurations.

### Local credentials

The SQL Server password is supplied through a local `.env` file. The repository contains only `.env.example`; `.env` is excluded through `.gitignore`.

Credentials must not be copied into SQL scripts, documentation, screenshots or committed client configuration.

### Synthetic data

The included learner and assessment data is synthetic. Stable learner and module codes make joins and repeatable inserts easier to inspect without using personal information.

### Idempotent setup where practical

Database, schema, table and seed scripts use existence checks. Re-running the normal setup should not recreate existing objects or duplicate the included sample rows.

This is not yet a migration framework. Later schema changes will need an explicit strategy rather than relying only on `IF NOT EXISTS` checks.

### Separation of core workflow and examples

The numbered scripts in `sql/` form one connected database workflow:

1. create the database
2. create the relational schema
3. insert synthetic records
4. run reporting queries

The scripts in `sql/examples/` are standalone learning and diagnostic examples. In particular, the current data-quality example uses a temporary sales-order table and does not yet validate the core `dpa` model.

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

- unattended provisioning
- production user and role design
- automated schema migrations
- SQL Server integration tests in CI
- cloud deployment
- a dimensional reporting model
- a finished Power BI report

These are scope boundaries, not implied completed features.

## Planned Extensions

The next useful increments are:

1. PowerShell-based startup, readiness checks and ordered script execution
2. model-specific constraints and executable data-quality assertions
3. a small dimensional reporting layer with documented grain and KPI definitions
4. end-to-end SQL Server integration tests in GitHub Actions
5. a reviewed Power BI connection and report based on the reporting layer

Each increment should remain separately reviewable and should include a concrete verification step.
