# Reporting Model

## Purpose

The `reporting` schema provides a small dimensional layer for BI-oriented analysis. It is loaded from the normalized `dpa` source model and is designed to be inspected directly or connected to Power BI.

The model is intentionally compact. It demonstrates grain definition, surrogate keys, dimensional relationships, reproducible loading and source-to-report reconciliation without presenting the lab as a production data warehouse.

## Grain

`reporting.fact_assessment_result` contains exactly one row per learner and assessment.

This grain is enforced through a unique constraint on:

```text
assessment_key + learner_key
```

The fact also retains `source_result_id` as a unique lineage reference to `dpa.assessment_results`.

## Star Schema

```text
reporting.dim_module ───────┐
                            │
reporting.dim_learner ──────┼── reporting.fact_assessment_result
                            │
reporting.dim_assessment ───┘
```

### `reporting.dim_module`

One row per source learning module.

Key attributes:

- `module_key` — reporting surrogate key
- `source_module_id` — source-system lineage key
- `module_code`
- `module_name`
- `topic_area`

### `reporting.dim_learner`

One row per synthetic learner.

Key attributes:

- `learner_key` — reporting surrogate key
- `source_learner_id` — source-system lineage key
- `learner_code`
- `learner_name`

### `reporting.dim_assessment`

One row per assessment.

Key attributes:

- `assessment_key` — reporting surrogate key
- `source_assessment_id` — source-system lineage key
- `assessment_name`
- `assessment_date`

### `reporting.fact_assessment_result`

One row per learner and assessment.

Stored measures:

- `score`
- `max_score`
- `pass_score`

Persisted derived measures:

- `score_percentage`
- `passed`

`score_percentage` and `passed` are computed by SQL Server from the stored measures. They cannot drift independently from `score`, `max_score` or `pass_score`.

## Loading Strategy

`sql/08_load_reporting_model.sql` performs an upsert inside one transaction:

1. update existing dimensions from the relational source
2. insert missing dimension members
3. resolve source rows to reporting surrogate keys
4. update existing fact rows
5. insert missing fact rows

The load does not automatically remove reporting rows that no longer exist in the source. Instead, `sql/09_verify_reporting_model.sql` fails when source and reporting counts or values diverge. This avoids silent data removal in the normal lab workflow.

## Verification

The reporting verification checks:

- all expected tables and the detail view exist
- dimension and fact counts equal their relational sources
- dimension attributes reconcile in both directions
- every fact row resolves to valid dimension rows
- the learner-assessment grain contains no duplicates
- fact values reconcile row by row with `dpa.v_assessment_results`
- reporting check constraints and foreign keys are enabled and trusted
- `score_percentage` and `passed` are persisted computed columns

A successful verification returns:

```text
source_reconciliation_verified = 1
reporting_model_verified = 1
```

## Power BI Relationship Plan

The intended Power BI relationships are one-to-many, single direction:

```text
dim_module[module_key]         1 → * fact_assessment_result[module_key]
dim_learner[learner_key]       1 → * fact_assessment_result[learner_key]
dim_assessment[assessment_key] 1 → * fact_assessment_result[assessment_key]
```

The fact table should be the central table. The source-system IDs remain available for traceability but are not intended as report-facing relationship keys.

## Current Boundary

This is a local reporting layer for a controlled training dataset. It does not yet implement slowly changing dimensions, incremental-watermark processing, historical snapshots, orchestration, CI execution or a finished Power BI semantic model.