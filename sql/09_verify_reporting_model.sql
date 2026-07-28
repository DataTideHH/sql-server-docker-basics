USE dpa_training;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'reporting.dim_module', N'U') IS NULL
    THROW 51300, 'Missing table: reporting.dim_module', 1;

IF OBJECT_ID(N'reporting.dim_learner', N'U') IS NULL
    THROW 51300, 'Missing table: reporting.dim_learner', 1;

IF OBJECT_ID(N'reporting.dim_assessment', N'U') IS NULL
    THROW 51300, 'Missing table: reporting.dim_assessment', 1;

IF OBJECT_ID(N'reporting.fact_assessment_result', N'U') IS NULL
    THROW 51300, 'Missing table: reporting.fact_assessment_result', 1;

IF OBJECT_ID(N'reporting.v_assessment_result_detail', N'V') IS NULL
    THROW 51300, 'Missing view: reporting.v_assessment_result_detail', 1;
GO

DECLARE @source_module_count INT = (SELECT COUNT(*) FROM dpa.learning_modules);
DECLARE @source_learner_count INT = (SELECT COUNT(*) FROM dpa.learners);
DECLARE @source_assessment_count INT = (SELECT COUNT(*) FROM dpa.assessments);
DECLARE @source_result_count INT = (SELECT COUNT(*) FROM dpa.assessment_results);

DECLARE @reporting_module_count INT = (SELECT COUNT(*) FROM reporting.dim_module);
DECLARE @reporting_learner_count INT = (SELECT COUNT(*) FROM reporting.dim_learner);
DECLARE @reporting_assessment_count INT = (SELECT COUNT(*) FROM reporting.dim_assessment);
DECLARE @reporting_result_count INT = (SELECT COUNT(*) FROM reporting.fact_assessment_result);

IF @reporting_module_count <> @source_module_count
    THROW 51301, 'Module dimension count does not match the relational source.', 1;

IF @reporting_learner_count <> @source_learner_count
    THROW 51302, 'Learner dimension count does not match the relational source.', 1;

IF @reporting_assessment_count <> @source_assessment_count
    THROW 51303, 'Assessment dimension count does not match the relational source.', 1;

IF @reporting_result_count <> @source_result_count
    THROW 51304, 'Fact row count does not match the relational source.', 1;
GO

IF EXISTS (
    SELECT
        module_id,
        module_code,
        module_name,
        topic_area
    FROM dpa.learning_modules
    EXCEPT
    SELECT
        source_module_id,
        module_code,
        module_name,
        topic_area
    FROM reporting.dim_module
)
OR EXISTS (
    SELECT
        source_module_id,
        module_code,
        module_name,
        topic_area
    FROM reporting.dim_module
    EXCEPT
    SELECT
        module_id,
        module_code,
        module_name,
        topic_area
    FROM dpa.learning_modules
)
    THROW 51305, 'Module dimension values do not match the relational source.', 1;
GO

IF EXISTS (
    SELECT
        learner_id,
        learner_code,
        learner_name
    FROM dpa.learners
    EXCEPT
    SELECT
        source_learner_id,
        learner_code,
        learner_name
    FROM reporting.dim_learner
)
OR EXISTS (
    SELECT
        source_learner_id,
        learner_code,
        learner_name
    FROM reporting.dim_learner
    EXCEPT
    SELECT
        learner_id,
        learner_code,
        learner_name
    FROM dpa.learners
)
    THROW 51306, 'Learner dimension values do not match the relational source.', 1;
GO

IF EXISTS (
    SELECT
        assessment_id,
        assessment_name,
        assessment_date
    FROM dpa.assessments
    EXCEPT
    SELECT
        source_assessment_id,
        assessment_name,
        assessment_date
    FROM reporting.dim_assessment
)
OR EXISTS (
    SELECT
        source_assessment_id,
        assessment_name,
        assessment_date
    FROM reporting.dim_assessment
    EXCEPT
    SELECT
        assessment_id,
        assessment_name,
        assessment_date
    FROM dpa.assessments
)
    THROW 51307, 'Assessment dimension values do not match the relational source.', 1;
GO

IF EXISTS (
    SELECT 1
    FROM reporting.fact_assessment_result f
    LEFT JOIN reporting.dim_module m
        ON m.module_key = f.module_key
    LEFT JOIN reporting.dim_learner l
        ON l.learner_key = f.learner_key
    LEFT JOIN reporting.dim_assessment a
        ON a.assessment_key = f.assessment_key
    WHERE m.module_key IS NULL
       OR l.learner_key IS NULL
       OR a.assessment_key IS NULL
)
    THROW 51308, 'The reporting fact contains orphaned dimension keys.', 1;
GO

IF EXISTS (
    SELECT
        assessment_key,
        learner_key
    FROM reporting.fact_assessment_result
    GROUP BY
        assessment_key,
        learner_key
    HAVING COUNT(*) > 1
)
    THROW 51309, 'The reporting fact violates its learner-assessment grain.', 1;
