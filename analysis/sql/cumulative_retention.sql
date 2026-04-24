-- cumulative_retention.sql

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
,first_return AS
(
    SELECT
        customer_unique_id
        ,cohort_month
        ,MIN(month_number) AS first_return_month_number
    FROM cohort_periods
    WHERE month_number BETWEEN 1 AND 8
    GROUP BY 1, 2
)
,cumulative_returns AS
(
    SELECT DISTINCT
        cohort_month
        ,first_return_month_number
        ,COUNT(first_return_month_number) OVER (
            PARTITION BY cohort_month
            ORDER BY first_return_month_number
            RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_count
    FROM first_return
)
,cumulative_returns_alternative AS
(
    SELECT
        fr1.cohort_month
        ,fr1.first_return_month_number
        ,COUNT(DISTINCT fr2.customer_unique_id) AS cumlutive_count
    FROM first_return AS fr1
    INNER JOIN first_return AS fr2
        ON fr1.cohort_month = fr2.cohort_month
        AND fr1.first_return_month_number >= fr2.first_return_month_number
    GROUP BY 1, 2
)
,cohort_grid AS (
    SELECT
        ab.cohort_month
        ,gs AS month_number
    FROM generate_series(0, 8) AS gs
    CROSS JOIN (
        SELECT DISTINCT cohort_month
        FROM analysis_base
    ) AS ab
)
,cumulative_return_counts AS
(
    SELECT
        cg.cohort_month
        ,cg.month_number
        ,CASE
            WHEN cg.month_number = 0 THEN 0
            ELSE COALESCE(cr.cumulative_count,
                 MAX(cr.cumulative_count) OVER (
                     PARTITION BY cg.cohort_month
                     ORDER BY cg.month_number
                 )
            )
        END AS cum_count
    FROM cohort_grid AS cg
    LEFT JOIN cumulative_returns AS cr
        ON cg.cohort_month = cr.cohort_month
        AND cg.month_number = cr.first_return_month_number
)
,cohort_size AS
(
    SELECT
        cohort_month
        ,COUNT(DISTINCT customer_unique_id) AS cohort_size
    FROM cohort_periods
    WHERE month_number = 0
    GROUP BY 1
)
SELECT
    crc.cohort_month
    ,crc.month_number
    ,crc.cum_count
    ,cs.cohort_size
    ,ROUND(crc.cum_count::NUMERIC / cs.cohort_size, 6)::NUMERIC(7, 6) AS cumulative_retention
FROM cumulative_return_counts AS crc
INNER JOIN cohort_size cs
    ON crc.cohort_month = cs.cohort_month
ORDER BY 1, 2
;