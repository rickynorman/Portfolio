/* Tracks which products are purchased in customers’ first and second orders, plus value metrics and time between orders. */

WITH
client AS (
    SELECT
        id AS store_id, name
    FROM stores
    WHERE name  = 'Sample Store'
),

order_ranks AS (
    SELECT
        id,
        RANK() OVER (PARTITION BY profile_id ORDER BY placed_at ASC) AS rank
    FROM orders
    INNER JOIN client USING(store_id)
    WHERE total_price > 0
    AND payment_status = 'PAID'
    AND source_name NOT LIKE '%exchange%'
    AND source_name NOT IN ('pos', '1662707')
),

first_order_items AS (
    SELECT
        profile_id,
        JSON_EXTRACT_SCALAR(item, '$.title') AS skus_in_first_order,
        placed_at,
        total_price - total_refunded - total_tax AS total_price
    FROM orders
    INNER JOIN client USING(store_id)
    CROSS JOIN UNNEST(CAST(JSON_PARSE(items) AS ARRAY<JSON>)) AS items(item)
    INNER JOIN order_ranks USING(id)
    WHERE rank = 1
),

second_order_items AS (
    SELECT
        profile_id,
        JSON_EXTRACT_SCALAR(item, '$.title') AS skus_in_second_order,
        placed_at,
        total_price - total_refunded - total_tax AS total_price
    FROM orders
    INNER JOIN client USING(store_id)
    CROSS JOIN UNNEST(CAST(JSON_PARSE(items) AS ARRAY<JSON>)) AS items(item)
    INNER JOIN order_ranks USING(id)
    WHERE rank = 2
),

profile_stats AS (
    SELECT
        profile_id,
        SUM(total_price - total_refunded - total_tax) AS LTV
    FROM orders
    GROUP BY profile_id
)

SELECT
    skus_in_first_order,
    skus_in_second_order,
    COUNT(*) AS customer_count,
    AVG(first_order_items.total_price) AS first_order_value,
    AVG(second_order_items.total_price) AS second_order_value,
    AVG(LTV) AS average_ltv,
    AVG(DATE_DIFF('day', first_order_items.placed_at, second_order_items.placed_at)) AS average_between_orders
FROM first_order_items
INNER JOIN second_order_items USING(profile_id)
LEFT JOIN profile_stats USING(profile_id)
WHERE first_order_items.placed_at > NOW() - interval '12' month
GROUP BY 1, 2
ORDER BY 3 DESC