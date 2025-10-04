/* Finds products with high page views but low purchases, highlighting those needing conversion improvement. */

WITH

product_traffic AS (
    SELECT
        product_id,
        COUNT(events.id) AS view_frequency
    FROM production.events
    WHERE events.type = 'page_view'
    AND event_time > NOW() - interval '60' day
    AND product_id IS NOT NULL
    AND store_id = '6f853ba1-dabd-4fe7-8e66-1964fd59af86'
    GROUP BY 1
),

product_purchases AS (
    SELECT
        JSON_EXTRACT_SCALAR(item, '$.product_id') AS product_id,
        COUNT(id) AS purchase_frequency
    FROM production.orders
    CROSS JOIN UNNEST(CAST(JSON_PARSE(items) AS ARRAY<JSON>)) AS items(item)
    WHERE placed_at > NOW() - interval '60' day
    AND store_id = '6f853ba1-dabd-4fe7-8e66-1964fd59af86'
    GROUP BY 1
)

SELECT
    title,
    SUM(view_frequency) AS view_frequency,
    SUM(purchase_frequency) AS purchase_frequency,
    SUM(view_frequency) * 1.00 / SUM(purchase_frequency) AS views_required_for_a_purchase,
    SUM(purchase_frequency) * 1.00 / SUM(view_frequency) AS product_specific_conversion_rate
FROM product_traffic
FULL OUTER JOIN product_purchases USING(product_id)
LEFT JOIN (
    SELECT
        product_id,
        ARRAY_AGG(title ORDER BY freq DESC)[1] AS title
    FROM (
        SELECT
            product_id,
            product_title AS title,
            COUNT(*) AS freq
        FROM production.products
        WHERE store_id = '6f853ba1-dabd-4fe7-8e66-1964fd59af86'
        GROUP BY 1, 2
    )
    WHERE product_id IS NOT NULL
    GROUP BY product_id
) USING(product_id)
WHERE title IS NOT NULL AND view_frequency IS NOT NULL AND purchase_frequency IS NOT NULL
AND (view_frequency * 1.00 / purchase_frequency) > 1
GROUP BY 1
ORDER BY 4 DESC
LIMIT 2000