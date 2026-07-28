# SQL Examples

This folder contains standalone SQL Server examples for checking the local environment and exploring common Data/BI query patterns.

These files are separate from the connected `dpa_training` workflow in the parent `sql/` directory. They can be run individually after connecting to the local SQL Server instance.

## Files

| File | Purpose |
|---|---|
| `01_basic_checks.sql` | Inspect the SQL Server version, current database, login context and available user tables |
| `02_training_queries.sql` | Review metadata and reusable patterns for row counts, grouped aggregations and joins |
| `03_data_quality_checks.sql` | Demonstrate missing-value, duplicate-key and invalid-range checks with a temporary sales-order table |

## How to Use

1. Start the SQL Server container.
2. Connect with DataGrip or another SQL Server client.
3. Open one script at a time.
4. Select the intended data source and database context.
5. Run the statements block by block and inspect the result sets.

## Scope

The examples are designed for inspection and practice. They do not modify the core `dpa_training` model unless a script explicitly states otherwise.

The data-quality example is self-contained and intentionally includes invalid rows so that each check returns a visible result. Model-specific quality assertions for the `dpa` schema are planned separately.