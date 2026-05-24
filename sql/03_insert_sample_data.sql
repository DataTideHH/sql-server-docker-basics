USE dpa_training;
GO

-- Insert learning modules
INSERT INTO dpa.learning_modules (module_code, module_name, topic_area)
SELECT v.module_code, v.module_name, v.topic_area
FROM (VALUES
    (N'MOD-PC',   N'PC Grundlagen',              N'IT Fundamentals'),
    (N'MOD-PROG', N'Grundlagen Programmierung',  N'Programming'),
    (N'MOD-DB',   N'Datenbanken',                N'Databases'),
    (N'MOD-LNX',  N'Linux Grundlagen',           N'Infrastructure'),
    (N'MOD-NET',  N'Netzwerkgrundlagen',         N'Networking')
) AS v(module_code, module_name, topic_area)
WHERE NOT EXISTS (
    SELECT 1
    FROM dpa.learning_modules lm
    WHERE lm.module_code = v.module_code
);
GO

-- Insert synthetic learners
INSERT INTO dpa.learners (learner_code, learner_name)
SELECT v.learner_code, v.learner_name
FROM (VALUES
    (N'LRN-001', N'Learner 001'),
    (N'LRN-002', N'Learner 002'),
    (N'LRN-003', N'Learner 003'),
    (N'LRN-004', N'Learner 004'),
    (N'LRN-005', N'Learner 005')
) AS v(learner_code, learner_name)
WHERE NOT EXISTS (
    SELECT 1
    FROM dpa.learners l
    WHERE l.learner_code = v.learner_code
);
GO

-- Insert assessments
INSERT INTO dpa.assessments (
    module_id,
    assessment_name,
    assessment_date,
    max_score,
    pass_score
)
SELECT
    lm.module_id,
    v.assessment_name,
    v.assessment_date,
    v.max_score,
    v.pass_score
FROM (VALUES
    (N'MOD-PC',   N'PC Grundlagen LEK 1',             CAST('2025-08-01' AS date), 100.00, 50.00),
    (N'MOD-PROG', N'Programming Basics Check',        CAST('2025-09-05' AS date), 100.00, 50.00),
    (N'MOD-DB',   N'Database Fundamentals Check',     CAST('2025-10-02' AS date), 100.00, 50.00),
    (N'MOD-LNX',  N'Linux Command Line Check',        CAST('2025-10-30' AS date), 100.00, 50.00),
    (N'MOD-NET',  N'Networking Fundamentals Check',   CAST('2025-12-19' AS date), 100.00, 50.00)
) AS v(module_code, assessment_name, assessment_date, max_score, pass_score)
JOIN dpa.learning_modules lm
    ON lm.module_code = v.module_code
WHERE NOT EXISTS (
    SELECT 1
    FROM dpa.assessments a
    WHERE a.assessment_name = v.assessment_name
);
GO

-- Insert synthetic assessment results
INSERT INTO dpa.assessment_results (
    assessment_id,
    learner_id,
    score,
    passed
)
SELECT
    a.assessment_id,
    l.learner_id,
    v.score,
    CASE
        WHEN v.score >= a.pass_score THEN CAST(1 AS bit)
        ELSE CAST(0 AS bit)
    END AS passed
FROM (VALUES
    (N'PC Grundlagen LEK 1',           N'LRN-001', 78.00),
    (N'PC Grundlagen LEK 1',           N'LRN-002', 62.00),
    (N'PC Grundlagen LEK 1',           N'LRN-003', 91.00),
    (N'PC Grundlagen LEK 1',           N'LRN-004', 47.00),
    (N'PC Grundlagen LEK 1',           N'LRN-005', 84.00),

    (N'Programming Basics Check',      N'LRN-001', 72.00),
    (N'Programming Basics Check',      N'LRN-002', 58.00),
    (N'Programming Basics Check',      N'LRN-003', 88.00),
    (N'Programming Basics Check',      N'LRN-004', 41.00),
    (N'Programming Basics Check',      N'LRN-005', 69.00),

    (N'Database Fundamentals Check',   N'LRN-001', 81.00),
    (N'Database Fundamentals Check',   N'LRN-002', 66.00),
    (N'Database Fundamentals Check',   N'LRN-003', 92.00),
    (N'Database Fundamentals Check',   N'LRN-004', 55.00),
    (N'Database Fundamentals Check',   N'LRN-005', 74.00),

    (N'Linux Command Line Check',      N'LRN-001', 76.00),
    (N'Linux Command Line Check',      N'LRN-002', 49.00),
    (N'Linux Command Line Check',      N'LRN-003', 85.00),
    (N'Linux Command Line Check',      N'LRN-004', 53.00),
    (N'Linux Command Line Check',      N'LRN-005', 71.00),

    (N'Networking Fundamentals Check', N'LRN-001', 68.00),
    (N'Networking Fundamentals Check', N'LRN-002', 57.00),
    (N'Networking Fundamentals Check', N'LRN-003', 79.00),
    (N'Networking Fundamentals Check', N'LRN-004', 44.00),
    (N'Networking Fundamentals Check', N'LRN-005', 63.00)
) AS v(assessment_name, learner_code, score)
JOIN dpa.assessments a
    ON a.assessment_name = v.assessment_name
JOIN dpa.learners l
    ON l.learner_code = v.learner_code
WHERE NOT EXISTS (
    SELECT 1
    FROM dpa.assessment_results ar
    WHERE ar.assessment_id = a.assessment_id
      AND ar.learner_id = l.learner_id
);
GO