/*Finds emails of repeat sample sale buyers whose yearly spend exceeded $200 in both 2022 and 2023.*/

WITH sample_sale_buyers AS (
    SELECT 
        profile_id,
        YEAR(placed_at) AS order_year
    FROM production.orders
    CROSS JOIN UNNEST(CAST(JSON_PARSE(items) AS ARRAY<JSON>)) AS items(item)
    WHERE store_id = '3bbf36d0-6247-433a-8460-57ba5a249de5'
      AND payment_status != 'CANCELED'
      AND orders.source_name != 'pos'
      AND LOWER(JSON_EXTRACT_SCALAR(item, '$.title')) LIKE '%sample%'
      AND YEAR(placed_at) IN (2022, 2023)
),
buyers_with_both_years AS (
    SELECT profile_id
    FROM sample_sale_buyers
    GROUP BY profile_id
    HAVING COUNT(DISTINCT order_year) = 2
),
high_aov_profiles AS (
    SELECT DISTINCT profile_id
    FROM production.orders
    WHERE store_id = '3bbf36d0-6247-433a-8460-57ba5a249de5'
      AND payment_status != 'CANCELED'
      AND orders.source_name != 'pos'
      AND (total_price - total_shipping - total_refunded) > 200
)
SELECT DISTINCT profiles.email
FROM buyers_with_both_years
JOIN high_aov_profiles ON buyers_with_both_years.profile_id = high_aov_profiles.profile_id
JOIN production.profiles ON buyers_with_both_years.profile_id = profiles.id
WHERE profiles.store_id = '3bbf36d0-6247-433a-8460-57ba5a249de5'