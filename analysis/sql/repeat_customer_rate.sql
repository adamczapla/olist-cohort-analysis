-- repeat_customer_rate.sql

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
,cohort_size_base AS
(
    SELECT
        ab.cohort_month
        ,COUNT(DISTINCT cc.customer_unique_id) AS cohort_size
    FROM analysis_base ab
    INNER JOIN analytics.customers_clean AS cc
        ON ab.customer_unique_id = cc.customer_unique_id
    INNER JOIN analytics.orders_clean AS oc
        ON cc.customer_id = oc.customer_id
    GROUP BY 1
)
,repeat_customers AS
(
    SELECT
        ab.cohort_month
        ,cc.customer_unique_id
    FROM analysis_base ab
    INNER JOIN analytics.customers_clean AS cc
        ON ab.customer_unique_id = cc.customer_unique_id
    INNER JOIN analytics.orders_clean AS oc
        ON cc.customer_id = oc.customer_id
    WHERE oc.order_status = 'delivered'
    GROUP BY 1, 2
    HAVING count(*) > 1
)
SELECT
    re.cohort_month
    ,csb.cohort_size
    ,COUNT(*) AS repeated_customers
    ,ROUND(COUNT(*)::NUMERIC / csb.cohort_size, 6)::NUMERIC(7, 6) AS repeat_rate
FROM repeat_customers AS re
INNER JOIN cohort_size_base AS csb
    ON re.cohort_month = csb.cohort_month
GROUP BY 1, 2
ORDER BY 1
;