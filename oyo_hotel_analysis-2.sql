# Discount and Booking Analysis
-- 10. How do discounts affect booking rates?
ALTER TABLE oyodata
ADD COLUMN discount_percent DECIMAL;

UPDATE oyodata 
SET discount_percent = discount / amount * 100;

SELECT 
    CASE 
        WHEN discount_percent = 0 THEN 'No Discount'
        WHEN discount_percent BETWEEN 11 AND 20 THEN '11-20%'
        WHEN discount_percent BETWEEN 21 AND 30 THEN '21-30%'
        ELSE '30%+'
    END AS discount_range,
    COUNT(*) AS total_bookings,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS booking_percentage
FROM 
    oyodata
GROUP BY 1
ORDER BY 1;

-- 11. Distribution of new vs returning customers
WITH customer_bookings AS (
    SELECT 
        customer_id,
        MIN(date_of_booking) AS first_booking,
        COUNT(*) AS total_bookings
    FROM 
        oyodata
    GROUP BY 
        customer_id
)
SELECT 
    CASE 
        WHEN total_bookings = 1 THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()) AS percentage
FROM 
    customer_bookings
GROUP BY 
    CASE 
        WHEN total_bookings = 1 THEN 'New Customer'
        ELSE 'Returning Customer'
    END;



# Customer Behaviour
-- 12. Relationship between length of stay and revenue?
SELECT 
	CASE
         WHEN DATEDIFF(check_out,check_in) = 1 THEN '1 Day'
         WHEN DATEDIFF(check_out,check_in) BETWEEN 2 AND 3 THEN '2-3 Days'
         WHEN DATEDIFF(check_out,check_in) BETWEEN 4 AND 7 THEN '4-7 Days'
         ELSE '8+ Days'
         END AS 'stay_duration',
AVG(amount) as 'average_revenue',
COUNT(*) counts
FROM oyodata
WHERE status = 'Stayed'
GROUP BY 1;

-- 13. Segment Customers in High Spenders, Frequent Spenders, Frequent Cancellers
# Segmentation Criteria:
-- Frequent Bookers: Customers with more than a certain number of bookings.
-- High Spenders: Customers who spend more than a certain amount on bookings.
-- Frequent Cancellers: Customers with a high cancellation rate
WITH CTE AS (
SELECT customer_id, COUNT(*) total_bookings, SUM(amount) total_spent,
SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*) * 100 cancellation_rate,
CASE 
  WHEN COUNT(*) > 5 AND SUM(amount) > 6000 AND SUM(CASE WHEN status = 'Cancelled' THEN 1 ELSE 0 END) / COUNT(*) * 100 < 4 THEN 'Frequent_high_spenders'
  WHEN COUNT(*) > 5 THEN 'Frequent Bookers'
  WHEN SUM(amount) > 6000 THEN 'High Spenders'
  ELSE 'Other'
END AS segment
FROM oyodata
GROUP BY 1)
select *
from CTE
WHERE segment <> 'Other';


# Cancellation Analysis
-- 14. What is overall Cancellation Rate? 
SELECT 
  COUNT(CASE WHEN status = 'Cancelled' THEN 1 END) * 100.0 / COUNT(*) AS cancellation_rate
FROM oyodata;

-- 15. What is the monthly distribution of cancellations?
SELECT MONTHNAME(date_of_booking) 'month', COUNT(*) cancellations
FROM oyodata
WHERE status = 'Cancelled'
GROUP BY 1
ORDER BY 2 DESC;

-- 16. What is the cancellation rate across different hotels and cities?
WITH CTE AS(
SELECT 
    h.city,
    h.hotel_id,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN o.`status` = 'Cancelled' THEN 1 ELSE 0 END) AS canceled_bookings,
    (SUM(CASE WHEN o.`status` = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS cancellation_rate
FROM 
    oyodata o
JOIN 
    oyo_hotels h ON o.hotel_id = h.hotel_id
WHERE CITY IN ('Bangalore','Chennai','Delhi','Gurgaon','Hyderabad')  
GROUP BY 
    h.city, h.hotel_id
ORDER BY 
    h.city, cancellation_rate DESC), CTE2 AS(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY city ORDER BY cancellation_rate DESC) `rank`
FROM CTE)
SELECT city, hotel_id, cancellation_rate, `rank`
FROM CTE2
WHERE `rank` <=5;
