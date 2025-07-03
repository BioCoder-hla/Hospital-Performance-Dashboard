-- Query 7: Single Hospital Performance Profile
-- Retrieves all performance metrics for a specific, named hospital.
SELECT
    m.measure_name,
    p.score,
    p.performance_category,
    p.denominator,
    p.number_of_patients_returned
FROM
    performance_data p
JOIN
    hospitals h ON p.facility_id = h.facility_id
JOIN
    measures m ON p.measure_id = m.measure_id
WHERE
    h.facility_name = 'OROVILLE HOSPITAL'
ORDER BY
    m.measure_name;
