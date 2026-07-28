USE dpa_training;
GO

SET XACT_ABORT ON;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = N'reporting'
)
BEGIN
    EXEC(N'CREATE SCHEMA reporting');
END;
GO

IF OBJECT_ID(N'reporting.dim_module', N'U') IS NULL
BEGIN
    CREATE TABLE reporting.dim_module (
        module_key INT IDENTITY(1,1) NOT NULL,
        source_module_id INT NOT NULL,
        module_code NVARCHAR(20) NOT NULL,
        module_name NVARCHAR(100) NOT NULL,
        topic_area NVARCHAR(100) NOT NULL,
        CONSTRAINT PK_reporting_dim_module
            PRIMARY KEY (module_key),
        CONSTRAINT UQ_reporting_dim_module_source
            UNIQUE (source_module_id),
        CONSTRAINT UQ_reporting_dim_module_code
            UNIQUE (module_code),
        CONSTRAINT CK_reporting_dim_module_required_text CHECK (
            LEN(LTRIM(RTRIM(module_code))) > 0
            AND LEN(LTRIM(RTRIM(module_name))) > 0
            AND LEN(LTRIM(RTRIM(topic_area))) > 0
        )
    );
END;
GO

IF OBJECT_ID(N'reporting.dim_learner', N'U') IS NULL
BEGIN
    CREATE TABLE reporting.dim_learner (
        learner_key INT IDENTITY(1,1) NOT NULL,
        source_learner_id INT NOT NULL,
        learner_code NVARCHAR(20) NOT NULL,
        learner_name NVARCHAR(100) NOT NULL,
        CONSTRAINT PK_reporting_dim_learner
            PRIMARY KEY (learner_key),
        CONSTRAINT UQ_reporting_dim_learner_source
            UNIQUE (source_learner_id),
        CONSTRAINT UQ_reporting_dim_learner_code
            UNIQUE (learner_code),
        CONSTRAINT CK_reporting_dim_learner_required_text CHECK (
            LEN(LTRIM(RTRIM(learner_code))) > 0
            AND LEN(LTRIM(RTRIM(learner_name))) > 0
        )
    );
END;
GO

IF OBJECT_ID(N'reporting.dim_assessment', N'U') IS NULL
BEGIN
    CREATE TABLE reporting.dim_assessment (
        assessment_key INT IDENTITY(1,1) NOT NULL,
        source_assessment_id INT NOT NULL,
        assessment_name NVARCHAR(100) NOT NULL,
        assessment_date DATE NOT NULL,
        CONSTRAINT PK_reporting_dim_assessment
            PRIMARY KEY (assessment_key),
        CONSTRAINT UQ_reporting_dim_assessment_source
            UNIQUE (source_assessment_id),
        CONSTRAINT CK_reporting_dim_assessment_required_text CHECK (
            LEN(LTRIM(RTRIM(assessment_name))) > 0
        )
    );
END;
GO

IF OBJECT_ID(N'reporting.fact_assessment_result', N'U') IS NULL
BEGIN
    CREATE TABLE reporting.fact_assessment_result (
        assessment_result_key BIGINT IDENTITY(1,1) NOT NULL,
        source_result_id INT NOT NULL,
        module_key INT NOT NULL,
        learner_key INT NOT NULL,
        assessment_key INT NOT NULL,
        score DECIMAL(5,2) NOT NULL,
        max_score DECIMAL(5,2) NOT NULL,
        pass_score DECIMAL(5,2) NOT NULL,
        score_percentage AS (
            CAST(
                100.0 * score / NULLIF(max_score, 0)
                AS DECIMAL(7,2)
            )
        ) PERSISTED,
        passed AS (
            CAST(
                CASE WHEN score >= pass_score THEN 1 ELSE 0 END
                AS bit
            )
        ) PERSISTED,
        loaded_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_reporting_fact_loaded_at_utc
            DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_reporting_fact_assessment_result
            PRIMARY KEY (assessment_result_key),
        CONSTRAINT UQ_reporting_fact_source_result
            UNIQUE (source_result_id),
        CONSTRAINT UQ_reporting_fact_grain
            UNIQUE (assessment_key, learner_key),
        CONSTRAINT FK_reporting_fact_module
            FOREIGN KEY (module_key)
            REFERENCES reporting.dim_module(module_key),
        CONSTRAINT FK_reporting_fact_learner
            FOREIGN KEY (learner_key)
            REFERENCES reporting.dim_learner(learner_key),
        CONSTRAINT FK_reporting_fact_assessment
            FOREIGN KEY (assessment_key)
            REFERENCES reporting.dim_assessment(assessment_key),
        CONSTRAINT CK_reporting_fact_score_values CHECK (
            max_score > 0
            AND pass_score >= 0
            AND pass_score <= max_score
            AND score >= 0
            AND score <= max_score
        )
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'reporting.fact_assessment_result')
      AND name = N'IX_reporting_fact_module_key'
)
BEGIN
    CREATE INDEX IX_reporting_fact_module_key
        ON reporting.fact_assessment_result (module_key)
        INCLUDE (score, score_percentage, passed);
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'reporting.fact_assessment_result')
      AND name = N'IX_reporting_fact_learner_key'
)
BEGIN
    CREATE INDEX IX_reporting_fact_learner_key
        ON reporting.fact_assessment_result (learner_key)
        INCLUDE (score, score_percentage, passed);
END;
GO

CREATE OR ALTER VIEW reporting.v_assessment_result_detail
AS
SELECT
    f.assessment_result_key,
    f.source_result_id,
    m.module_code,
    m.module_name,
    m.topic_area,
    a.source_assessment_id,
    a.assessment_name,
    a.assessment_date,
    l.learner_code,
    l.learner_name,
    f.score,
    f.max_score,
    f.pass_score,
    f.score_percentage,
    f.passed,
    f.loaded_at_utc
FROM reporting.fact_assessment_result f
JOIN reporting.dim_module m
    ON m.module_key = f.module_key
JOIN reporting.dim_learner l
    ON l.learner_key = f.learner_key
JOIN reporting.dim_assessment a
    ON a.assessment_key = f.assessment_key;
GO