# GitHub Actions Integration Workflow

## Purpose

The workflow in `.github/workflows/sql-server-integration.yml` runs the complete SQL Server lab on a fresh GitHub-hosted runner. It reuses the repository's Docker Compose and PowerShell entry points instead of maintaining a separate CI-only provisioning implementation.

The CI goal is to prove that a clean machine can:

1. validate the PowerShell scripts
2. start the pinned SQL Server container
3. create and verify the relational source model
4. execute the negative integrity suite
5. create and load the dimensional reporting model
6. reconcile reporting data with the source
7. execute the complete workflow a second time without duplication or failure

## Triggers

The workflow runs on:

- pull requests to `main` when workflow, Compose, environment-template, PowerShell or SQL files change
- pushes to `main` for the same relevant paths
- manual `workflow_dispatch` runs

Documentation-only changes do not start the comparatively expensive SQL Server container job unless the workflow file itself is part of the change.

## Runner and Permissions

The job uses:

- `ubuntu-24.04`
- `actions/checkout@v6`
- `contents: read`
- a 20-minute job timeout
- concurrency cancellation for superseded runs on the same ref

The workflow does not require repository secrets or write permissions.

## Temporary Configuration

The local workflow expects a `.env` file. CI creates one at runtime with:

- a generated SQL Server system-administrator password
- the Developer edition
- host port `14333`
- the repository's pinned SQL Server image

The generated password is not committed. The temporary `.env` file is removed during the final cleanup step.

## Execution Sequence

```text
checkout
   │
   ├── report PowerShell, Docker and Compose versions
   ├── parse every scripts/*.ps1 file
   ├── create temporary .env
   │
   ▼
first complete initialization
   │
   ├── pull pinned SQL Server image
   ├── start container and wait for health
   ├── create or upgrade relational model
   ├── load deterministic source data
   ├── create and load star schema
   ├── verify source model
   ├── execute seven negative integrity tests
   └── reconcile reporting model
   │
   ▼
second complete initialization
   │
   └── repeat the same workflow with -SkipImagePull
   │
   ▼
cleanup
```

The second initialization is part of the same job and uses the same temporary Docker volume. This proves repeatability after the first load rather than only proving that a clean installation works once.

## Failure Diagnostics

When a previous step fails, the workflow prints:

- Docker Compose service and container state
- the latest 200 SQL Server service log lines

This preserves useful evidence in the Actions log while still allowing the final cleanup step to execute.

## Cleanup Behaviour

The final step always attempts to:

- stop and remove the Compose containers
- remove the Compose network
- remove the temporary `.env`

The command does not use Docker's volume-removal option. On a GitHub-hosted runner, the virtual machine and its remaining local storage are discarded after the job.

## Validation Evidence

The first pull-request run completed successfully on 28 July 2026.

Observed CI characteristics:

- GitHub-hosted Ubuntu 24.04.4 runner
- repository token limited to read access
- all PowerShell scripts parsed successfully
- first complete SQL Server workflow succeeded on a fresh runner
- second complete workflow succeeded for repeatability
- failure diagnostics were not needed
- cleanup completed successfully

The database assertions executed inside both complete runs included:

- 5 modules
- 5 learners
- 5 assessments
- 25 source results
- 21 derived passed results
- seven passed negative integrity tests
- 5 module dimension rows
- 5 learner dimension rows
- 5 assessment dimension rows
- 25 fact rows
- 21 passed fact rows
- average score percentage `68.12`
- source reconciliation result `1`
- reporting-model verification result `1`

## Boundaries

This workflow is an integration test for the repository's local lab. It is not:

- a production deployment pipeline
- a database backup strategy
- a release pipeline
- a cloud-hosted SQL Server deployment
- a substitute for versioned production migrations
