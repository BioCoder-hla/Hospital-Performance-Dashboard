-- Query 3: Top 5 Worst Performing UNIQUE Hospitals for Heart Failure Readmissions (REVISED)
-- Generates a highly actionable list of specific hospitals needing attention for a key metric.
-- Changed from Top 10 to Top 5 for a more focused view.
SELECT DISTINCT
    h.facility_name,
    h.city_town,
    h.state,
    p.score
FROM 
    performance_data p
JOIN 
    hospitals h ON p.facility_id = h.facility_id
WHERE 
    p.measure_id = 'READM_30_HF' -- The specific measure for Heart Failure Readmissions
    AND p.score IS NOT NULL
ORDER BY 
    p.score DESC -- Order by the highest (worst) score
LIMIT 5; -- Changed to 5
