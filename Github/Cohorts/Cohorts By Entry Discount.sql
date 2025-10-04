/* Groups customers by the discount received on their first order and tracks their lifetime value (LTV) over various time intervals up to one year. */

WITH
client AS (
    SELECT
        id AS store_id,
        name
    FROM stores
    WHERE name = 'Sample Store'
),

profile_entry_month AS (
    SELECT
        profile_id,
        MIN(placed_at) AS first_order_at,
        ARRAY_AGG(ROUND(total_discounts*10.00/total_price)*10 ORDER BY placed_at)[1] AS discount_amount
    FROM orders
    INNER JOIN client USING(store_id)
    WHERE total_price > 0
    AND payment_status = 'PAID'
    AND source_name NOT LIKE '%exchange%'
    AND source_name NOT IN ('pos', '1662707')
    GROUP BY profile_id
),

profile_stats AS (
    SELECT
        profile_id,
        SUM(total_price - total_tax - total_refunded) AS LTV,
        SUM(IF(placed_at < first_order_at + interval '30' day, total_price - total_tax - total_refunded, 0)) AS day_30_LTV,
        SUM(IF(placed_at < first_order_at + interval '60' day, total_price - total_tax - total_refunded, 0)) AS day_60_LTV,
        SUM(IF(placed_at < first_order_at + interval '90' day, total_price - total_tax - total_refunded, 0)) AS day_90_LTV,
        SUM(IF(placed_at < first_order_at + interval '120' day, total_price - total_tax - total_refunded, 0)) AS day_120_LTV,
        SUM(IF(placed_at < first_order_at + interval '150' day, total_price - total_tax - total_refunded, 0)) AS day_150_LTV,
        SUM(IF(placed_at < first_order_at + interval '180' day, total_price - total_tax - total_refunded, 0)) AS day_180_LTV,
        SUM(IF(placed_at < first_order_at + interval '210' day, total_price - total_tax - total_refunded, 0)) AS day_210_LTV,
        SUM(IF(placed_at < first_order_at + interval '240' day, total_price - total_tax - total_refunded, 0)) AS day_240_LTV,
        SUM(IF(placed_at < first_order_at + interval '270' day, total_price - total_tax - total_refunded, 0)) AS day_270_LTV,
        SUM(IF(placed_at < first_order_at + interval '300' day, total_price - total_tax - total_refunded, 0)) AS day_300_LTV,
        SUM(IF(placed_at < first_order_at + interval '330' day, total_price - total_tax - total_refunded, 0)) AS day_330_LTV,
        SUM(IF(placed_at < first_order_at + interval '365' day, total_price - total_tax - total_refunded, 0)) AS day_365_LTV
    FROM orders
    INNER JOIN client USING(store_id)
    LEFT JOIN profile_entry_month USING(profile_id)
    WHERE total_price > 0
    AND payment_status = 'PAID'
    AND source_name NOT LIKE '%exchange%'
    AND source_name NOT IN ('pos', '1662707')
    GROUP BY profile_id
)

SELECT
    IF(discount_amount > 100, 100, discount_amount) AS cohort, -- Discount amount rounded to the nearest 10%
    COUNT(profile_id) AS cohort_size,
    IF(MIN(first_order_at) + interval '30' day < NOW(), AVG(day_30_LTV), NULL) AS day_30_LTV,
    IF(MIN(first_order_at) + interval '60' day < NOW(), AVG(day_60_LTV), NULL) AS day_60_LTV,
    IF(MIN(first_order_at) + interval '90' day < NOW(), AVG(day_90_LTV), NULL) AS day_90_LTV,
    IF(MIN(first_order_at) + interval '120' day < NOW(), AVG(day_120_LTV), NULL) AS day_120_LTV,
    IF(MIN(first_order_at) + interval '150' day < NOW(), AVG(day_150_LTV), NULL) AS day_150_LTV,
    IF(MIN(first_order_at) + interval '180' day < NOW(), AVG(day_180_LTV), NULL) AS day_180_LTV,
    IF(MIN(first_order_at) + interval '210' day < NOW(), AVG(day_210_LTV), NULL) AS day_210_LTV,
    IF(MIN(first_order_at) + interval '240' day < NOW(), AVG(day_240_LTV), NULL) AS day_240_LTV,
    IF(MIN(first_order_at) + interval '270' day < NOW(), AVG(day_270_LTV), NULL) AS day_270_LTV,
    IF(MIN(first_order_at) + interval '300' day < NOW(), AVG(day_300_LTV), NULL) AS day_300_LTV,
    IF(MIN(first_order_at) + interval '330' day < NOW(), AVG(day_330_LTV), NULL) AS day_330_LTV,
    IF(MIN(first_order_at) + interval '365' day < NOW(), AVG(day_365_LTV), NULL) AS day_365_LTV,
    AVG(LTV) AS all_time_LTV
FROM profile_entry_month
LEFT JOIN profile_stats USING(profile_id)
GROUP BY 1
ORDER BY 1 ASC