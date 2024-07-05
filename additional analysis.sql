# Additional Analysis

# Percentage of amount among top 5 Cities
WITH CTE AS (
SELECT city, SUM(amount) avg_amount
FROM oyodata o
JOIN oyo_hotels oh 
ON o.hotel_id = oh.Hotel_id
WHERE status = 'Stayed'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 6)
SELECT *,
ROUND(avg_amount / SUM(avg_amount) OVER() * 100) percentage
FROM CTE;


