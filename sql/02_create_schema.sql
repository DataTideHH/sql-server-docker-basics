USE dpa_training;
GO

SET XACT_ABORT ON;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'dpa'
)
BEGIN
    EXEC(N'CREATE SCHEMA dpa');
END;
GO

IF OBJECT_ID(N'dpa.learning_modules', N'U') IS NULL
BEGIN
    CREATE TABLE dpa.learning_modules (
        module_id INT IDENTITY(1,1) PRIMARY KEY,
        module_code NVARCHAR(20) NOT NULL UNIQUE,
        module_name NVARCHAR(100) NOT NULL,
        topic_area NVARCHAR(100) NOT NULL
    );
END;
GO

IF OBJECT_ID(N'dpa.learners', N'U') IS NULL
BEGIN
    CREATE TABLE dpa.learners (
        learner_id INT IDENTITY(1,1) PRIMARY KEY,
        learner_code NVARCHAR(20) NOT NULL UNIQUE,
        learner_name NVARCHAR(100) NOT NULL
    );
END;
GO

IF OBJECT_ID(N'dpa.assessments', N'U') IS NULL
BEGIN
    CREATE TABLE dpa.assessments (
        assessment_id INT IDENTITY(1,1) PRIMARY KEY,
        module_id INT NOT NULL,
        assessment_name NVARCHAR(100) NOT NULL,
        assessment_date DATE NOT NULL,
        max_score DECIMAL(5,2) NOT NULL,
        pass_score DECIMAL(5,2) NOT NULL,
        CONSTRAINT FK_assessments_learning_modules
            FOREIGN KEY (module_id)
            REFERENCES dpa.learning_modules(module_id)
    );
END;
GO

IF OBJECT_ID(N'dpa.assessment_results', N'U') IS NULL
BEGIN
    CREATE TABLE dpa.assessment_results (
        result_id INT IDENTITY(1,1) PRIMARY KEY,
        assessment_id INT NOT NULL,
        learner_id INT NOT NULL,
        score DECIMAL(5,2) NOT NULL,
        CONSTRAINT FK_results_assessments
            FOREIGN KEY (assessment_id)
            REFERENCES dpa.assessments(assessment_id),
        CONSTRAINT FK_results_learners
            FOREIGN KEY (learner_id)
            REFERENCES dpa.learners(learner_id),
        CONSTRAINT UQ_assessment_learner
            UNIQUE (assessment_id, learner_id)
    );
END;
GO

