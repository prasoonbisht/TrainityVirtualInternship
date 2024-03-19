/*
Operation Analytics and Investigating Metric Spike 
Case Study 1 : Job Data Analysis
Working with a table named job_data with the following columns:
job_id: Unique identifier of jobs
actor_id: Unique identifier of actor
event: The type of event (decision/skip/transfer).
language: The Language of the content
time_spent: Time spent to review the job in seconds.
org: The Organization of the actor
ds: The date in the format yyyy/mm/dd (stored as text).
*/

use operation_1;

-- 1) Jobs Reviewed Over Time: The number of jobs reviewed per hour for each day in November 2020.
SELECT 
    DATE(ds) AS date,
    COUNT(job_id) AS jobs_per_day,
    SUM(time_spent) / (60 * 60) AS hours_per_day
FROM
    job_data
WHERE
    ds BETWEEN '2020-11-1' AND '2020-11-30'
GROUP BY ds;


-- 2) Throughput Analysis (number of events per second): The 7-day rolling average of throughput
SELECT 
	DATE(ds), 
	ROUND(SUM(job_count) OVER (ORDER BY ds ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)/
    SUM(total_time) OVER (ORDER BY ds ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) 
	AS throughput_7d
FROM
(SELECT 
	ds, 
    COUNT(job_id) as job_count, SUM(time_spent) as total_time 
FROM 
	job_data
WHERE
	event IN ('transfer', 'decision')
GROUP BY ds, event) new_data;


-- 3)  The percentage share of each language over the last 30 days.
SELECT 
	language, 
    COUNT(language) as language_count, 
    COUNT(language)/COUNT(language)OVER() AS language_share
FROM 
	job_data
GROUP BY language
ORDER BY language_share DESC;


-- 4) Duplicate rows from the job_data table.
SELECT 
    actor_id, COUNT(*) AS Duplicates
FROM
    job_data
GROUP BY actor_id
HAVING COUNT(*) > 1;

SELECT 
    ds, job_id, actor_id, event, language, time_spent, org
FROM
    job_data
WHERE
    job_id IN (SELECT 
            job_id
        FROM
            job_data
        GROUP BY job_id
        HAVING COUNT(job_id) > 1);



/*
Case Study 2 : Investigating Metric Spike
Working with three tables:
users: Contains one row per user, with descriptive information about that user’s account.
events: Contains one row per event, where an event is an action that a user has taken (e.g., login, messaging, search).
email_events: Contains events specific to the sending of emails.
*/

use metric_spike;
use operation_n_metric;

-- 1) Weekly user engagement.
SELECT 
    EXTRACT(WEEK FROM occurred_at) AS Week,
    event_name,
    COUNT(event_name) AS event_count
FROM
    events
WHERE
    event_type = 'engagement'
GROUP BY Week , event_name; 


-- 2)  User growth for the product
SELECT 
	*, 
    COALESCE(users - LAG(users) OVER (PARTITION BY product ORDER BY year, month), 0) AS growth
FROM
(SELECT 
    EXTRACT(YEAR FROM occurred_at) AS year,
    EXTRACT(MONTH FROM occurred_at) AS month,
    device AS Product, 
    COUNT(DISTINCT user_id) AS users
FROM 
    events
GROUP BY 
    year, month, Product
ORDER BY 
    year, month) d;


-- 3) Weekly retention of users based on their sign-up cohort
SELECT 
    EXTRACT(WEEK FROM created_at) AS activation_week,
    COUNT(DISTINCT user_id) AS all_users,
    COUNT(DISTINCT CASE
        WHEN state = 'active' THEN user_id
    END) AS active_users
FROM
    users
GROUP BY 1;


-- 4) Weekly engagement per device
SELECT 
    EXTRACT(WEEK FROM occurred_at) AS wwk,
    COUNT(DISTINCT user_id) AS weekly_users_per_device,
    COUNT(DISTINCT CASE
            WHEN
                device IN ('macbook pro' , 'lenovo thinkpad',
                    'macbook air',
                    'dell inspiron notebook',
                    'asus chromebook',
                    'dell inspiron desktop',
                    'acer aspire notebook',
                    'hp pavilion desktop',
                    'acer aspire desktop',
                    'mac mini')
            THEN
                user_id
            ELSE NULL
        END) AS computer,
    COUNT(DISTINCT CASE
            WHEN
                device IN ('iphone 5' , 'samsung galaxy s4',
                    'nexus 5',
                    'nexus 7',
                    'nexus 10',
                    'iphone 5s',
                    'iphone 4s',
                    'nokia lumia 635',
                    'htc one',
                    'samsung galaxy note',
                    'amazon fire phone')
            THEN
                user_id
            ELSE NULL
        END) AS smart_phone,
    COUNT(DISTINCT CASE
            WHEN
                device IN ('ipad air' , 'nexus 7',
                    'ipad mini',
                    'nexus 10',
                    'kindle fire',
                    'windows surface',
                    'samsung galaxy tablet')
            THEN
                user_id
            ELSE NULL
        END) AS tablet
FROM
    events
WHERE
    event_type = 'engagement'
        AND event_name = 'login'
GROUP BY 1
ORDER BY 1;


-- 5) Email engagement metrics
SELECT 
	Week,
    ROUND((Sent_Weekly_Digest/total)*100, 2) AS Weekly_Digest_Rate,
    ROUND((Weekly_Email_Open/total)*100, 2) AS Weekly_Email_Open_Rate,
    ROUND((Weekly_Email_Clickthrough/total)*100, 2) AS Weekly_Email_Clickthrough_Rate,
    ROUND((Weekly_Sent_Reengagement_Email/total)*100, 2) AS Weekly_Sent_Reengagement_Email_Rate
FROM
	(SELECT 
		EXTRACT(WEEK FROM occurred_at) AS Week,
		COUNT(CASE
				WHEN action = 'sent_weekly_digest' THEN user_id
			END) AS Sent_Weekly_Digest,
		COUNT(CASE
				WHEN action = 'email_open' THEN user_id
			END) AS Weekly_Email_Open,
		COUNT(CASE
				WHEN action = 'email_clickthrough' THEN user_id
			END) AS Weekly_Email_Clickthrough,
		COUNT(CASE
				WHEN action = 'sent_reengagement_email' THEN user_id
			END) AS Weekly_Sent_Reengagement_Email,
		COUNT(user_id) AS total
	FROM
		email_events
	GROUP BY 1) sub
GROUP BY 1;