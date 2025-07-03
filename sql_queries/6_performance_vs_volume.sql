-- Query 6: Performance vs. Patient Volume
-- Analyzes if there's a correlation between hospital size (by patient volume) and performance.
SELECT
    CASE
        WHEN p.denominator <= 100 THEN 'Small (<= 100 cases)'
        WHEN p.denominator > 100 AND p.denominator <= 500 THEN 'Medium (101-500 cases)'
        WHEN p.denominator > 500 AND p.denominator <= 1000 THEN 'Large (501-1000 cases)'
        ELSE 'Very Large (> 1000 cases)'
    END AS hospital_volume_tier,
    COUNT(*) AS number_of_measures,
    ROUND(AVG(p.score), 2) AS average_score
FROM
    performance_data p
WHERE
    p.denominator IS NOT NULL
    AND p.score IS NOT NULL
    AND (p.measure_id LIKE 'READM%' OR p.measure_id LIKE 'EDAC%')
GROUP BY
    hospital_volume_tier
ORDER BY
    average_score;
