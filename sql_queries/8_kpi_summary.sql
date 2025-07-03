-- Query 8: KPI Summary
-- Calculates the main numbers for the top-line dashboard summary.
SELECT
    (SELECT COUNT(DISTINCT facility_id) FROM hospitals) AS total_hospitals,
    (SELECT COUNT(DISTINCT measure_id) FROM measures) AS total_measures,
    (
        SELECT ROUND(AVG(score), 2)
        FROM performance_data
        WHERE score IS NOT NULL AND (measure_id LIKE 'READM%' OR measure_id LIKE 'EDAC%')
    ) AS average_readmission_score;
