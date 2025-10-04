/* Tracks customers acquired each year and analyzes their order revenue by year, showing cohort growth and revenue trends over time. */

WITH profile_orders AS (
SELECT
profile_id,
placed_at,
total_price - total_refunded AS revenue
FROM orders
WHERE store_id = '6c7412d0-6791-4db0-bcae-5293111ee3b8'
),

profile_cohorts AS (
SELECT
profile_id,
MIN(placed_at AT TIME ZONE 'America/New_York') AS first_order_date,
MIN(DATE_TRUNC('year', placed_at AT TIME ZONE 'America/New_York')) AS first_order_year
FROM production.orders
WHERE store_id = '6c7412d0-6791-4db0-bcae-5293111ee3b8'
GROUP BY 1
)

SELECT
YEAR(first_order_year) AS cohort,
YEAR(first_order_year) + DATE_DIFF('year', first_order_year, placed_at) AS order_year,
COUNT(DISTINCT profile_id) AS customers_acquired,
SUM(revenue) AS revenue
FROM profile_cohorts
LEFT JOIN profile_orders USING(profile_id)
WHERE first_order_year >= TIMESTAMP '2018-01-01 00:00 America/New_York'
GROUP BY 1, 2
ORDER BY 1, 2