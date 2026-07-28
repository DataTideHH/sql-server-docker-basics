USE dpa_training;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dpa.v_assessment_results', N'V') IS NULL
    THROW 51200, 'Missing source view: dpa.v_assessment_results', 1;

IF OBJECT_ID(N'reporting.fact_assessment_result', N'U') IS NULL
    THROW 51200, 'Missing reporting model. Run sql/07_create_reporting_model.sql first.', 1;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE target
    SET
        target.module_code = src.module_code,
        target.module_name = src.module_name,
        target.topic_area = src.topic_area
    FROM reporting.dim_module target
    JOIN dpa.learning_modules src
        ON src.module_id = target.source_module_id;

    INSERT INTO reporting.dim_module (
        source_module_id,
        module_code,
        module_name,
        topic_area
    )
    SELECT
        src.module_id,
        src.module_code,
        src.module_name,
        src.topic_area
    FROM dpa.learning_modules src
    WHERE NOT EXISTS (
        SELECT 1
        FROM reporting.dim_module target
        WHERE target.source_module_id = src.module_id
    );

    UPDATE target
    SET
        target.learner_code = src.learner_code,
        target.learner_name = src.learner_name
    FROM reporting.dim_learner target
    JOIN dpa.learners src
        ON src.learner_id = target.source_learner_id;

    INSERT INTO reporting.dim_learner (
        source_learner_id,
        learner_code,
        learner_name
    )
    SELECT
        src.learner_id,
        src.learner_code,
        src.learner_name
    FROM dpa.learners src
    WHERE NOT EXISTS (
        SELECT 1
        FROM reporting.dim_learner target
        WHERE target.source_learner_id = src.learner_id
    );

    UPDATE target
    SET
        target.assessment_name = src.assessment_name,
        target.assessment_date = src.assessment_date
    FROM reporting.dim_assessment target
    JOIN dpa.assessments src
        ON src.assessment_id = target.source_assessment_id;

    INSERT INTO reporting.dim_assessment (
        source_assessment_id,
        assessment_name,
        assessment_date
    )
    SELECT
        src.assessment_id,
        src.assessment_name,
        src.assessment_date
    FROM dpa.assessments src
    WHERE NOT EXISTS (
        SELECT 1
        FROM reporting.dim_assessment target
        WHERE target.source_assessment_id = src.assessment_id
    );

    SELECT
        ar.result_id AS source_result_id,
        dm.module_key,
        dl.learner_key,
        da.assessment_key,
        vr.score,
        vr.max_score,
        vr.pass_score
    INTO #fact_source
    FROM dpa.assessment_results ar
    JOIN dpa.v_assessment_results vr
        ON vr.result_id = ar.result_id
    JOIN dpa.assessments a
        ON a.assessment_id = ar.assessment_id
    JOIN reporting.dim_module dm
        ON dm.source_module_id = a.module_id
    JOIN reporting.dim_learner dl
        ON dl.source_learner_id = ar.learner_id
    JOIN reporting.dim_assessment da
        ON da.source_assessment_id = ar.assessment_id;

    IF (SELECT COUNT(*) FROM #fact_source)
       <> (SELECT COUNT(*) FROM dpa.assessment_results)
    BEGIN
        THROW 51201, 'Reporting load could not resolve every source result to dimension keys.', 1;
    END;

    UPDATE target
    SET
        target.module_key = src.module_key,
        target.learner_key = src.learner_key,
        target.assessment_key = src.assessment_key,
        target.score = src.score,
        target.max_score = src.max_score,
        target.pass_score = src.pass_score,
        target.loaded_at_utc = SYSUTCDATETIME()
    FROM reporting.fact_assessment_result target
    JOIN #fact_source src
        ON src.source_result_id = target.source_result_id;

    INSERT INTO reporting.fact_assessment_result (
        source_result_id,
        module_key,
        learner_key,
        assessment_key,
        score,
        max_score,
        pass_score
    )
    SELECT
        src.source_result_id,
        src.module_key,
        src.learner_key,
        src.assessment_key,
        src.score,
        src.max_score,
        src.pass_score
    FROM #fact_source src
    WHERE NOT EXISTS (
        SELECT 1
        FROM reporting.fact_assessment_result target
        WHERE target.source_result_id = src.source_result_id
    );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

SELECT
    (SELECT COUNT(*) FROM reporting.dim_module) AS module_dimension_rows,
    (SELECT COUNT(*) FROM reporting.dim_learner) AS learner_dimension_rows,
    (SELECT COUNT(*) FROM reporting.dim_assessment) AS assessment_dimension_rows,
    (SELECT COUNT(*) FROM reporting.fact_assessment_result) AS fact_rows,
    (SELECT COUNT(*) FROM reporting.fact_assessment_result WHERE passed = 1) AS passed_fact_rows,
    CAST(1 AS bit) AS reporting_load_completed;
GO