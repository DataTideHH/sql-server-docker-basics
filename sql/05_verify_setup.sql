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
GO

DECLARE @module_count INT = (SELECT COUNT(*) FROM dpa.learning_modules);
DECLARE @learner_count INT = (SELECT COUNT(*) FROM dpa.learners);
DECLARE @assessment_count INT = (SELECT COUNT(*) FROM dpa.assessments);
DECLARE @result_count INT = (SELECT COUNT(*) FROM dpa.assessment_results);

IF @module_count <> 5
    THROW 51001, 'Unexpected module row count.', 1;

IF @learner_count <> 5
    THROW 51002, 'Unexpected learner row count.', 1;

IF @assessment_count <> 5
    THROW 51003, 'Unexpected assessment row count.', 1;

IF @result_count <> 25
    THROW 51004, 'Unexpected assessment result row count.', 1;

SELECT
    DB_NAME() AS database_name,
    @module_count AS learning_modules,
    @learner_count AS learners,
    @assessment_count AS assessments,
    @result_count AS assessment_results,
    CAST(1 AS bit) AS setup_verified;
GO