-- Upgrade existing databases from the earlier model. The stored passed flag is
-- removed only after confirming that it agrees with score and pass_score.
IF COL_LENGTH(N'dpa.assessment_results', N'passed') IS NOT NULL
BEGIN
    EXEC sys.sp_executesql N'
        IF EXISTS (
            SELECT 1
            FROM dpa.assessment_results ar
            JOIN dpa.assessments a
                ON a.assessment_id = ar.assessment_id
            WHERE ar.passed <> CAST(
                CASE WHEN ar.score >= a.pass_score THEN 1 ELSE 0 END
                AS bit
            )
        )
        BEGIN
            THROW 51010, ''Existing passed values do not match score and pass_score.'', 1;
        END;

        DECLARE @default_constraint sysname;
        DECLARE @drop_constraint_sql nvarchar(max);

        SELECT @default_constraint = dc.name
        FROM sys.default_constraints dc
        JOIN sys.columns c
            ON c.object_id = dc.parent_object_id
           AND c.column_id = dc.parent_column_id
        WHERE dc.parent_object_id = OBJECT_ID(N''dpa.assessment_results'')
          AND c.name = N''passed'';

        IF @default_constraint IS NOT NULL
        BEGIN
            SET @drop_constraint_sql =
                N''ALTER TABLE dpa.assessment_results DROP CONSTRAINT ''
                + QUOTENAME(@default_constraint)
                + N'';'';

            EXEC sys.sp_executesql @drop_constraint_sql;
        END;

        ALTER TABLE dpa.assessment_results DROP COLUMN passed;
    ';
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dpa.learning_modules')
      AND name = N'CK_learning_modules_required_text'
)
BEGIN
    ALTER TABLE dpa.learning_modules WITH CHECK
        ADD CONSTRAINT CK_learning_modules_required_text CHECK (
            LEN(LTRIM(RTRIM(module_code))) > 0
            AND LEN(LTRIM(RTRIM(module_name))) > 0
            AND LEN(LTRIM(RTRIM(topic_area))) > 0
        );

    ALTER TABLE dpa.learning_modules
        CHECK CONSTRAINT CK_learning_modules_required_text;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dpa.learners')
      AND name = N'CK_learners_required_text'
)
BEGIN
    ALTER TABLE dpa.learners WITH CHECK
        ADD CONSTRAINT CK_learners_required_text CHECK (
            LEN(LTRIM(RTRIM(learner_code))) > 0
            AND LEN(LTRIM(RTRIM(learner_name))) > 0
        );

    ALTER TABLE dpa.learners
        CHECK CONSTRAINT CK_learners_required_text;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dpa.assessments')
      AND name = N'CK_assessments_required_values'
)
BEGIN
    ALTER TABLE dpa.assessments WITH CHECK
        ADD CONSTRAINT CK_assessments_required_values CHECK (
            LEN(LTRIM(RTRIM(assessment_name))) > 0
            AND max_score > 0
            AND pass_score >= 0
            AND pass_score <= max_score
        );

    ALTER TABLE dpa.assessments
        CHECK CONSTRAINT CK_assessments_required_values;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'dpa.assessment_results')
      AND name = N'CK_assessment_results_score_nonnegative'
)
BEGIN
    ALTER TABLE dpa.assessment_results WITH CHECK
        ADD CONSTRAINT CK_assessment_results_score_nonnegative CHECK (score >= 0);

    ALTER TABLE dpa.assessment_results
        CHECK CONSTRAINT CK_assessment_results_score_nonnegative;
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.key_constraints
    WHERE parent_object_id = OBJECT_ID(N'dpa.assessments')
      AND name = N'UQ_assessments_module_name'
)
BEGIN
    ALTER TABLE dpa.assessments
        ADD CONSTRAINT UQ_assessments_module_name
            UNIQUE (module_id, assessment_name);
END;
GO

CREATE OR ALTER TRIGGER dpa.TR_assessment_results_validate_score
ON dpa.assessment_results
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dpa.assessments a
            ON a.assessment_id = i.assessment_id
        WHERE i.score > a.max_score
    )
    BEGIN
        THROW 51020, 'Assessment result score cannot exceed assessment max_score.', 1;
    END;
END;
GO

CREATE OR ALTER TRIGGER dpa.TR_assessments_validate_existing_results
ON dpa.assessments
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(max_score)
       AND EXISTS (
            SELECT 1
            FROM inserted i
            JOIN dpa.assessment_results ar
                ON ar.assessment_id = i.assessment_id
            WHERE ar.score > i.max_score
       )
    BEGIN
        THROW 51021, 'Assessment max_score cannot be lower than an existing result score.', 1;
    END;
END;
GO

CREATE OR ALTER VIEW dpa.v_assessment_results
AS
SELECT
    ar.result_id,
    ar.assessment_id,
    ar.learner_id,
    ar.score,
    a.max_score,
    a.pass_score,
    CAST(
        100.0 * ar.score / NULLIF(a.max_score, 0)
        AS DECIMAL(7,2)
    ) AS score_percentage,
    CAST(
        CASE WHEN ar.score >= a.pass_score THEN 1 ELSE 0 END
        AS bit
    ) AS passed
FROM dpa.assessment_results ar
JOIN dpa.assessments a
    ON a.assessment_id = ar.assessment_id;
GO
