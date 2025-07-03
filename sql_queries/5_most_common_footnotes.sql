-- Query 5: Most Common Footnotes
-- Identifies the most frequent reasons for data flags or missing values.
SELECT 
    pf.footnote_id,
    f.footnote_text,
    COUNT(*) AS frequency
FROM 
    performance_footnotes pf
LEFT JOIN 
    footnotes f ON pf.footnote_id = f.footnote_id
GROUP BY 
    pf.footnote_id, f.footnote_text
ORDER BY 
    frequency DESC
LIMIT 5;
