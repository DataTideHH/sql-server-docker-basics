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
    vr.score,
    vr.score_percentage,
    vr.passed
FROM dpa.v_assessment_results vr
JOIN dpa.assessments a
    ON vr.assessment_id = a.assessment_id
JOIN dpa.learning_modules lm
    ON a.module_id = lm.module_id
JOIN dpa.learners l
    ON vr.learner_id = l.learner_id
ORDER BY
    a.assessment_date,
    lm.module_code,
    l.learner_code;
GO

-- KPI: average percentage score and pass rate by module
SELECT
    lm.module_code,
    lm.module_name,
    COUNT(*) AS result_count,
    CAST(AVG(vr.score_percentage) AS DECIMAL(7,2)) AS average_score_percent,
    SUM(CASE WHEN vr.passed = 1 THEN 1 ELSE 0 END) AS passed_count,
    CAST(
        100.0 * SUM(CASE WHEN vr.passed = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS pass_rate_percent
FROM dpa.v_assessment_results vr
JOIN dpa.assessments a
    ON vr.assessment_id = a.assessment_id
JOIN dpa.learning_modules lm
    ON a.module_id = lm.module_id
GROUP BY
    lm.module_code,
    lm.module_name
ORDER BY
    pass_rate_percent DESC,
    average_score_percent DESC;
GO

-- KPI: learner performance overview
SELECT
    l.learner_code,
    l.learner_name,
    COUNT(*) AS assessments_taken,
    CAST(AVG(vr.score_percentage) AS DECIMAL(7,2)) AS average_score_percent,
    SUM(CASE WHEN vr.passed = 1 THEN 1 ELSE 0 END) AS passed_assessments,
    SUM(CASE WHEN vr.passed = 0 THEN 1 ELSE 0 END) AS failed_assessments
FROM dpa.v_assessment_results vr
JOIN dpa.learners l
    ON vr.learner_id = l.learner_id
GROUP BY
    l.learner_code,
    l.learner_name
ORDER BY
    average_score_percent DESC;
GO

-- Flag modules below target pass rate
SELECT
    lm.module_code,
    lm.module_name,
    COUNT(*) AS result_count,
    CAST(
        100.0 * SUM(CASE WHEN vr.passed = 1 THEN 1 ELSE 0 END) / COUNT(*)
        AS DECIMAL(5,2)
    ) AS pass_rate_percent,
    CASE
        WHEN 100.0 * SUM(CASE WHEN vr.passed = 1 THEN 1 ELSE 0 END) / COUNT(*) < 80
            THEN 'Below target'
        ELSE 'On target'
    END AS status
FROM dpa.v_assessment_results vr
JOIN dpa.assessments a
    ON vr.assessment_id = a.assessment_id
JOIN dpa.learning_modules lm
    ON a.module_id = lm.module_id
GROUP BY
    lm.module_code,
    lm.module_name
ORDER BY
    pass_rate_percent ASC;
GO
