# Project Notes

This repository documents a local Microsoft SQL Server learning setup using Docker Desktop, DataGrip and SQL scripts.

It is part of the DataTideHH portfolio and supports practical learning in the context of Data/BI, relational databases and Microsoft-oriented data tooling.

## Purpose

The repository is intentionally small. It is not meant to be a production database project.

It is meant to demonstrate:

- local SQL Server setup with Docker
- connection workflow with DataGrip
- safe use of environment variables
- basic SQL checks and examples
- clean repository structure
- documentation of learning steps

## Technical Context

The project uses a local SQL Server container.

Important concept:

- SQL Server runs inside Docker.
- The host machine connects through a mapped port.
- Local credentials are stored in `.env`.
- `.env` is ignored by Git.
- Public documentation must not contain real passwords.

## Port Choice

The project uses host port `14333` instead of the default SQL Server port `1433`.

Reason:

- avoids conflicts with an existing local SQL Server installation
- makes the Docker-based environment easier to identify
- keeps the setup explicit in documentation

## Data Handling

This repository should only contain safe learning material.

Allowed:

- setup scripts
- example queries
- synthetic data
- public training examples
- documentation

Not allowed:

- real credentials
- private dumps
- personal data
- customer data
- database volumes
- generated local exports

## Current Scope

Current scope:

- Docker-based SQL Server environment
- DataGrip connection workflow
- basic SQL Server checks
- example SQL queries
- portfolio-oriented documentation

Out of scope for now:

- production deployment
- user and role management beyond local learning
- automated database migrations
- CI/CD pipelines
- cloud deployment
- private or sensitive datasets

## Future Improvements

Possible future improvements:

1. Add a small synthetic training database.
2. Add a simple star-schema example for BI learning.
3. Add a Python connection example.
4. Add a DataSpell or notebook example with pandas.
5. Add Power BI connection notes later.
