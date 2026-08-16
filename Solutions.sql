    -- Question a: How many unique customers? 
    SELECT count(distinct customer_id) as total_customers 
    FROM subscriptions;
    -- Question b: How many subscription events?
    SELECT
    COUNT(*)  total_subscriptions
    FROM subscriptions;
  -- Question c: How many events occurred for each plan? 
  SELECT p.plan_name, COUNT(*) as total_events
  FROM subscriptions as s
  JOIN plans as p
  ON s.plan_id= p.plan_id
  GROUP BY p.plan_name
  ORDER BY  total_events desc;
  -- Question 1: How many customers has Foodie-Fi ever had? 
  SELECT
  COUNT( DISTINCT customer_id) as total_customers
  FROM subscriptions;
  --  Question 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
  SELECT
    DATE_FORMAT(start_date, '%Y-%m-01') AS trial_month,
    COUNT(DISTINCT customer_id) AS trial_customers
FROM subscriptions
WHERE plan_id = 0
GROUP BY
    DATE_FORMAT(start_date, '%Y-%m-01')
ORDER BY
    trial_month;
--  Question 3 . Which subscription plans have the highest number of events? 
SELECT
p.plan_name , 
COUNT(*) AS total_events
 FROM subscriptions AS s 
 JOIN plans AS p
 ON s.plan_id = p.plan_id
 GROUP BY
 p.plan_name, p.plan_id
 ORDER BY
 total_events DESC;
 -- Question 4. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name 
  SELECT 
  p.plan_name, count(*) AS total_events
 FROM subscriptions AS s 
 JOIN plans AS p 
 ON s.plan_id = p.plan_id
 WHERE 
 s.start_date >= '2021-01-01'
 GROUP BY p.plan_name;
 -- Question 5. What is the customer count and percentage of customers who have churned rounded to 1 decimal place? 
select count(distinct customer_id) as customer_count,
count(distinct case when plan_id = 4 Then customer_id end) as churned_customers,
ROUND(COUNT(DISTINCT CASE
WHEN plan_id = 4 THEN customer_id
END) * 100.0 / COUNT(DISTINCT customer_id), 1) AS churn_percentage
 from subscriptions ;

--  Question 6. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH customer_journey AS (
    SELECT
        customer_id,
        plan_id,
        start_date,
        LEAD(plan_id) OVER (
            PARTITION BY customer_id
            ORDER BY start_date
        ) AS next_plan_id
    FROM subscriptions
)

SELECT
    COUNT(DISTINCT customer_id) AS churned_after_trial,
    ROUND(
        COUNT(DISTINCT customer_id) * 100.0
        / (SELECT COUNT(DISTINCT customer_id)
           FROM subscriptions),
        0
    ) AS percentage_of_customers
FROM customer_journey
WHERE plan_id = 0
  AND next_plan_id = 4;

-- Question 7. What is the number and percentage of customers who churned after becoming paid subscribers?

WITH customer_status AS (
SELECT customer_id,
MAX(CASE WHEN plan_id IN (1, 2, 3) THEN 1 ELSE 0  END) AS became_paid,
MAX(CASE WHEN plan_id = 4 THEN 1 ELSE 0 END) AS churned
FROM subscriptions
GROUP BY customer_id)

SELECT COUNT(*) AS churned_after_paid,
ROUND(COUNT(*) * 100.0 /
(SELECT COUNT(DISTINCT customer_id)
FROM subscriptions),1) AS percentage_of_customers
FROM customer_status
WHERE became_paid = 1
AND churned = 1;

  -- Question 8 . What is the number and percentage of customer plans after their initial free trial?

WITH customer_journey AS (SELECT customer_id, plan_id, start_date,
LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id
FROM subscriptions)

SELECT p.plan_name AS plan_after_trial,COUNT(DISTINCT cj.customer_id) AS customer_count,
ROUND(COUNT(DISTINCT cj.customer_id) * 100.0 / (SELECT COUNT(DISTINCT customer_id)
FROM subscriptions),1) AS percentage_of_customers
FROM customer_journey AS cj
JOIN plans AS p
ON cj.next_plan_id = p.plan_id
WHERE cj.plan_id = 0
GROUP BY p.plan_name
ORDER BY customer_count DESC;
    
-- Question 9. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH customer_plans AS (SELECT customer_id,plan_id,start_date,
ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS rn
FROM subscriptions
WHERE start_date <= '2020-12-31')

SELECT p.plan_name,COUNT(*) AS customer_count,
ROUND(COUNT(*) * 100.0 /
(SELECT COUNT(*) FROM customer_plans WHERE rn = 1),1) AS percentage
FROM customer_plans AS cp
JOIN plans AS p
ON cp.plan_id = p.plan_id
WHERE cp.rn = 1
GROUP BY p.plan_name
ORDER BY customer_count DESC; 


-- Question 10. How many customers have upgraded to an annual plan in 2020?

SELECT COUNT(DISTINCT customer_id) AS customers_upgraded_to_annual
FROM subscriptions
WHERE plan_id = 3
AND start_date >= '2020-01-01'
AND start_date < '2021-01-01'; 

-- Question 11. How many customers downgraded from a Pro Monthly plan to a Basic Monthly plan in 2020?

