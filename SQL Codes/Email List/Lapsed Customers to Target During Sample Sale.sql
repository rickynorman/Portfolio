/*Selects emails of customers with recent site visits but no purchases in the last six months.*/

WITH recent_pageviews AS (
    SELECT DISTINCT 
        sessions.profile_id
    FROM production.events
    JOIN production.sessions ON events.session_id = sessions.id
        AND events.store_id = sessions.store_id
    WHERE events.store_id = '3bbf36d0-6247-433a-8460-57ba5a249de5'
        AND events.type = 'page_view'
        AND events.event_time >= CURRENT_TIMESTAMP - INTERVAL '3' MONTH
),
recent_orders AS (
    SELECT DISTINCT 
        profile_id
    FROM production.orders
    WHERE store_id = '3bbf36d0-6247-433a-8460-57ba5a249de5'
        AND payment_status != 'CANCELED'
        AND orders.source_name != 'pos'
        AND placed_at >= CURRENT_TIMESTAMP - INTERVAL '6' MONTH
)
SELECT DISTINCT 
    profiles.email
FROM recent_pageviews
LEFT JOIN recent_orders  ON recent_pageviews.profile_id = recent_orders.profile_id
JOIN production.profiles  ON recent_pageviews.profile_id = profiles.id 
    AND profiles.store_id = '3bbf36d0-6247-433a-8460-57ba5a249de5'