GO

IF EXISTS (
    SELECT
        ar.result_id,
        lm.module_code,
        l.learner_code,
        a.assessment_id,
        a.assessment_name,
        a.assessment_date,
        vr.score,
        vr.max_score,
        vr.pass_score,
        vr.score_percentage,
        vr.passed
    FROM dpa.assessment_results ar
    JOIN dpa.v_assessment_results vr
        ON vr.result_id = ar.result_id
    JOIN dpa.assessments a
        ON a.assessment_id = ar.assessment_id
    JOIN dpa.learning_modules lm
        ON lm.module_id = a.module_id
    JOIN dpa.learners l
        ON l.learner_id = ar.learner_id
    EXCEPT
    SELECT
        f.source_result_id,
        m.module_code,
        l.learner_code,
        a.source_assessment_id,
        a.assessment_name,
        a.assessment_date,
        f.score,
        f.max_score,
        f.pass_score,
        f.score_percentage,
        f.passed
    FROM reporting.fact_assessment_result f
    JOIN reporting.dim_module m
        ON m.module_key = f.module_key
    JOIN reporting.dim_learner l
        ON l.learner_key = f.learner_key
    JOIN reporting.dim_assessment a
        ON a.assessment_key = f.assessment_key
)
OR EXISTS (
    SELECT
        f.source_result_id,
        m.module_code,
        l.learner_code,
        a.source_assessment_id,
        a.assessment_name,
        a.assessment_date,
        f.score,
        f.max_score,
        f.pass_score,
        f.score_percentage,
        f.passed
    FROM reporting.fact_assessment_result f
    JOIN reporting.dim_module m
        ON m.module_key = f.module_key
    JOIN reporting.dim_learner l
        ON l.learner_key = f.learner_key
    JOIN reporting.dim_assessment a
        ON a.assessment_key = f.assessment_key
    EXCEPT
    SELECT
        ar.result_id,
        lm.module_code,
        l.learner_code,
        a.assessment_id,
        a.assessment_name,
        a.assessment_date,
        vr.score,
        vr.max_score,
        vr.pass_score,
        vr.score_percentage,
        vr.passed
    FROM dpa.assessment_results ar
    JOIN dpa.v_assessment_results vr
        ON vr.result_id = ar.result_id
    JOIN dpa.assessments a
        ON a.assessment_id = ar.assessment_id
    JOIN dpa.learning_modules lm
        ON lm.module_id = a.module_id
    JOIN dpa.learners l
        ON l.learner_id = ar.learner_id
)
    THROW 51310, 'Fact values do not reconcile with the relational source.', 1;
GO

IF EXISTS (
    SELECT 1
    FROM sys.check_constraints cc
    JOIN sys.tables t
        ON t.object_id = cc.parent_object_id
    JOIN sys.schemas s
        ON s.schema_id = t.schema_id
    WHERE s.name = N'reporting'
      AND (cc.is_disabled = 1 OR cc.is_not_trusted = 1)
)
    THROW 51311, 'A reporting check constraint is disabled or not trusted.', 1;

IF EXISTS (
    SELECT 1
    FROM sys.foreign_keys fk
    JOIN sys.tables t
        ON t.object_id = fk.parent_object_id
    JOIN sys.schemas s
        ON s.schema_id = t.schema_id
    WHERE s.name = N'reporting'
      AND (fk.is_disabled = 1 OR fk.is_not_trusted = 1)
)
    THROW 51312, 'A reporting foreign key is disabled or not trusted.', 1;
GO

IF (
    SELECT COUNT(*)
    FROM sys.computed_columns
    WHERE object_id = OBJECT_ID(N'reporting.fact_assessment_result')
      AND name IN (N'score_percentage', N'passed')
      AND is_persisted = 1
) <> 2
    THROW 51313, 'Reporting derived measures are missing or not persisted.', 1;
GO

SELECT
    DB_NAME() AS database_name,
    (SELECT COUNT(*) FROM reporting.dim_module) AS module_dimension_rows,
    (SELECT COUNT(*) FROM reporting.dim_learner) AS learner_dimension_rows,
    (SELECT COUNT(*) FROM reporting.dim_assessment) AS assessment_dimension_rows,
    (SELECT COUNT(*) FROM reporting.fact_assessment_result) AS fact_rows,
    (SELECT COUNT(*) FROM reporting.fact_assessment_result WHERE passed = 1) AS passed_fact_rows,
    (
        SELECT CAST(AVG(score_percentage) AS DECIMAL(7,2))
        FROM reporting.fact_assessment_result
    ) AS average_score_percentage,
    CAST(1 AS bit) AS source_reconciliation_verified,
    CAST(1 AS bit) AS reporting_model_verified;
GO