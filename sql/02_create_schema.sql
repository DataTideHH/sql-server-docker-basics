USE dpa_training;
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
        passed BIT NOT NULL,
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