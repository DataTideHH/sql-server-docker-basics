# DataGrip Workflow

This document describes the intended DataGrip workflow for the SQL Server Docker Basics project.

The goal is to use JetBrains DataGrip as the main SQL client for working with a local Microsoft SQL Server container.

## Connection Context

The local SQL Server container is exposed on the host through a non-default port.

Default local connection settings:

| Setting | Value |
|---|---|
| DBMS | Microsoft SQL Server |
| Host | 127.0.0.1 |
| Port | 14333 |
| Authentication | SQL Server authentication |
| User | sa |
| Password | local value from `.env` |
| Database | select manually after connecting |

The `.env` file is intentionally ignored by Git and must not be committed.

## Basic DataGrip Setup

Recommended steps:

1. Open DataGrip.
2. Create a new data source.
3. Select Microsoft SQL Server.
4. Set host to `127.0.0.1`.
5. Set port to `14333`.
6. Use SQL Server authentication.
7. Enter user `sa`.
8. Enter the local password from `.env`.
9. Test the connection.
10. Download the required driver if DataGrip asks for it.
11. Apply and save the connection.

## First Connection Checks

After connecting, run this SQL statement:

    SELECT @@VERSION AS sql_server_version;

Then check available databases:

    SELECT name
    FROM sys.databases
    ORDER BY name;

## Working with Scripts

Recommended DataGrip workflow:

1. Open the repository folder as a project.
2. Open SQL files from the `sql/` folder.
3. Select the correct data source in the top-right run configuration.
4. Execute scripts block by block.
5. Keep setup scripts, examples and experiments separated.
6. Do not commit local scratch files or exported private data.

## Recommended Script Structure

Suggested structure:

    sql/
    ├── examples/
    │   ├── 01_basic_checks.sql
    │   └── 02_training_queries.sql
    └── README.md

Possible future structure:

    sql/
    ├── setup/
    ├── examples/
    ├── exercises/
    └── solutions/

## Safety Notes

Do not commit:

- `.env`
- real passwords
- SQL Server database volumes
- private dumps
- personal or confidential data exports
- generated local backup files

For public portfolio purposes, scripts should use training data, synthetic data or clearly non-sensitive examples only.

## Portfolio Purpose

This workflow demonstrates:

- local Microsoft SQL Server setup with Docker
- SQL client usage with DataGrip
- reproducible setup documentation
- safe handling of local credentials
- structured SQL script organization