WITH plan_changes AS
(SELECT customer_id,plan_id AS current_plan,start_date,
LEAD(plan_id) OVER ( PARTITION BY customer_id ORDER BY start_date) AS next_plan,
LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_start_date
FROM subscriptions)

SELECT COUNT(DISTINCT customer_id) AS downgraded_customers
FROM plan_changes
WHERE current_plan = 2
AND next_plan = 1
AND next_start_date >= '2020-01-01'
AND next_start_date < '2021-01-01';

  -- Question 12. How many customers upgraded from a Basic Monthly plan to a Pro Monthly plan in 2020?

WITH plan_changes AS (SELECT customer_id,plan_id AS current_plan,start_date,
LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan,
LEAD(start_date) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_start_date
FROM subscriptions)

SELECT COUNT(DISTINCT customer_id) AS upgraded_customers
FROM plan_changes
WHERE current_plan = 1
AND next_plan = 2
AND next_start_date >= '2020-01-01'
AND next_start_date < '2021-01-01';

-- Question 13. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT ROUND(AVG(DATEDIFF(annual.start_date,first_join.first_start_date)),0) AS average_days_to_annual
FROM
(SELECT customer_id,MIN(start_date) AS first_start_date
FROM subscriptions
GROUP BY customer_id) AS first_join
JOIN subscriptions AS annual
ON first_join.customer_id = annual.customer_id
WHERE annual.plan_id = 3; 

-- Question 14. Which month had the highest number of new customers?
WITH first_join AS (
    SELECT
        customer_id,
        MIN(start_date) AS first_join_date
    FROM subscriptions
    GROUP BY customer_id
)

SELECT
    DATE_FORMAT(first_join_date, '%Y-%m-01') AS join_month,
    COUNT(*) AS new_customers
FROM first_join
GROUP BY DATE_FORMAT(first_join_date, '%Y-%m-01')
ORDER BY new_customers DESC; 
-- Question 15 : How has the customer base changed over time?
WITH first_join AS (
    SELECT
        customer_id,
        MIN(start_date) AS first_join_date
    FROM subscriptions
    GROUP BY customer_id
),

monthly_customers AS (
    SELECT
        DATE_FORMAT(first_join_date, '%Y-%m-01') AS join_month,
        COUNT(*) AS new_customers
    FROM first_join
    GROUP BY DATE_FORMAT(first_join_date, '%Y-%m-01')
)

SELECT
    join_month,
    new_customers,
    SUM(new_customers) OVER (
        ORDER BY join_month
    ) AS cumulative_customers
FROM monthly_customers
ORDER BY join_month; 
 -- Question 16. Which subscription plan has the highest number of customers? 
SELECT
    p.plan_name,
    COUNT(DISTINCT s.customer_id) AS total_customers
FROM subscriptions AS s
JOIN plans AS p
    ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY total_customers DESC;
-- Question 17. What percentage of customers have ever subscribed to a paid plan?
SELECT
    ROUND(
        COUNT(DISTINCT CASE
            WHEN plan_id IN (1, 2, 3) THEN customer_id
        END) * 100.0
        / COUNT(DISTINCT customer_id),
        1
    ) AS paid_plan_percentage
FROM subscriptions; 
--  Question 18. What is the average number of days customers stayed on the Basic Monthly plan before their next subscription event?
WITH plan_changes AS (
    SELECT
        customer_id,
        plan_id,
        start_date,
        LEAD(start_date) OVER (
            PARTITION BY customer_id
            ORDER BY start_date
        ) AS next_start_date
    FROM subscriptions
)

SELECT
    ROUND(AVG(DATEDIFF(next_start_date, start_date)), 0) AS avg_days_on_basic_monthly
FROM plan_changes
WHERE plan_id = 1
  AND next_start_date IS NOT NULL;
  -- Question 19.On average, how many days does it take customers to move from their initial trial to their first paid subscription?
  
  SELECT
    ROUND(
        AVG(
            DATEDIFF(first_paid_date, trial_date)
        ),
        0
    ) AS avg_days_to_first_paid_plan
FROM (
    SELECT
        customer_id,

        MIN(
            CASE
                WHEN plan_id = 0
                THEN start_date
            END
        ) AS trial_date,

        MIN(
            CASE
                WHEN plan_id IN (1, 2, 3)
                THEN start_date
            END
        ) AS first_paid_date

    FROM subscriptions
    GROUP BY customer_id
) AS customer_dates
WHERE trial_date IS NOT NULL
  AND first_paid_date IS NOT NULL;
  
  -- Question 20. What percentage of customers who subscribed to a paid plan eventually churned?
  SELECT
    COUNT(DISTINCT CASE
        WHEN plan_id = 4 THEN customer_id
    END) AS churned_customers,

    COUNT(DISTINCT CASE
        WHEN plan_id IN (1, 2, 3) THEN customer_id
    END) AS paid_customers,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN plan_id = 4 THEN customer_id
        END) * 100.0
        /
        COUNT(DISTINCT CASE
            WHEN plan_id IN (1, 2, 3) THEN customer_id
        END),
        1
    ) AS paid_customer_churn_rate
FROM subscriptions;
