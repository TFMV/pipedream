-- create_tables.sql
-- Creates the base tables for the e-commerce analytics pipeline

-- 1. Products table - reference data
CREATE TABLE products (
    product_id VARCHAR PRIMARY KEY,
    name VARCHAR,
    category VARCHAR,
    price DOUBLE PRECISION,
    inventory_count INT,
    created_at TIMESTAMP,
    is_active BOOLEAN
);

-- 2. Users table - reference data
CREATE TABLE users (
    user_id VARCHAR PRIMARY KEY,
    email VARCHAR,
    country VARCHAR,
    city VARCHAR,
    device_type VARCHAR,
    created_at TIMESTAMP,
    last_login TIMESTAMP
);

-- 3. User events table - the main event stream
CREATE TABLE user_events (
    event_id VARCHAR PRIMARY KEY,
    user_id VARCHAR,
    session_id VARCHAR,
    event_type VARCHAR, -- pageview, product_view, add_to_cart, remove_from_cart, checkout, purchase
    product_id VARCHAR,
    page_url VARCHAR,
    referrer_url VARCHAR,
    device_type VARCHAR,
    event_time TIMESTAMP,
    event_data JSONB -- additional event-specific data
);

-- 4. Create a watermarked view for the event stream
CREATE MATERIALIZED VIEW user_events_watermarked AS
SELECT 
    event_id,
    user_id,
    session_id,
    event_type,
    product_id,
    page_url,
    referrer_url,
    device_type,
    event_time,
    event_data,
    (event_time - INTERVAL '2 minutes') AS event_time_watermark
FROM 
    user_events; 