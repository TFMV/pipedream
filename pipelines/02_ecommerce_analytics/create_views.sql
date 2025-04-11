-- create_views.sql
-- Creates the materialized views for e-commerce analytics

-- 1. Page view metrics - track traffic by page, device, and referrer
CREATE MATERIALIZED VIEW pageview_metrics AS
SELECT
    page_url,
    device_type,
    referrer_url,
    COUNT(*) AS view_count,
    COUNT(DISTINCT user_id) AS unique_visitors,
    COUNT(DISTINCT session_id) AS session_count,
    MIN(event_time) AS first_view,
    MAX(event_time) AS last_view
FROM
    user_events_watermarked
WHERE
    event_type = 'pageview'
GROUP BY
    page_url, device_type, referrer_url;

-- 2. Product view metrics - track product popularity
CREATE MATERIALIZED VIEW product_view_metrics AS
SELECT
    p.product_id,
    p.name,
    p.category,
    p.price,
    COUNT(*) AS view_count,
    COUNT(DISTINCT u.user_id) AS unique_viewers,
    COUNT(DISTINCT u.session_id) AS session_count
FROM
    user_events_watermarked u
JOIN
    products p ON u.product_id = p.product_id
WHERE
    u.event_type = 'product_view'
GROUP BY
    p.product_id, p.name, p.category, p.price;

-- 3. Funnel analysis - track conversion through the purchase funnel
CREATE MATERIALIZED VIEW funnel_analysis AS
WITH funnel_stages AS (
    SELECT
        session_id,
        bool_or(event_type = 'pageview') AS reached_pageview,
        bool_or(event_type = 'product_view') AS reached_product_view,
        bool_or(event_type = 'add_to_cart') AS reached_add_to_cart,
        bool_or(event_type = 'checkout') AS reached_checkout,
        bool_or(event_type = 'purchase') AS reached_purchase
    FROM
        user_events_watermarked
    GROUP BY
        session_id
)
SELECT
    COUNT(*) AS total_sessions,
    SUM(CASE WHEN reached_pageview THEN 1 ELSE 0 END) AS pageview_count,
    SUM(CASE WHEN reached_product_view THEN 1 ELSE 0 END) AS product_view_count,
    SUM(CASE WHEN reached_add_to_cart THEN 1 ELSE 0 END) AS add_to_cart_count,
    SUM(CASE WHEN reached_checkout THEN 1 ELSE 0 END) AS checkout_count,
    SUM(CASE WHEN reached_purchase THEN 1 ELSE 0 END) AS purchase_count,
    CAST(SUM(CASE WHEN reached_product_view THEN 1 ELSE 0 END) AS FLOAT) / 
        NULLIF(SUM(CASE WHEN reached_pageview THEN 1 ELSE 0 END), 0) AS pageview_to_product_view_rate,
    CAST(SUM(CASE WHEN reached_add_to_cart THEN 1 ELSE 0 END) AS FLOAT) / 
        NULLIF(SUM(CASE WHEN reached_product_view THEN 1 ELSE 0 END), 0) AS product_view_to_cart_rate,
    CAST(SUM(CASE WHEN reached_checkout THEN 1 ELSE 0 END) AS FLOAT) / 
        NULLIF(SUM(CASE WHEN reached_add_to_cart THEN 1 ELSE 0 END), 0) AS cart_to_checkout_rate,
    CAST(SUM(CASE WHEN reached_purchase THEN 1 ELSE 0 END) AS FLOAT) / 
        NULLIF(SUM(CASE WHEN reached_checkout THEN 1 ELSE 0 END), 0) AS checkout_to_purchase_rate,
    CAST(SUM(CASE WHEN reached_purchase THEN 1 ELSE 0 END) AS FLOAT) / 
        NULLIF(SUM(CASE WHEN reached_pageview THEN 1 ELSE 0 END), 0) AS overall_conversion_rate
FROM
    funnel_stages;

