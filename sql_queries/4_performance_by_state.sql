-- Query 4: Average Performance Score by State
-- Reveals geographic trends by ranking states based on their average performance.
SELECT
    h.state,
    COUNT(DISTINCT h.facility_id) AS number_of_hospitals,
    ROUND(AVG(p.score), 2) as average_state_score
FROM 
    performance_data p
JOIN 
    hospitals h ON p.facility_id = h.facility_id
WHERE 
    p.score IS NOT NULL
    AND (p.measure_id LIKE 'READM%' OR p.measure_id LIKE 'EDAC%')
GROUP BY 
    h.state
HAVING 
    number_of_hospitals > 20
ORDER BY 
    average_state_score DESC;
