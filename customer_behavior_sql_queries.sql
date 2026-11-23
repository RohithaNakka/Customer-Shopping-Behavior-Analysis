-- Customer Shopping Behaviour Analysis
select * from public.customer;
-- 1. Dataset and customer-record overview
SELECT
    COUNT(*) AS purchase_records,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount)::numeric, 2) AS average_purchase_amount,
    ROUND(AVG(review_rating)::numeric, 2) AS average_review_rating
FROM public.customer;

-- 2. Revenue and average purchase amount by gender
SELECT
    gender,
    COUNT(*) AS purchase_records,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount)::numeric, 2) AS average_purchase_amount
FROM public.customer
GROUP BY gender
ORDER BY total_revenue DESC;

-- 3. Discount users whose purchase amount is above the overall average
SELECT
    customer_id,
    purchase_amount,
    discount_applied
FROM public.customer
WHERE LOWER(discount_applied) = 'yes'
  AND purchase_amount > (
      SELECT AVG(purchase_amount)
      FROM public.customer
  )
ORDER BY purchase_amount DESC;

-- 4. Top five products by average review rating
SELECT
    item_purchased,
    ROUND(AVG(review_rating)::numeric, 2) AS average_review_rating,
    COUNT(*) AS review_count
FROM public.customer
GROUP BY item_purchased
ORDER BY average_review_rating DESC, review_count DESC
LIMIT 5;

-- 5. Compare average purchase amount for Standard and Express shipping
SELECT
    shipping_type,
    COUNT(*) AS purchase_records,
    ROUND(AVG(purchase_amount)::numeric, 2) AS average_purchase_amount
FROM public.customer
WHERE LOWER(shipping_type) IN ('standard', 'express')
GROUP BY shipping_type
ORDER BY average_purchase_amount DESC;

-- 6. Subscriber vs non-subscriber performance
SELECT
    subscription_status,
    COUNT(*) AS purchase_records,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount)::numeric, 2) AS average_purchase_amount,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS share_of_records_pct
FROM public.customer
GROUP BY subscription_status
ORDER BY total_revenue DESC;

-- 7. Five products with the highest percentage of discounted records
-- 100.0 ensures decimal arithmetic in PostgreSQL.
SELECT
    item_purchased,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (WHERE LOWER(discount_applied) = 'yes') AS discounted_records,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE LOWER(discount_applied) = 'yes')
        / NULLIF(COUNT(*), 0),
        2
    ) AS discount_utilization_pct
FROM public.customer
GROUP BY item_purchased
ORDER BY discount_utilization_pct DESC, total_records DESC
LIMIT 5;

-- 8. Purchase-history segments based on previous_purchases.
--  descriptive bands, not verified lifecycle/loyalty labels.
WITH segmented AS (
    SELECT
        customer_id,
        CASE
            WHEN previous_purchases BETWEEN 1 AND 10 THEN 'Low prior purchase count'
            WHEN previous_purchases BETWEEN 11 AND 25 THEN 'Medium prior purchase count'
            ELSE 'High prior purchase count'
        END AS purchase_history_segment
    FROM public.customer
)
SELECT
    purchase_history_segment,
    COUNT(*) AS customer_records
FROM segmented
GROUP BY purchase_history_segment
ORDER BY customer_records DESC;

-- 9. Top three products within each category by record count
WITH product_counts AS (
    SELECT
        category,
        item_purchased,
        COUNT(*) AS purchase_records,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY COUNT(*) DESC
        ) AS product_rank
    FROM public.customer
    GROUP BY category, item_purchased
)
SELECT
    category,
    item_purchased,
    purchase_records,
    product_rank
FROM product_counts
WHERE product_rank <= 3
ORDER BY category, product_rank, item_purchased;

-- 10. Compare subscription rates for lower vs higher prior-purchase counts
WITH repeat_groups AS (
    SELECT
        CASE
            WHEN previous_purchases > 5 THEN 'More than 5 prior purchases'
            ELSE '5 or fewer prior purchases'
        END AS prior_purchase_group,
        subscription_status
    FROM public.customer
)
SELECT
    prior_purchase_group,
    COUNT(*) AS customer_records,
    COUNT(*) FILTER (
        WHERE LOWER(subscription_status) = 'yes'
    ) AS subscribed_records,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE LOWER(subscription_status) = 'yes'
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS subscription_rate_pct
FROM repeat_groups
GROUP BY prior_purchase_group
ORDER BY prior_purchase_group;

-- 11. Revenue by age group
SELECT
    age_group,
    COUNT(*) AS purchase_records,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount)::numeric, 2) AS average_purchase_amount
FROM public.customer
GROUP BY age_group
ORDER BY total_revenue DESC;

-- 12. Revenue and average purchase amount by season
SELECT
    season,
    COUNT(*) AS purchase_records,
    SUM(purchase_amount) AS total_revenue,
    ROUND(AVG(purchase_amount)::numeric, 2) AS average_purchase_amount
FROM public.customer
GROUP BY season
ORDER BY total_revenue DESC;