-- 4. Revenue tracker - track revenue in sliding windows
CREATE MATERIALIZED VIEW revenue_tracker AS
SELECT
    window_start,
    window_end,
    COUNT(DISTINCT event_id) AS purchase_count,
    COUNT(DISTINCT user_id) AS unique_customers,
    SUM(CAST(event_data->>'total_amount' AS DOUBLE PRECISION)) AS total_revenue,
    SUM(CAST(event_data->>'item_count' AS INT)) AS items_sold
FROM
    HOP(user_events_watermarked, event_time_watermark, INTERVAL '5 minute', INTERVAL '1 hour') 
WHERE
    event_type = 'purchase'
GROUP BY
    window_start, window_end;

-- 5. Product performance - best and worst selling products
CREATE MATERIALIZED VIEW product_performance AS
SELECT
    p.product_id,
    p.name,
    p.category,
    p.price,
    COUNT(CASE WHEN u.event_type = 'product_view' THEN 1 ELSE NULL END) AS view_count,
    COUNT(CASE WHEN u.event_type = 'add_to_cart' THEN 1 ELSE NULL END) AS cart_adds,
    COUNT(CASE WHEN u.event_type = 'purchase' THEN 1 ELSE NULL END) AS purchases,
    CASE 
        WHEN COUNT(CASE WHEN u.event_type = 'product_view' THEN 1 ELSE NULL END) = 0 THEN 0
        ELSE CAST(COUNT(CASE WHEN u.event_type = 'add_to_cart' THEN 1 ELSE NULL END) AS FLOAT) / 
             COUNT(CASE WHEN u.event_type = 'product_view' THEN 1 ELSE NULL END)
    END AS view_to_cart_ratio,
    CASE 
        WHEN COUNT(CASE WHEN u.event_type = 'add_to_cart' THEN 1 ELSE NULL END) = 0 THEN 0
        ELSE CAST(COUNT(CASE WHEN u.event_type = 'purchase' THEN 1 ELSE NULL END) AS FLOAT) / 
             COUNT(CASE WHEN u.event_type = 'add_to_cart' THEN 1 ELSE NULL END)
    END AS cart_to_purchase_ratio,
    COUNT(CASE WHEN u.event_type = 'purchase' THEN 1 ELSE NULL END) * p.price AS estimated_revenue
FROM
    products p
LEFT JOIN
    user_events_watermarked u ON p.product_id = u.product_id
GROUP BY
    p.product_id, p.name, p.category, p.price;

-- 6. Simplified anomaly detection - detect unusual changes in purchase patterns
-- Using a simpler approach without STDDEV since it's not supported
CREATE MATERIALIZED VIEW anomaly_detection AS
WITH hourly_metrics AS (
    SELECT
        DATE_TRUNC('hour', event_time) AS hour,
        COUNT(*) AS event_count
    FROM
        user_events_watermarked
    WHERE
        event_type = 'purchase'
    GROUP BY
        DATE_TRUNC('hour', event_time)
),
hourly_stats AS (
    SELECT
        hour,
        event_count,
        AVG(event_count) OVER (
            PARTITION BY 1
            ORDER BY hour
            ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
        ) AS avg_count,
        MAX(event_count) OVER (
            PARTITION BY 1
            ORDER BY hour
            ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
        ) AS max_count,
        MIN(event_count) OVER (
            PARTITION BY 1
            ORDER BY hour
            ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
        ) AS min_count
    FROM
        hourly_metrics
)
SELECT
    hour,
    event_count,
    avg_count,
    max_count,
    min_count,
    (event_count - avg_count) / NULLIF(GREATEST(1, (max_count - min_count) / 2), 0) AS deviation_score,
    CASE 
        WHEN avg_count IS NULL THEN FALSE
        -- Consider 3x from average as an anomaly
        WHEN event_count > avg_count * 3 THEN TRUE
        WHEN event_count * 3 < avg_count THEN TRUE
        ELSE FALSE
    END AS is_anomaly
FROM
    hourly_stats
ORDER BY
    hour DESC; 