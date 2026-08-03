Problem 1 : How many customers has Foodie-Fi ever had?

Solution :
SELECT
COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;




Problem 2 : What is the monthly distribution of trial plan start_date values ? — Use the start of the month as the group by value

Solution :
SELECT DATE_TRUNC('month',start_date),COUNT(*)
FROM subscriptions
WHERE plan_id=0
GROUP BY DATE_TRUNC('month',start_date)
ORDER BY 1;




Problem 3 : What plan_name values occur after the year 2020? Show the number of subscription events for each plan.

Solution :
SELECT p.plan_name, COUNT(*) AS total_events
FROM subscriptions s
JOIN plans p
ON s.plan_id = p.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_name
ORDER BY total_events DESC;


Problem 4 : What is the customer count and percentage of customers who have churned? Round the percentage to one decimal place.

Solution :
SELECT COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) AS churned_customers,
ROUND(COUNT(DISTINCT CASE WHEN plan_id = 4 THEN customer_id END) * 100.0 /
COUNT(DISTINCT customer_id), 1) AS churn_percentage
FROM subscriptions;


Problem 5: Customers who churned immediately after their free trial

  
Solution :
  
WITH next_plan AS
(SELECT customer_id,plan_id,
LEAD(plan_id) OVER(PARTITION BY customer_id
ORDER BY start_date) AS next_plan
FROM subscriptions)

SELECT COUNT(*) AS customer_count,
ROUND(COUNT(*) * 100.0 /
(SELECT COUNT(DISTINCT customer_id)
FROM subscriptions), 0) AS percentage
FROM next_plan
WHERE plan_id=0
AND next_plan=4;
