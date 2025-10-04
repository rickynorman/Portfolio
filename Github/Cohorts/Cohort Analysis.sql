/* Segments customers by initial discount amount and discount code used, tracking their LTV, retention rates, and average days between first and second orders over one year. */

WITH profile_entry_month AS (
    SELECT
        profile_id,
        MIN(placed_at) AS first_order_timestamp,
        TRY(ARRAY_AGG(placed_at ORDER BY placed_at ASC)[2]) AS second_order_timestamp,
        MIN(placed_at) AS first_order_at,
        ARRAY_AGG(ROUND(total_discounts / 20) * 20 ORDER BY placed_at)[1] AS discount_amount,
        ARRAY_AGG(TRY(discount_codes[1]) ORDER BY placed_at ASC)[1] AS entry_code
    FROM production.orders
    WHERE total_price > 0
    AND payment_status = 'PAID'
    AND source_name NOT LIKE '%exchange%'
    AND source_name NOT IN ('pos', '1662707')
    AND store_id = '804ab081-7cc3-49db-a6ef-7f1e84c852f1'
    GROUP BY profile_id
    HAVING MIN(placed_at) > NOW() - interval '2' year
),

profile_stats AS (
    SELECT
        profile_id,
        SUM(total_price - total_tax - total_refunded) AS LTV,
        SUM(IF(placed_at < first_order_at + interval '30' day, total_price - total_tax - total_refunded, 0)) AS day_30_LTV,
        SUM(IF(placed_at < first_order_at + interval '90' day, total_price - total_tax - total_refunded, 0)) AS day_90_LTV,
        SUM(IF(placed_at < first_order_at + interval '180' day, total_price - total_tax - total_refunded, 0)) AS day_180_LTV,
        SUM(IF(placed_at < first_order_at + interval '365' day, total_price - total_tax - total_refunded, 0)) AS day_365_LTV,
        SIGN(SUM(IF(placed_at != first_order_at, 1, 0))) AS retention,
        SIGN(SUM(IF(placed_at != first_order_at AND placed_at < first_order_at + interval '30' day, 1, 0))) AS day_30_retention,
        SIGN(SUM(IF(placed_at != first_order_at AND placed_at < first_order_at + interval '90' day, 1, 0))) AS day_90_retention,
        SIGN(SUM(IF(placed_at != first_order_at AND placed_at < first_order_at + interval '180' day, 1, 0))) AS day_180_retention,
        SIGN(SUM(IF(placed_at != first_order_at AND placed_at < first_order_at + interval '365' day, 1, 0))) AS day_365_retention
    FROM production.orders
    LEFT JOIN profile_entry_month USING(profile_id)
    WHERE total_price > 0
    AND store_id = '804ab081-7cc3-49db-a6ef-7f1e84c852f1'
    AND payment_status = 'PAID' 
    AND source_name NOT LIKE '%exchange%'
    AND source_name NOT IN ('pos', '1662707')
    GROUP BY profile_id
)

SELECT
    IF(discount_amount > 160, 160, discount_amount) AS cohort, -- Discount amount rounnded to the nearest $10
    entry_code,
    COUNT(profile_id) AS cohort_size,
    IF(MIN(first_order_at) + interval '30' day < NOW(), AVG(day_30_LTV), NULL) AS day_30_LTV,
    IF(MIN(first_order_at) + interval '90' day < NOW(), AVG(day_90_LTV), NULL) AS day_90_LTV,
    IF(MIN(first_order_at) + interval '180' day < NOW(), AVG(day_180_LTV), NULL) AS day_180_LTV,
    IF(MIN(first_order_at) + interval '365' day < NOW(), AVG(day_365_LTV), NULL) AS day_365_LTV,
    AVG(LTV) AS all_time_LTV,
    IF(MIN(first_order_at) + interval '30' day < NOW(), AVG(day_30_retention), NULL) AS day_30_retention,
    IF(MIN(first_order_at) + interval '90' day < NOW(), AVG(day_90_retention), NULL) AS day_90_retention,
    IF(MIN(first_order_at) + interval '180' day < NOW(), AVG(day_180_retention), NULL) AS day_180_retention,
    IF(MIN(first_order_at) + interval '365' day < NOW(), AVG(day_365_retention), NULL) AS day_365_retention,
    AVG(retention) AS all_time_retention,
    AVG(DATE_DIFF('day', first_order_timestamp, second_order_timestamp)) AS z_days_between_orders
FROM profile_entry_month
LEFT JOIN profile_stats USING(profile_id)
GROUP BY 1,2
HAVING COUNT(profile_id) >= 5
ORDER BY 1 ASC