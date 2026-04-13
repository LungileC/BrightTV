select * from `workspace`.`brighttv`.`user_profiles` limit 100;


select * 
from `workspace`.`brighttv`.`viewership` as V
left join `workspace`.`brighttv`.`user_profiles` as UP 
on V.UserID0 = UP.UserID limit 10;

---Converting UTC time to SA time
SELECT 
    *,
    from_utc_timestamp(TO_TIMESTAMP(v.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg') AS sast_timestamp
FROM `workspace`.`brighttv`.`viewership` AS v;


-------------------------------------------------

CREATE OR REPLACE TEMP VIEW transactions_clean AS
SELECT 
    *,
    from_utc_timestamp(RecordDate2, 'Africa/Johannesburg') AS sa_time
FROM workspace.brighttv.viewership;


---------------------------------------------
SELECT 
    UserID0 AS user_id,
    sa_time,
    date(sa_time) AS watch_date,
    hour(sa_time) AS watch_hour,
    dayofweek(sa_time) AS day_of_week
FROM transactions_clean;


SELECT 
    UP.UserID AS user_id,
    UP.Age,
    UP.Gender,
    UP.Province,
    V.Channel2,
    V.RecordDate2
FROM workspace.brighttv.user_profiles AS UP
LEFT JOIN workspace.brighttv.viewership AS V
    ON UP.UserID = V.UserID0;


---==========================================
-- 1. total viewing records per user
---==========================================
SELECT 
    UserID0 AS user_id,
    COUNT(*) AS total_viewing_records,
    COUNT(DISTINCT Channel2) AS unique_channels_watched
FROM workspace.brighttv.viewership
GROUP BY UserID0;


-- 1.1 Most watched channel

SELECT 
    Channel2,
    COUNT(*) AS total_views
FROM workspace.brighttv.viewership
GROUP BY Channel2
ORDER BY total_views DESC
LIMIT 10;


---==========================================
-- 2 record watching time per user
---==========================================

SELECT 
    UserID0 AS user_id,
    SUM(DATEDIFF(`Duration 2`, RecordDate2)) AS total_minutes_watched
FROM workspace.brighttv.viewership
GROUP BY UserID0 
ORDER BY total_minutes_watched DESC
LIMIT 10;



--- Peak viewing times ---

SELECT HOUR(RecordDate2) AS watch_hour, COUNT(*) AS total_views
FROM workspace.brighttv.viewership
GROUP BY HOUR(RecordDate2)
ORDER BY total_views DESC;



--- Low Consumption days ---
SELECT RecordDate2  AS watch_date, COUNT(*) AS total_views
FROM workspace.brighttv.viewership
GROUP BY RecordDate2
ORDER BY total_views ASC
LIMIT 10;



--- most watched channel ----
SELECT Channel2, COUNT(*) AS views
FROM workspace.brighttv.viewership
GROUP BY Channel2
ORDER BY views DESC;



--- View by gender ---
SELECT 
    Gender,
    COUNT(*) AS total_views,
    COUNT(DISTINCT V.Channel2) AS unique_channels
FROM workspace.brighttv.user_profiles AS UP
LEFT JOIN workspace.brighttv.viewership AS V
    ON UP.UserID = V.UserID0
GROUP BY Gender;


--views by age group 

SELECT 
    CASE 
        WHEN Age < 25 THEN 'Under 25'
        WHEN Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN Age BETWEEN 35 AND 44 THEN '35-44'
        ELSE '45+'
    END AS age_group,
    COUNT(*) AS total_views,
    COUNT(DISTINCT V.Channel2) AS unique_channels
FROM workspace.brighttv.user_profiles as UP
LEFT JOIN workspace.brighttv.viewership as V
    ON UP.UserID = V.UserID0
GROUP BY age_group
ORDER BY total_views DESC;


-- Consumption by demographic
SELECT 
    UP.Gender,
    UP.Age,
    UP.Province,
    COUNT(DISTINCT V.UserID0) as viewers,
    COUNT(*) as total_sessions
FROM workspace.brighttv.viewership as V
LEFT JOIN workspace.brighttv.user_profiles as UP
ON V.UserID0 = UP.UserID
WHERE UP.Age > 0 AND UP.Age < 100
GROUP BY 1, 2, 3
ORDER BY total_sessions DESC;


-- Identify low consumption days
WITH daily_stats AS (
SELECT 
        DATE(RecordDate2) as watch_date,
        DAYOFWEEK(RecordDate2) as day_num,
        CASE DAYOFWEEK(RecordDate2)
            WHEN 1 THEN 'Sunday' WHEN 2 THEN 'Monday' WHEN 3 THEN 'Tuesday'
            WHEN 4 THEN 'Wednesday' WHEN 5 THEN 'Thursday' WHEN 6 THEN 'Friday'
            WHEN 7 THEN 'Saturday'
        END as weekday,
        COUNT(*) as daily_sessions,
        COUNT(DISTINCT UserID0) as daily_unique_users
    FROM workspace.brighttv.viewership
    GROUP BY 1, 2, 3
),
avg_stats AS (
    SELECT 
        day_num,
        weekday,
        AVG(daily_sessions) as avg_sessions,
        STDDEV(daily_sessions) as stddev_sessions
    FROM daily_stats
    GROUP BY 1, 2
)
SELECT 
    ds.watch_date,
    ds.weekday,
    ds.daily_sessions,
    ds.daily_unique_users,
    as_.avg_sessions,
    ROUND((ds.daily_sessions - as_.avg_sessions) / as_.stddev_sessions, 2) as z_score,
    CASE 
        WHEN ds.daily_sessions < as_.avg_sessions - as_.stddev_sessions THEN 'Very Low'
        WHEN ds.daily_sessions < as_.avg_sessions THEN 'Below Average'
        ELSE 'Normal'
    END as consumption_level
FROM daily_stats ds
JOIN avg_stats as_ ON ds.day_num = as_.day_num
WHERE ds.daily_sessions < as_.avg_sessions
ORDER BY z_score ASC;

---======================================
--- final input
---=======================================

-- Final master query combining key metrics for presentation
CREATE OR REPLACE TEMP VIEW master_insights AS
SELECT 
    '1_Total_Users' as metric_category,
    'Total Users' as metric_name,
    CAST(COUNT(DISTINCT UserID) AS STRING) as metric_value
FROM workspace.brighttv.user_profiles
WHERE Age > 0 AND Age < 100

UNION ALL

SELECT 
    '1_Total_Users',
    'Active Viewers',
    CAST(COUNT(DISTINCT UserID0) AS STRING)
FROM workspace.brighttv.viewership

UNION ALL

SELECT 
    '2_Consumption',
    'Total Viewing Sessions',
    CAST(COUNT(*) AS STRING)
FROM workspace.brighttv.viewership

UNION ALL

SELECT 
    '2_Consumption',
    'Unique Channels',
    CAST(COUNT(DISTINCT Channel2) AS STRING)
FROM workspace.brighttv.viewership

UNION ALL

(
    SELECT 
        '3_Top_Channels',
        Channel2,
        CAST(COUNT(*) AS STRING)
    FROM workspace.brighttv.viewership
    GROUP BY Channel2
    ORDER BY COUNT(*) DESC
    LIMIT 5
)

UNION ALL

SELECT 
    '4_Demographics',
    CONCAT('Avg Age: ', CAST(ROUND(AVG(Age), 1) AS STRING)),
    CONCAT('Male: ', CAST(COUNT(CASE WHEN Gender='male' THEN 1 END) AS STRING), 
           ' | Female: ', CAST(COUNT(CASE WHEN Gender='female' THEN 1 END) AS STRING))
FROM workspace.brighttv.user_profiles
WHERE Age > 0 AND Age < 100

UNION ALL

(
    SELECT 
        '5_Most_Active_Province',
        Province,
        CAST(COUNT(DISTINCT UserID) AS STRING)
    FROM workspace.brighttv.user_profiles
    WHERE Province IS NOT NULL
    GROUP BY Province
    ORDER BY COUNT(DISTINCT UserID) DESC
    LIMIT 1
);



-- Final output - all insights in one table
SELECT * FROM master_insights
ORDER BY metric_category, metric_name;

---======================================
---Big Query--
---======================================

WITH viewership_clean AS (
    SELECT 
        V.*,
        from_utc_timestamp(TO_TIMESTAMP(V.RecordDate2, 'yyyy/MM/dd HH:mm'), 'Africa/Johannesburg') AS sa_time
    FROM workspace.brighttv.viewership V
),

viewership_features AS (
    SELECT 
        UserID0 AS user_id,
        Channel2,
        sa_time,
        DATE(sa_time) AS watch_date,
        HOUR(sa_time) AS watch_hour,
        DAYOFWEEK(sa_time) AS day_of_week
    FROM viewership_clean
),

user_consumption AS (
    SELECT 
        UserID0 AS user_id,
        COUNT(*) AS total_views,
        COUNT(DISTINCT Channel2) AS unique_channels,
        COALESCE(SUM(DATEDIFF(`Duration 2`, RecordDate2)), 0) AS total_minutes_watched
    FROM workspace.brighttv.viewership
    GROUP BY UserID0
),

daily_stats AS (
    SELECT 
        DATE(sa_time) as watch_date,
        DAYOFWEEK(sa_time) as day_num,
        CASE DAYOFWEEK(sa_time)
            WHEN 1 THEN 'Sunday'
            WHEN 2 THEN 'Monday'
            WHEN 3 THEN 'Tuesday'
            WHEN 4 THEN 'Wednesday'
            WHEN 5 THEN 'Thursday'
            WHEN 6 THEN 'Friday'
            WHEN 7 THEN 'Saturday'
        END as weekday,
        COUNT(*) as daily_sessions,
        COUNT(DISTINCT user_id) as daily_unique_users
    FROM viewership_features
    GROUP BY 1,2,3
),

avg_stats AS (
    SELECT 
        day_num,
        weekday,
        AVG(daily_sessions) as avg_sessions,
        STDDEV(daily_sessions) as stddev_sessions
    FROM daily_stats
    GROUP BY 1,2
)

SELECT 
    UP.UserID AS user_id,
    
    -- Handle NULLs / missing values
    COALESCE(UP.Gender, 'Unknown') AS gender,
    COALESCE(UP.Province, 'Unknown') AS province,
    COALESCE(UP.Race, 'Unknown') AS race,
    
    -- Age grouping with IF logic
    CASE 
        WHEN UP.Age IS NULL THEN 'Unknown'
        WHEN UP.Age < 25 THEN 'Under 25'
        WHEN UP.Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN UP.Age BETWEEN 35 AND 44 THEN '35-44'
        ELSE '45+'
    END AS age_group,

    VF.Channel2,
    VF.watch_date,
    VF.watch_hour,
    VF.day_of_week,

    -- Aggregations
    COUNT(VF.user_id) AS total_sessions,
    COALESCE(SUM(UC.total_minutes_watched), 0) AS total_minutes_watched,
    COALESCE(MAX(UC.unique_channels), 0) AS unique_channels,

    -- Peak / Low classification
    CASE 
        WHEN DS.daily_sessions IS NULL THEN 'No Data'
        WHEN DS.daily_sessions < AS_.avg_sessions - AS_.stddev_sessions THEN 'Very Low'
        WHEN DS.daily_sessions < AS_.avg_sessions THEN 'Below Average'
        ELSE 'Normal'
    END AS consumption_level

FROM workspace.brighttv.user_profiles UP

LEFT JOIN viewership_features VF
    ON UP.UserID = VF.user_id

LEFT JOIN user_consumption UC
    ON UP.UserID = UC.user_id

LEFT JOIN daily_stats DS
    ON VF.watch_date = DS.watch_date

LEFT JOIN avg_stats AS_
    ON DS.day_num = AS_.day_num

GROUP BY 
    UP.UserID,
    UP.Gender,
    UP.Province,
    UP.Race,
    UP.Age,
    VF.Channel2,
    VF.watch_date,
    VF.watch_hour,
    VF.day_of_week,
    DS.daily_sessions,
    AS_.avg_sessions,
    AS_.stddev_sessions;
