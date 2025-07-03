-- Query 2: Top 5 Worst Performing Measures by Average Score
-- Identifies which medical conditions or procedures have the highest average readmission/return scores.
SELECT 
    m.measure_name,
    COUNT(p.performance_id) AS number_of_hospitals_reporting,
    ROUND(AVG(p.score), 2) AS average_score
FROM 
    performance_data p
JOIN 
    measures m ON p.measure_id = m.measure_id
WHERE 
    p.score IS NOT NULL
    AND (p.measure_id LIKE 'READM%' OR p.measure_id LIKE 'EDAC%')
GROUP BY 
    m.measure_name
ORDER BY 
    average_score DESC
LIMIT 5;
