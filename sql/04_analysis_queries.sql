USE dpa_training;
GO

-- Overview: all assessment results with module and learner context
SELECT
    lm.module_code,
    lm.module_name,
    lm.topic_area,
    a.assessment_name,
    a.assessment_date,
    l.learner_code,
    l.learner_name,
    ar.score,
    ar.passed
FROM dpa_training.dpa.assessment_results ar
JOIN dpa_training.dpa.assessments a
    ON ar.assessment_id = a.assessment_id
JOIN dpa_training.dpa.learning_modules lm
    ON a.module_id = lm.module_id
JOIN dpa_training.dpa.learners l
    ON ar.learner_id = l.learner_id
ORDER BY
    a.assessment_date,
    lm.module_code,
    l.learner_code;
GO

-- KPI: average score and pass rate by module
SELECT
    lm.module_code,
    lm.module_name,
    COUNT(*) AS result_count,
    AVG(ar.score) AS average_score,
    SUM(CASE WHEN ar.passed = 1 THEN 1 ELSE 0 END) AS passed_count,
    CAST(
        100.0 * SUM(CASE WHEN ar.passed = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS pass_rate_percent
FROM dpa_training.dpa.assessment_results ar
JOIN dpa_training.dpa.assessments a
    ON ar.assessment_id = a.assessment_id
JOIN dpa_training.dpa.learning_modules lm
    ON a.module_id = lm.module_id
GROUP BY
    lm.module_code,
    lm.module_name
ORDER BY
    pass_rate_percent DESC,
    average_score DESC;
GO

-- KPI: learner performance overview
SELECT
    l.learner_code,
    l.learner_name,
    COUNT(*) AS assessments_taken,
    AVG(ar.score) AS average_score,
    SUM(CASE WHEN ar.passed = 1 THEN 1 ELSE 0 END) AS passed_assessments,
    SUM(CASE WHEN ar.passed = 0 THEN 1 ELSE 0 END) AS failed_assessments
FROM dpa_training.dpa.assessment_results ar
JOIN dpa_training.dpa.learners l
    ON ar.learner_id = l.learner_id
GROUP BY
    l.learner_code,
    l.learner_name
ORDER BY
    average_score DESC;
GO

-- Flag modules below target pass rate
SELECT
    lm.module_code,
    lm.module_name,
    COUNT(*) AS result_count,
    CAST(
        100.0 * SUM(CASE WHEN ar.passed = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS pass_rate_percent,
    CASE
        WHEN 100.0 * SUM(CASE WHEN ar.passed = 1 THEN 1 ELSE 0 END) / COUNT(*) < 80
            THEN 'Below target'
        ELSE 'On target'
    END AS status
FROM dpa_training.dpa.assessment_results ar
JOIN dpa_training.dpa.assessments a
    ON ar.assessment_id = a.assessment_id
JOIN dpa_training.dpa.learning_modules lm
    ON a.module_id = lm.module_id
GROUP BY
    lm.module_code,
    lm.module_name
ORDER BY
    pass_rate_percent ASC;
GO