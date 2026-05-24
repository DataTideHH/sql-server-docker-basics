# SQL Server Docker Basics

A small Microsoft SQL Server learning repository using Docker Desktop, DataGrip and DataSpell.

## Purpose

This repository documents a local SQL Server setup for learning SQL, relational database concepts, DataGrip workflows and Python/DataSpell database access.

The project is part of my Data/BI learning path with a focus on SQL, data modelling, reporting workflows and Microsoft-oriented data tooling.

## Stack

- Docker Desktop
- Microsoft SQL Server container
- DataGrip
- DataSpell
- Python later
- SQL scripts

## Current Status

Initial repository setup.

Included:

- docker-compose.yml
- .env.example
- .gitignore
- basic project folders

Not included:

- real passwords
- .env files
- database volumes
- private data
- exported local data

## Planned Structure

```text
sql-server-docker-basics/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── README.md
├── sql/
├── docs/
└── notebooks/
```

## Environment Variables

Create a local `.env` file from `.env.example`:

```zsh
cp .env.example .env
```

Then change the password in `.env`.

The `.env` file is intentionally ignored by Git.

## Planned Next Steps

- start SQL Server container
- verify container status
- connect with DataGrip
- create a small learning database
- add SQL scripts for schema and sample data
- connect from Python/DataSpell later
