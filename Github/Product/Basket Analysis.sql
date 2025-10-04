/* Analyzes product and variant combinations in orders, showing their frequency, new customer share, and average order value. */

WITH
client AS (
    SELECT
        id AS store_id, name
    FROM stores
    WHERE name  = 'Sample Store'
),

product_table AS (
    SELECT
        sku,
        ARRAY_AGG(product_title ORDER BY updated_at DESC)[1] AS product,
        ARRAY_AGG(variant_title ORDER BY updated_at DESC)[1] AS variant
    FROM products
    INNER JOIN client USING(store_id)
    GROUP BY sku
),

order_items AS (
    SELECT
        id,
        profile_id,
        product,
        IF(variant = 'Default Title' OR variant IS NULL, '', variant) AS variant
    FROM orders
    INNER JOIN client USING(store_id)
    CROSS JOIN UNNEST(CAST(JSON_PARSE(items) AS ARRAY<JSON>)) AS items(item)
    LEFT JOIN product_table ON LOWER(JSON_EXTRACT_SCALAR(item, '$.sku')) = LOWER(sku)
    WHERE total_price > 0
    AND payment_status = 'PAID'
    AND source_name NOT LIKE '%exchange%'
    AND source_name NOT IN ('pos', '1662707')
    AND placed_at > NOW() - interval '1' year
    AND product IS NOT NULL
    AND CAST(JSON_EXTRACT_SCALAR(item, '$.price') AS REAL) > 0.00
),

order_carts AS (
    SELECT
        id,
        profile_id,
        ARRAY_SORT(
            ARRAY_DISTINCT(
                ARRAY_AGG(
                    IF(
                        variant = '', 
                        product, 
                        CONCAT(product, ' - ', variant)
                    )
                )
            )
        ) AS product_variant_cart,
        ARRAY_SORT(ARRAY_DISTINCT(ARRAY_AGG(product))) AS product_cart,
        FILTER(ARRAY_SORT(ARRAY_DISTINCT(ARRAY_AGG(variant))), item -> item != '') AS variant_cart
    FROM order_items
    GROUP BY id, profile_id
),

order_stats AS (
    SELECT
        id,
        total_price - total_tax - total_refunded AS order_value,
        RANK() OVER (PARTITION BY profile_id ORDER BY placed_at ASC) AS order_rank
    FROM orders
    INNER JOIN client USING(store_id)
    WHERE total_price > 0
    AND payment_status = 'PAID'
    AND source_name NOT LIKE '%exchange%'
    AND source_name NOT IN ('pos', '1662707')
)

SELECT
    product_cart, -- this can be adjusted between product_variant_cart, product_cart, and variant_cart
    COUNT(*) AS order_count,
    SUM(IF(order_rank = 1, 1, 0)) * 1.00 / COUNT(*) AS new_order_pctg,
    AVG(order_value) AS AOV
FROM order_carts
LEFT JOIN order_stats USING(id)
GROUP BY 1
ORDER BY 2 DESC