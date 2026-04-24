-- customer_retention.sql

WITH cohort_base AS
(
    SELECT
        cc.customer_unique_id
        ,DATE_TRUNC('month', MIN(oc.order_purchase_timestamp)::date)::date AS cohort_month
    FROM analytics.customers_clean AS cc
    INNER JOIN analytics.orders_clean AS oc
        ON cc.customer_id = oc.customer_id
    WHERE oc.order_status = 'delivered'
    GROUP BY 1
)
,analysis_base AS
(
    SELECT
        customer_unique_id
        ,cohort_month
    FROM cohort_base
    WHERE cohort_month BETWEEN '2017-01-01' AND '2017-09-01'
)
,orders_enriched AS
(
    SELECT
        cc.customer_unique_id
        ,ab.cohort_month
        ,DATE_TRUNC('month', oc.order_purchase_timestamp::date)::date AS order_month
    FROM analysis_base ab
    INNER JOIN analytics.customers_clean AS cc
        ON ab.customer_unique_id = cc.customer_unique_id
    INNER JOIN analytics.orders_clean AS oc
        ON cc.customer_id = oc.customer_id
    WHERE oc.order_status = 'delivered'
)
,cohort_periods AS (
    SELECT
        customer_unique_id
        ,cohort_month
        ,order_month
        ,DATE_PART('year', AGE(order_month, cohort_month)) * 12 +
            DATE_PART('month', AGE(order_month, cohort_month)) AS month_number
    FROM orders_enriched
)
,retention_counts AS
(
    SELECT
        cohort_month
        ,month_number
        ,COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_periods
    WHERE month_number <= 8
    GROUP BY 1, 2
)
,generated_series AS (
    SELECT
        ab.cohort_month
        ,gs AS month_number
    FROM generate_series(0, 8) AS gs
    CROSS JOIN (
        SELECT DISTINCT cohort_month
        FROM analysis_base
    ) AS ab
)
,cohort_activitiy AS
(
    SELECT
        gs.cohort_month
        ,gs.month_number
        ,COALESCE(rc.active_customers, 0) AS active_customers
    FROM generated_series AS gs
    LEFT JOIN retention_counts AS rc
        ON gs.cohort_month = rc.cohort_month
        AND gs.month_number = rc.month_number
)
SELECT
    cohort_month
    ,month_number
    ,active_customers
    ,FIRST_VALUE(active_customers) OVER cohort_window AS cohort_size
    ,ROUND(
        active_customers::NUMERIC /
        FIRST_VALUE(active_customers) OVER cohort_window,
        6
     )::NUMERIC(7, 6) AS retention_rate
FROM cohort_activitiy
WINDOW cohort_window AS (
    PARTITION BY cohort_month
    ORDER BY month_number
)
ORDER BY 1, 2
;