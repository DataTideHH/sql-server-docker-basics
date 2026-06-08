# SQL Server Docker Basics

A small Microsoft SQL Server learning repository using Docker Desktop, DataGrip and SQL scripts.

## Purpose

This repository documents a local SQL Server setup for learning SQL, relational database concepts, DataGrip workflows and Microsoft-oriented data tooling.

The project is part of my Data/BI learning path with a focus on SQL, data modelling, reporting workflows and the Microsoft Data Stack.

## What This Demonstrates

This repository demonstrates:

- local SQL Server setup with Docker
- safe use of `.env` for local credentials
- SQL Server connection workflow with DataGrip
- basic SQL Server checks
- structured SQL script organization
- documented learning steps for Data/BI workflows

## Stack

- Docker Desktop
- Microsoft SQL Server container
- DataGrip
- SQL scripts
- Python/DataSpell later
- Power BI later

## Current Status

Initial Docker-based SQL Server setup is working.

Verified:

- SQL Server container starts successfully
- SQL Server listens on host port `14333`
- `sqlcmd` is available inside the container
- connection test with `SELECT @@VERSION` works
- DataGrip connection works
- DPA training database scripts are included

Included:

- `docker-compose.yml`
- `.env.example`
- `.gitignore`
- basic project folders
- DataGrip workflow documentation
- SQL example scripts

Not included:

- real passwords
- `.env` files
- database volumes
- private data
- exported local data

## Repository Structure

    sql-server-docker-basics/
    ├── docker-compose.yml
    ├── .env.example
    ├── .gitignore
    ├── README.md
    ├── docs/
    │   ├── datagrip-workflow.md
    │   └── project-notes.md
    ├── sql/
    │   └── examples/
    │       ├── README.md
    │       ├── 01_basic_checks.sql
    │       └── 02_training_queries.sql
    └── notebooks/

## Environment Variables

Create a local `.env` file from `.env.example`:

    cp .env.example .env

Then change the password in `.env`.

The `.env` file is intentionally ignored by Git.

## Local Connection

Default local connection settings:

| Setting | Value |
|---|---|
| DBMS | Microsoft SQL Server |
| Host | 127.0.0.1 |
| Port | 14333 |
| User | sa |
| Password | local value from `.env` |

## DataGrip Workflow

The DataGrip workflow is documented in:

    docs/datagrip-workflow.md

## SQL Examples

Example scripts are available in:

    sql/examples/

Current examples:

- `01_basic_checks.sql`
- `02_training_queries.sql`

## Notes and Limitations

This repository is a local learning setup, not a production database project.

It should not contain:

- real credentials
- private dumps
- personal data
- customer data
- SQL Server database volumes
- generated local exports

## Planned Next Steps

Possible future improvements:

- add a small synthetic training database
- add a simple star-schema example for BI learning
- add Python/DataSpell connection example
- add optional pandas-based analysis notebook
- add Power BI connection notes later
