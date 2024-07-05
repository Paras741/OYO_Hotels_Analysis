# Booking Trends
-- 1. What is the total number of bookings per month?
SELECT DATE_FORMAT(date_of_booking,'%Y-%m') `month`, COUNT(booking_id) total_no_booking
FROM oyodata
GROUP BY 1;

-- 2. What is the Average length of stay?
SELECT AVG(DATEDIFF(check_out, check_in)) avg_length_of_stay
FROM oyodata
WHERE status = 'Stayed';

-- 3. How does the booking volume vary by day of the week?
SELECT DAYNAME(date_of_booking) `Day`, COUNT(booking_id) no_of_booking
FROM oyodata
GROUP BY 1
ORDER BY 2 DESC;

# Revenue Analysis
-- 4. What is the total revenue generated per month?
SELECT MONTHNAME(date_of_booking) `month`, SUM(amount) `total_amount`
FROM oyodata
GROUP BY 1;

-- 5.How does revenue vary by city?
SELECT city, AVG(amount) total_revenue
FROM oyodata o 
JOIN oyo_hotels oh
ON o.hotel_id = oh.Hotel_id
GROUP BY 1
ORDER BY 2 DESC;

-- 6. Find top 5 Highest revenue generated hotels in top cities?
WITH CTE AS(
SELECT oh.city, oh.hotel_id, SUM(amount) total_revenue
FROM oyodata o 
JOIN oyo_hotels oh
ON o.hotel_id = oh.Hotel_id
WHERE `status` = 'Stayed' AND city IN ('Gurgaon','Bangalore','Delhi','Mumbai','Pune')
GROUP BY 1,2), CTE2 AS(
SELECT *,
DENSE_RANK() OVER(PARTITION BY city ORDER BY total_revenue DESC) `rank`
FROM CTE)
SELECT city, hotel_id, total_revenue
FROM CTE2
WHERE `rank` <= 5;

# Hotel Performance
-- 7. Find top 5 most visiting hotels in top 5 visiting cities?
WITH CTE AS(
SELECT oh.city, oh.hotel_id, COUNT(booking_id) visiting
FROM oyodata o 
JOIN oyo_hotels oh
ON o.hotel_id = oh.Hotel_id
WHERE `status` = 'Stayed' AND city IN ('Gurgaon','Delhi','Bangalore','Noida','Mumbai')
GROUP BY 1,2), CTE2 AS(
SELECT *,
ROW_NUMBER() OVER(PARTITION BY city ORDER BY visiting DESC) `rank`
FROM CTE)
SELECT city, hotel_id, visiting
FROM CTE2
WHERE `rank` <= 5;

-- 8. Which hotels have the highest occupancy rates?
SELECT hotel_id,
SUM(CASE WHEN `status` = 'Stayed' THEN no_of_rooms ELSE NULL END) / SUM(no_of_rooms)*100 occupancy_rate # sum of rooms for each hotel id
FROM oyodata
GROUP BY 1
ORDER BY 2 DESC;

-- 9. Top 10 hotels with highest booking rates?
SELECT hotel_id, COUNT(*) AS total_bookings
FROM oyodata
GROUP BY hotel_id
ORDER BY total_bookings DESC
LIMIT 10;

