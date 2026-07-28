USE dpa_training;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

-- Test 1: max_score must be positive.
DECLARE @error_number INT = NULL;
DECLARE @assessment_id INT = (
    SELECT TOP (1) assessment_id
    FROM dpa.assessments
    ORDER BY assessment_id
);

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE dpa.assessments
    SET max_score = 0
    WHERE assessment_id = @assessment_id;
END TRY
BEGIN CATCH
    SET @error_number = ERROR_NUMBER();
END CATCH;

IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

IF @error_number <> 547
    THROW 51101, 'Integrity test failed: max_score = 0 was not rejected by a check constraint.', 1;
GO

-- Test 2: pass_score cannot exceed max_score.
DECLARE @error_number INT = NULL;
DECLARE @assessment_id INT = (
    SELECT TOP (1) assessment_id
    FROM dpa.assessments
    ORDER BY assessment_id
);

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE dpa.assessments
    SET pass_score = max_score + 1
    WHERE assessment_id = @assessment_id;
END TRY
BEGIN CATCH
    SET @error_number = ERROR_NUMBER();
END CATCH;

IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

IF @error_number <> 547
    THROW 51102, 'Integrity test failed: pass_score above max_score was not rejected.', 1;
GO

-- Test 3: result scores cannot be negative.
DECLARE @error_number INT = NULL;
DECLARE @result_id INT = (
    SELECT TOP (1) result_id
    FROM dpa.assessment_results
    ORDER BY result_id
);

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE dpa.assessment_results
    SET score = -1
    WHERE result_id = @result_id;
END TRY
BEGIN CATCH
    SET @error_number = ERROR_NUMBER();
END CATCH;

IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

IF @error_number <> 547
    THROW 51103, 'Integrity test failed: negative result score was not rejected.', 1;
GO

-- Test 4: result scores cannot exceed the assessment maximum.
DECLARE @error_number INT = NULL;
DECLARE @result_id INT = (
    SELECT TOP (1) result_id
    FROM dpa.assessment_results
    ORDER BY result_id
);

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE ar
    SET score = a.max_score + 1
    FROM dpa.assessment_results ar
    JOIN dpa.assessments a
        ON a.assessment_id = ar.assessment_id
    WHERE ar.result_id = @result_id;
END TRY
BEGIN CATCH
    SET @error_number = ERROR_NUMBER();
END CATCH;

IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

IF @error_number <> 51020
    THROW 51104, 'Integrity test failed: score above max_score was not rejected by the result trigger.', 1;
GO

-- Test 5: an assessment maximum cannot be lowered below an existing score.
DECLARE @error_number INT = NULL;
DECLARE @assessment_id INT = (
    SELECT TOP (1) a.assessment_id
    FROM dpa.assessments a
    JOIN dpa.assessment_results ar
        ON ar.assessment_id = a.assessment_id
    GROUP BY a.assessment_id, a.pass_score
    HAVING MAX(ar.score) - 1 >= a.pass_score
    ORDER BY a.assessment_id
);
DECLARE @new_max_score DECIMAL(5,2) = (
    SELECT MAX(score) - 1
    FROM dpa.assessment_results
    WHERE assessment_id = @assessment_id
);

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE dpa.assessments
    SET max_score = @new_max_score
    WHERE assessment_id = @assessment_id;
END TRY
BEGIN CATCH
    SET @error_number = ERROR_NUMBER();
END CATCH;

IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

IF @error_number <> 51021
    THROW 51105, 'Integrity test failed: max_score below an existing result was not rejected.', 1;
GO

-- Test 6: one learner can have only one result per assessment.
DECLARE @error_number INT = NULL;
DECLARE @assessment_id INT = (
    SELECT TOP (1) assessment_id
    FROM dpa.assessment_results
    GROUP BY assessment_id
    HAVING COUNT(*) >= 2
    ORDER BY assessment_id
);
DECLARE @existing_learner_id INT = (
    SELECT MIN(learner_id)
    FROM dpa.assessment_results
    WHERE assessment_id = @assessment_id
);
DECLARE @result_to_change INT = (
    SELECT TOP (1) result_id
    FROM dpa.assessment_results
    WHERE assessment_id = @assessment_id
      AND learner_id <> @existing_learner_id
    ORDER BY result_id
);

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE dpa.assessment_results
    SET learner_id = @existing_learner_id
    WHERE result_id = @result_to_change;
END TRY
BEGIN CATCH
    SET @error_number = ERROR_NUMBER();
END CATCH;

IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

IF @error_number NOT IN (2601, 2627)
    THROW 51106, 'Integrity test failed: duplicate learner-assessment result was not rejected.', 1;
GO

-- Test 7: assessment names must be unique inside a module.
DECLARE @error_number INT = NULL;
DECLARE @source_assessment_id INT;
DECLARE @source_module_id INT;
DECLARE @source_assessment_name NVARCHAR(100);
DECLARE @target_assessment_id INT;

SELECT TOP (1)
    @source_assessment_id = assessment_id,
    @source_module_id = module_id,
    @source_assessment_name = assessment_name
FROM dpa.assessments
ORDER BY assessment_id;

SELECT TOP (1)
    @target_assessment_id = assessment_id
FROM dpa.assessments
WHERE assessment_id <> @source_assessment_id
ORDER BY assessment_id;

BEGIN TRANSACTION;
BEGIN TRY
    UPDATE dpa.assessments
    SET module_id = @source_module_id,
        assessment_name = @source_assessment_name
    WHERE assessment_id = @target_assessment_id;
END TRY
BEGIN CATCH
    SET @error_number = ERROR_NUMBER();
END CATCH;

IF XACT_STATE() <> 0
    ROLLBACK TRANSACTION;

IF @error_number NOT IN (2601, 2627)
    THROW 51107, 'Integrity test failed: duplicate assessment name within a module was not rejected.', 1;
GO

IF EXISTS (
    SELECT 1
    FROM dpa.v_assessment_results
    WHERE passed <> CAST(
        CASE WHEN score >= pass_score THEN 1 ELSE 0 END
        AS bit
    )
)
    THROW 51108, 'Integrity test failed: derived pass status is inconsistent.', 1;
GO

SELECT
    CAST(7 AS INT) AS negative_tests_passed,
    CAST(1 AS bit) AS derived_outcome_test_passed,
    CAST(1 AS bit) AS integrity_test_suite_passed;
GO
