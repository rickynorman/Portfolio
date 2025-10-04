/*Identifies emails of customers who bought three or more sample sale items in a single order.*/

SELECT DISTINCT profiles.email
FROM production.orders
INNER JOIN production.profiles ON orders.profile_id = profiles.id 
    AND orders.store_id = profiles.store_id
CROSS JOIN UNNEST(CAST(JSON_PARSE(orders.items) AS ARRAY<JSON>)) AS items(item)
WHERE orders.store_id = '3bbf36d0-6247-433a-8460-57ba5a249de5'
  AND orders.payment_status != 'CANCELED'
  AND LOWER(JSON_EXTRACT_SCALAR(item, '$.title')) LIKE '%sample%'
  AND orders.source_name != 'pos'
GROUP BY orders.id, profiles.email
HAVING COUNT(*) >= 3