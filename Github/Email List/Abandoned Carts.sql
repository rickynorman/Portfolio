/* Identifies emails of users who abandoned carts in the last 90 days but did not place an order during that period. */

WITH 

cart_abandoned_last_90_days AS (
    SELECT DISTINCT 
        profile_id
    FROM carts
    INNER JOIN sessions ON carts.id = sessions.cart_id AND carts.store_id = sessions.store_id
    WHERE carts.store_id = '7f0596f3-aa34-48ac-8411-7bb46355c4bf'
    AND carts.abandoned = true
    AND carts.last_interacted_at > NOW() - INTERVAL '90' DAY
),

placed_order_last_90_days AS (
    SELECT DISTINCT 
        profile_id
    FROM orders
    WHERE orders.store_id = '7f0596f3-aa34-48ac-8411-7bb46355c4bf'
    AND payment_status != 'CANCELED'
    AND placed_at > NOW() - INTERVAL '90' DAY
    AND profile_id IS NOT NULL
)

SELECT DISTINCT 
    email
FROM profiles
INNER JOIN cart_abandoned_last_90_days AS ac ON profiles.id = ac.profile_id
WHERE profiles.store_id = '7f0596f3-aa34-48ac-8411-7bb46355c4bf'
AND ac.profile_id NOT IN (SELECT profile_id FROM placed_order_last_90_days)