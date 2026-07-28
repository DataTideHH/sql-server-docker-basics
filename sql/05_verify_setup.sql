USE dpa_training;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dpa.learning_modules', N'U') IS NULL
    THROW 51000, 'Missing table: dpa.learning_modules', 1;

IF OBJECT_ID(N'dpa.learners', N'U') IS NULL
    THROW 51000, 'Missing table: dpa.learners', 1;

IF OBJECT_ID(N'dpa.assessments', N'U') IS NULL
    THROW 51000, 'Missing table: dpa.assessments', 1;

IF OBJECT_ID(N'dpa.assessment_results', N'U') IS NULL
    THROW 51000, 'Missing table: dpa.assessment_results', 1;

IF OBJECT_ID(N'dpa.v_assessment_results', N'V') IS NULL
    THROW 51000, 'Missing view: dpa.v_assessment_results', 1;
GO

IF COL_LENGTH(N'dpa.assessment_results', N'passed') IS NOT NULL
    THROW 51005, 'The derived passed flag must not be stored in dpa.assessment_results.', 1;
GO

IF EXISTS (
    SELECT required.constraint_name
    FROM (VALUES
        (N'CK_learning_modules_required_text'),
        (N'CK_learners_required_text'),
        (N'CK_assessments_required_values'),
        (N'CK_assessment_results_score_nonnegative')
    ) AS required(constraint_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM sys.check_constraints cc
        WHERE cc.name = required.constraint_name
          AND cc.is_disabled = 0
          AND cc.is_not_trusted = 0
    )
)
    THROW 51006, 'One or more required trusted check constraints are missing.', 1;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.key_constraints kc
    WHERE kc.parent_object_id = OBJECT_ID(N'dpa.assessments')
      AND kc.name = N'UQ_assessments_module_name'
)
    THROW 51007, 'Missing unique constraint: UQ_assessments_module_name.', 1;

IF NOT EXISTS (
    SELECT 1
    FROM sys.key_constraints kc
    WHERE kc.parent_object_id = OBJECT_ID(N'dpa.assessment_results')
      AND kc.name = N'UQ_assessment_learner'
)
    THROW 51007, 'Missing unique constraint: UQ_assessment_learner.', 1;
GO

IF EXISTS (
    SELECT required.trigger_name
    FROM (VALUES
        (N'TR_assessment_results_validate_score'),
        (N'TR_assessments_validate_existing_results')
    ) AS required(trigger_name)
    WHERE NOT EXISTS (
        SELECT 1
        FROM sys.triggers t
        WHERE t.name = required.trigger_name
          AND t.is_disabled = 0
    )
)
    THROW 51008, 'One or more required integrity triggers are missing or disabled.', 1;
GO

IF EXISTS (
    SELECT 1
    FROM dpa.learning_modules
    WHERE LEN(LTRIM(RTRIM(module_code))) = 0
       OR LEN(LTRIM(RTRIM(module_name))) = 0
       OR LEN(LTRIM(RTRIM(topic_area))) = 0
)
    THROW 51009, 'Blank required values found in dpa.learning_modules.', 1;

IF EXISTS (
    SELECT 1
    FROM dpa.learners
    WHERE LEN(LTRIM(RTRIM(learner_code))) = 0
       OR LEN(LTRIM(RTRIM(learner_name))) = 0
)
    THROW 51009, 'Blank required values found in dpa.learners.', 1;

IF EXISTS (
    SELECT 1
    FROM dpa.assessments
    WHERE LEN(LTRIM(RTRIM(assessment_name))) = 0
       OR max_score <= 0
       OR pass_score < 0
       OR pass_score > max_score
)
    THROW 51009, 'Invalid assessment configuration found.', 1;

IF EXISTS (
    SELECT 1
    FROM dpa.assessment_results ar
    JOIN dpa.assessments a
        ON a.assessment_id = ar.assessment_id
    WHERE ar.score < 0
       OR ar.score > a.max_score
)
    THROW 51009, 'Invalid assessment result score found.', 1;
GO

IF EXISTS (
    SELECT assessment_id, learner_id
    FROM dpa.assessment_results
    GROUP BY assessment_id, learner_id
    HAVING COUNT(*) > 1
)
    THROW 51011, 'Duplicate learner-assessment result found.', 1;

IF EXISTS (
    SELECT module_id, assessment_name
    FROM dpa.assessments
    GROUP BY module_id, assessment_name
    HAVING COUNT(*) > 1
)
    THROW 51011, 'Duplicate assessment name within a module found.', 1;
GO

IF EXISTS (
    SELECT 1
    FROM dpa.v_assessment_results
    WHERE score_percentage < 0
       OR score_percentage > 100
       OR passed <> CAST(
            CASE WHEN score >= pass_score THEN 1 ELSE 0 END
            AS bit
       )
)
    THROW 51012, 'Derived assessment outcome is inconsistent.', 1;
GO

DECLARE @module_count INT = (SELECT COUNT(*) FROM dpa.learning_modules);
DECLARE @learner_count INT = (SELECT COUNT(*) FROM dpa.learners);
DECLARE @assessment_count INT = (SELECT COUNT(*) FROM dpa.assessments);
DECLARE @result_count INT = (SELECT COUNT(*) FROM dpa.assessment_results);
DECLARE @view_result_count INT = (SELECT COUNT(*) FROM dpa.v_assessment_results);
DECLARE @passed_count INT = (
    SELECT COUNT(*)
    FROM dpa.v_assessment_results
    WHERE passed = 1
);

IF @module_count <> 5
    THROW 51001, 'Unexpected module row count.', 1;

IF @learner_count <> 5
    THROW 51002, 'Unexpected learner row count.', 1;

IF @assessment_count <> 5
    THROW 51003, 'Unexpected assessment row count.', 1;

IF @result_count <> 25
    THROW 51004, 'Unexpected assessment result row count.', 1;

IF @view_result_count <> @result_count
    THROW 51013, 'Assessment outcome view does not match the result table row count.', 1;

IF @passed_count <> 21
    THROW 51014, 'Unexpected derived passed result count.', 1;

SELECT
    DB_NAME() AS database_name,
    @module_count AS learning_modules,
    @learner_count AS learners,
    @assessment_count AS assessments,
    @result_count AS assessment_results,
    @passed_count AS passed_results,
    CAST(1 AS bit) AS setup_verified,
    CAST(1 AS bit) AS integrity_rules_verified;
GO
