-- Query 1: National Performance Breakdown
-- Provides a high-level overview of how hospitals are performing against the national average.
SELECT 
    performance_category, 
    COUNT(*) AS number_of_measures,
    ROUND((COUNT(*) / (SELECT COUNT(*) FROM performance_data WHERE performance_category IS NOT NULL)) * 100, 1) AS percentage
FROM 
    performance_data
WHERE 
    performance_category IS NOT NULL AND performance_category != ''
GROUP BY 
    performance_category
ORDER BY 
    number_of_measures DESC;
