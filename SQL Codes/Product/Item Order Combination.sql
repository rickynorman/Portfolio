/*  Lists the most common product pairs bought together, with their purchase frequency and average order value. */

WITH
client AS (
    SELECT
        id AS store_id, name
    FROM stores
    WHERE name  = 'Sample Store'
),

applicable_orders AS (
    SELECT
        id,
        COMBINATIONS(
            ARRAY_DISTINCT(
                ARRAY_SORT(
                    TRANSFORM(
                        CAST(JSON_PARSE(items) AS ARRAY<JSON>),
                        item -> LOWER(JSON_EXTRACT_SCALAR(item, '$.title'))
                    )
                )
            ),
            2
        ) AS cart_item_pairs,
        total_price - total_tax - total_refunded AS order_value
    FROM orders
    INNER JOIN client USING(store_id)
    WHERE payment_status != 'CANCELED'
    AND placed_at > DATE '2023-08-15'
)

SELECT
    pair[1] AS product_A,
    pair[2] AS product_B,
    COUNT(id) AS frequency,
    AVG(order_value) AS AOV
FROM applicable_orders
CROSS JOIN UNNEST(cart_item_pairs) AS pairs(pair)
GROUP BY pair
ORDER BY 3 DESC
LIMIT 50