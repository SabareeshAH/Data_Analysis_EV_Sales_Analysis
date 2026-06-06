/*
==============================================================================
Data Analysis Project - Indian EV Sales Analysis
==============================================================================
--> Data Cleaning, Preprocessing, Transformation is done and transferred to 
PostgreSQL DB under table IND_EV_Sales_Data

--> This SQL File focuses on Exploratory Data Analysis using SQL 
*/

--Checking the Database
SELECT * FROM "IND_EV_Sales_Data";

/*****************************************************************************
PostgreSQL EDA Questions (SQL-focused)
*****************************************************************************/

-- 1. What are total EV sales by state?
SELECT state, SUM(ev_sales_quantity) AS Total_EV_Sales
FROM "IND_EV_Sales_Data" 
GROUP BY state
ORDER BY SUM(ev_sales_quantity) DESC;

-- 2. Which vehicle category contributes the most to EV sales?
SELECT vehicle_category, SUM(ev_sales_quantity) AS Total_EV_Sales,
DENSE_RANK() OVER(ORDER BY SUM(ev_sales_quantity) DESC) AS Ranking
FROM "IND_EV_Sales_Data" 
GROUP BY vehicle_category
ORDER BY SUM(ev_sales_quantity) DESC;

-- 3. What is monthly EV sales trend across India?
SELECT year,month_name, SUM(ev_sales_quantity) AS "Total_EV_Sales"
FROM "IND_EV_Sales_Data" 
GROUP BY year, month_name
ORDER BY SUM(ev_sales_quantity) DESC;

-- 4. Which state has the highest average monthly EV sales?
SELECT state, ROUND(AVG(ev_sales_quantity),2) AS Total_EV_Sales,
DENSE_RANK() OVER(ORDER BY AVG(ev_sales_quantity) DESC) AS Ranking
FROM "IND_EV_Sales_Data" 
GROUP BY state
ORDER BY AVG(ev_sales_quantity) DESC;

-- 5. What is the rank of states based on total EV sales?
SELECT state, SUM(ev_sales_quantity) AS Total_EV_Sales,
RANK() OVER(ORDER BY SUM(ev_sales_quantity) DESC) AS Ranking
FROM "IND_EV_Sales_Data" 
GROUP BY state
ORDER BY SUM(ev_sales_quantity) DESC;

-- 6. What is the month-over-month growth in EV sales per state?
WITH SALES_CTE AS(
	-- A.Calculating the total sales state and monthwise 
	SELECT state, month_name, SUM(ev_sales_quantity) AS Total_EV_Sales
	FROM "IND_EV_Sales_Data" 
	GROUP BY state, month_name
	ORDER BY SUM(ev_sales_quantity) DESC
),
SALES_CTE_2 AS(
	-- A.Calculating the prev year total sales state and monthwise
	SELECT state, month_name, Total_EV_Sales,
	LAG(Total_EV_Sales) OVER(PARTITION BY state ORDER BY month_name) AS Prev_Month_Sales
	FROM Sales_CTE
),
SALES_CTE_3 AS(
	-- A.Calculating the month over month sales
	SELECT state, month_name, Total_EV_Sales, Prev_Month_Sales,
	ROUND((Total_EV_Sales - Prev_Month_Sales) * 100 / NULLIF(Prev_Month_Sales, 0),2) AS Month_Over_Month_Growth
	FROM SALES_CTE_2
)
-- D. Querying the results by rejecting the NULL Values
SELECT * FROM SALES_CTE_3
WHERE Month_Over_Month_Growth IS NOT NULL
ORDER BY Month_Over_Month_Growth DESC;

-- 7.Which vehicle class dominates in each state?
SELECT state, vehicle_class, count(vehicle_class) AS Vehicle_class_count,
DENSE_RANK() OVER(PARTITION BY state ORDER BY count(vehicle_class) DESC)
FROM "IND_EV_Sales_Data" 
GROUP BY state, vehicle_class
ORDER BY count(vehicle_class) DESC;

-- 8.What is cumulative EV sales over time?
SELECT date, state, ev_sales_quantity,
SUM(ev_sales_quantity) OVER(PARTITION BY state ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Cumulative_EV_Sales
FROM "IND_EV_Sales_Data"
GROUP BY date, state, ev_sales_quantity;

-- 9.Which states consistently appear in top 5 EV sales every month?
WITH CTE_sales AS (
	SELECT state, month, year, SUM(ev_sales_quantity) AS Total_EV_Sales,
	DENSE_RANK() OVER(PARTITION BY state, month, year ORDER BY SUM(ev_sales_quantity) DESC) AS Ranking
	FROM "IND_EV_Sales_Data" 
	GROUP BY state, month, year
	ORDER BY year ASC, month ASC, SUM(ev_sales_quantity) DESC
)
SELECT DISTINCT state FROM CTE_sales
WHERE Ranking <= 5;

-- 10. What is the contribution of each vehicle type to total sales percentage?
WITH VEH_CTE AS(
	SELECT vehicle_type, SUM(ev_sales_quantity) AS Total_EV_Sales
	FROM "IND_EV_Sales_Data" 
	GROUP BY vehicle_type
)
SELECT vehicle_type, Total_EV_Sales, 
ROUND((Total_EV_Sales * 100 / SUM(Total_EV_Sales) OVER()),2) AS Vehicle_Type_Contribution
FROM VEH_CTE
ORDER BY ROUND((Total_EV_Sales * 100 / SUM(Total_EV_Sales) OVER()),2) DESC;