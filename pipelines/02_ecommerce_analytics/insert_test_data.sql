-- insert_test_data.sql
-- Sample data for testing the e-commerce analytics pipeline

-- 1. Insert product data
INSERT INTO products (product_id, name, category, price, inventory_count, created_at, is_active) VALUES
('P001', 'Premium Wireless Headphones', 'Electronics', 129.99, 500, NOW() - INTERVAL '30 days', TRUE),
('P002', 'Smartphone Fast Charger', 'Electronics', 24.99, 1000, NOW() - INTERVAL '60 days', TRUE),
('P003', 'Ultra HD Smart TV 55"', 'Electronics', 699.99, 200, NOW() - INTERVAL '90 days', TRUE),
('P004', 'Memory Foam Pillow', 'Home & Kitchen', 39.99, 800, NOW() - INTERVAL '45 days', TRUE),
('P005', 'Stainless Steel Water Bottle', 'Sports & Outdoors', 19.99, 1500, NOW() - INTERVAL '75 days', TRUE),
('P006', 'Organic Cotton T-Shirt', 'Clothing', 29.99, 1200, NOW() - INTERVAL '15 days', TRUE),
('P007', 'Bluetooth Smart Speaker', 'Electronics', 89.99, 600, NOW() - INTERVAL '20 days', TRUE),
('P008', 'Ergonomic Office Chair', 'Furniture', 199.99, 300, NOW() - INTERVAL '40 days', TRUE),
('P009', 'Fitness Tracker Watch', 'Electronics', 79.99, 750, NOW() - INTERVAL '25 days', TRUE),
('P010', 'Cast Iron Skillet', 'Home & Kitchen', 34.99, 400, NOW() - INTERVAL '35 days', TRUE);

-- 2. Insert user data
INSERT INTO users (user_id, email, country, city, device_type, created_at, last_login) VALUES
('U001', 'john.doe@example.com', 'United States', 'New York', 'mobile', NOW() - INTERVAL '100 days', NOW() - INTERVAL '1 day'),
('U002', 'jane.smith@example.com', 'United Kingdom', 'London', 'desktop', NOW() - INTERVAL '90 days', NOW() - INTERVAL '2 days'),
('U003', 'michael.brown@example.com', 'Canada', 'Toronto', 'tablet', NOW() - INTERVAL '80 days', NOW() - INTERVAL '5 hours'),
('U004', 'emily.jones@example.com', 'Australia', 'Sydney', 'mobile', NOW() - INTERVAL '70 days', NOW() - INTERVAL '12 hours'),
('U005', 'david.wilson@example.com', 'United States', 'Los Angeles', 'desktop', NOW() - INTERVAL '60 days', NOW() - INTERVAL '3 days'),
('U006', 'sarah.lee@example.com', 'United States', 'Chicago', 'mobile', NOW() - INTERVAL '50 days', NOW() - INTERVAL '1 hour'),
('U007', 'james.taylor@example.com', 'United Kingdom', 'Manchester', 'desktop', NOW() - INTERVAL '40 days', NOW() - INTERVAL '6 hours'),
('U008', 'olivia.martin@example.com', 'Canada', 'Vancouver', 'tablet', NOW() - INTERVAL '30 days', NOW() - INTERVAL '2 days'),
('U009', 'william.anderson@example.com', 'Australia', 'Melbourne', 'mobile', NOW() - INTERVAL '20 days', NOW() - INTERVAL '4 hours'),
('U010', 'sophia.garcia@example.com', 'United States', 'Miami', 'desktop', NOW() - INTERVAL '10 days', NOW() - INTERVAL '30 minutes');

-- 3. Insert event data - Session 1: Complete purchase flow for User 1
INSERT INTO user_events (event_id, user_id, session_id, event_type, product_id, page_url, referrer_url, device_type, event_time, event_data) VALUES
('E001', 'U001', 'S001', 'pageview', NULL, 'https://example.com/home', 'https://google.com', 'mobile', NOW() - INTERVAL '60 minutes', '{"scroll_depth": 80}'),
('E002', 'U001', 'S001', 'pageview', NULL, 'https://example.com/products', 'https://example.com/home', 'mobile', NOW() - INTERVAL '58 minutes', '{"scroll_depth": 65}'),
('E003', 'U001', 'S001', 'product_view', 'P001', 'https://example.com/products/P001', 'https://example.com/products', 'mobile', NOW() - INTERVAL '55 minutes', '{"view_duration": 45}'),
('E004', 'U001', 'S001', 'add_to_cart', 'P001', 'https://example.com/products/P001', NULL, 'mobile', NOW() - INTERVAL '52 minutes', '{"quantity": 1}'),
('E005', 'U001', 'S001', 'product_view', 'P005', 'https://example.com/products/P005', 'https://example.com/products', 'mobile', NOW() - INTERVAL '50 minutes', '{"view_duration": 30}'),
('E006', 'U001', 'S001', 'add_to_cart', 'P005', 'https://example.com/products/P005', NULL, 'mobile', NOW() - INTERVAL '48 minutes', '{"quantity": 1}'),
('E007', 'U001', 'S001', 'pageview', NULL, 'https://example.com/cart', 'https://example.com/products/P005', 'mobile', NOW() - INTERVAL '45 minutes', '{}'),
('E008', 'U001', 'S001', 'checkout', NULL, 'https://example.com/checkout', 'https://example.com/cart', 'mobile', NOW() - INTERVAL '42 minutes', '{"cart_value": 149.98, "item_count": 2}'),
('E009', 'U001', 'S001', 'purchase', NULL, 'https://example.com/order-confirmation', 'https://example.com/checkout', 'mobile', NOW() - INTERVAL '40 minutes', '{"order_id": "ORD001", "total_amount": 149.98, "item_count": 2, "payment_method": "credit_card"}');

-- Session 2: User browses but doesn't purchase
INSERT INTO user_events (event_id, user_id, session_id, event_type, product_id, page_url, referrer_url, device_type, event_time, event_data) VALUES
('E010', 'U002', 'S002', 'pageview', NULL, 'https://example.com/home', 'https://bing.com', 'desktop', NOW() - INTERVAL '55 minutes', '{"scroll_depth": 60}'),
('E011', 'U002', 'S002', 'pageview', NULL, 'https://example.com/products', 'https://example.com/home', 'desktop', NOW() - INTERVAL '53 minutes', '{"scroll_depth": 70}'),
('E012', 'U002', 'S002', 'product_view', 'P003', 'https://example.com/products/P003', 'https://example.com/products', 'desktop', NOW() - INTERVAL '51 minutes', '{"view_duration": 60}'),
('E013', 'U002', 'S002', 'product_view', 'P008', 'https://example.com/products/P008', 'https://example.com/products', 'desktop', NOW() - INTERVAL '48 minutes', '{"view_duration": 45}'),
('E014', 'U002', 'S002', 'product_view', 'P010', 'https://example.com/products/P010', 'https://example.com/products', 'desktop', NOW() - INTERVAL '45 minutes', '{"view_duration": 30}');

-- Session 3: User adds to cart but abandons
INSERT INTO user_events (event_id, user_id, session_id, event_type, product_id, page_url, referrer_url, device_type, event_time, event_data) VALUES
('E015', 'U003', 'S003', 'pageview', NULL, 'https://example.com/home', 'https://facebook.com', 'tablet', NOW() - INTERVAL '50 minutes', '{"scroll_depth": 40}'),
('E016', 'U003', 'S003', 'pageview', NULL, 'https://example.com/products', 'https://example.com/home', 'tablet', NOW() - INTERVAL '48 minutes', '{"scroll_depth": 85}'),
('E017', 'U003', 'S003', 'product_view', 'P007', 'https://example.com/products/P007', 'https://example.com/products', 'tablet', NOW() - INTERVAL '46 minutes', '{"view_duration": 75}'),
('E018', 'U003', 'S003', 'add_to_cart', 'P007', 'https://example.com/products/P007', NULL, 'tablet', NOW() - INTERVAL '44 minutes', '{"quantity": 1}'),
('E019', 'U003', 'S003', 'pageview', NULL, 'https://example.com/cart', 'https://example.com/products/P007', 'tablet', NOW() - INTERVAL '42 minutes', '{}');

-- Session 4: Complete purchase with multiple items
INSERT INTO user_events (event_id, user_id, session_id, event_type, product_id, page_url, referrer_url, device_type, event_time, event_data) VALUES
('E020', 'U004', 'S004', 'pageview', NULL, 'https://example.com/home', 'https://instagram.com', 'mobile', NOW() - INTERVAL '45 minutes', '{"scroll_depth": 90}'),
('E021', 'U004', 'S004', 'pageview', NULL, 'https://example.com/products', 'https://example.com/home', 'mobile', NOW() - INTERVAL '43 minutes', '{"scroll_depth": 75}'),
('E022', 'U004', 'S004', 'product_view', 'P006', 'https://example.com/products/P006', 'https://example.com/products', 'mobile', NOW() - INTERVAL '41 minutes', '{"view_duration": 30}'),
('E023', 'U004', 'S004', 'add_to_cart', 'P006', 'https://example.com/products/P006', NULL, 'mobile', NOW() - INTERVAL '40 minutes', '{"quantity": 2}'),
('E024', 'U004', 'S004', 'product_view', 'P009', 'https://example.com/products/P009', 'https://example.com/products', 'mobile', NOW() - INTERVAL '38 minutes', '{"view_duration": 90}'),
('E025', 'U004', 'S004', 'add_to_cart', 'P009', 'https://example.com/products/P009', NULL, 'mobile', NOW() - INTERVAL '36 minutes', '{"quantity": 1}'),
('E026', 'U004', 'S004', 'product_view', 'P002', 'https://example.com/products/P002', 'https://example.com/products', 'mobile', NOW() - INTERVAL '34 minutes', '{"view_duration": 20}'),
('E027', 'U004', 'S004', 'add_to_cart', 'P002', 'https://example.com/products/P002', NULL, 'mobile', NOW() - INTERVAL '33 minutes', '{"quantity": 1}'),
('E028', 'U004', 'S004', 'pageview', NULL, 'https://example.com/cart', 'https://example.com/products/P002', 'mobile', NOW() - INTERVAL '31 minutes', '{}'),
('E029', 'U004', 'S004', 'checkout', NULL, 'https://example.com/checkout', 'https://example.com/cart', 'mobile', NOW() - INTERVAL '28 minutes', '{"cart_value": 164.96, "item_count": 4}'),
('E030', 'U004', 'S004', 'purchase', NULL, 'https://example.com/order-confirmation', 'https://example.com/checkout', 'mobile', NOW() - INTERVAL '25 minutes', '{"order_id": "ORD002", "total_amount": 164.96, "item_count": 4, "payment_method": "paypal"}');

-- Session 5: Quick purchase of a single item
INSERT INTO user_events (event_id, user_id, session_id, event_type, product_id, page_url, referrer_url, device_type, event_time, event_data) VALUES
('E031', 'U005', 'S005', 'pageview', NULL, 'https://example.com/products', 'https://twitter.com', 'desktop', NOW() - INTERVAL '40 minutes', '{"scroll_depth": 60}'),
('E032', 'U005', 'S005', 'product_view', 'P004', 'https://example.com/products/P004', 'https://example.com/products', 'desktop', NOW() - INTERVAL '38 minutes', '{"view_duration": 45}'),
('E033', 'U005', 'S005', 'add_to_cart', 'P004', 'https://example.com/products/P004', NULL, 'desktop', NOW() - INTERVAL '37 minutes', '{"quantity": 2}'),
('E034', 'U005', 'S005', 'pageview', NULL, 'https://example.com/cart', 'https://example.com/products/P004', 'desktop', NOW() - INTERVAL '36 minutes', '{}'),
('E035', 'U005', 'S005', 'checkout', NULL, 'https://example.com/checkout', 'https://example.com/cart', 'desktop', NOW() - INTERVAL '35 minutes', '{"cart_value": 79.98, "item_count": 2}'),
('E036', 'U005', 'S005', 'purchase', NULL, 'https://example.com/order-confirmation', 'https://example.com/checkout', 'desktop', NOW() - INTERVAL '33 minutes', '{"order_id": "ORD003", "total_amount": 79.98, "item_count": 2, "payment_method": "credit_card"}');

-- Insert more recent events for testing time windows
INSERT INTO user_events (event_id, user_id, session_id, event_type, product_id, page_url, referrer_url, device_type, event_time, event_data) VALUES
('E037', 'U006', 'S006', 'pageview', NULL, 'https://example.com/home', 'https://google.com', 'mobile', NOW() - INTERVAL '15 minutes', '{"scroll_depth": 70}'),
('E038', 'U006', 'S006', 'product_view', 'P001', 'https://example.com/products/P001', 'https://example.com/home', 'mobile', NOW() - INTERVAL '14 minutes', '{"view_duration": 60}'),
('E039', 'U006', 'S006', 'add_to_cart', 'P001', 'https://example.com/products/P001', NULL, 'mobile', NOW() - INTERVAL '13 minutes', '{"quantity": 1}'),
('E040', 'U006', 'S006', 'checkout', NULL, 'https://example.com/checkout', 'https://example.com/cart', 'mobile', NOW() - INTERVAL '11 minutes', '{"cart_value": 129.99, "item_count": 1}'),
('E041', 'U006', 'S006', 'purchase', NULL, 'https://example.com/order-confirmation', 'https://example.com/checkout', 'mobile', NOW() - INTERVAL '10 minutes', '{"order_id": "ORD004", "total_amount": 129.99, "item_count": 1, "payment_method": "credit_card"}'),
('E042', 'U007', 'S007', 'pageview', NULL, 'https://example.com/home', 'https://bing.com', 'desktop', NOW() - INTERVAL '8 minutes', '{"scroll_depth": 50}'),
('E043', 'U007', 'S007', 'product_view', 'P003', 'https://example.com/products/P003', 'https://example.com/home', 'desktop', NOW() - INTERVAL '7 minutes', '{"view_duration": 90}'),
('E044', 'U007', 'S007', 'add_to_cart', 'P003', 'https://example.com/products/P003', NULL, 'desktop', NOW() - INTERVAL '6 minutes', '{"quantity": 1}'),
('E045', 'U007', 'S007', 'checkout', NULL, 'https://example.com/checkout', 'https://example.com/cart', 'desktop', NOW() - INTERVAL '4 minutes', '{"cart_value": 699.99, "item_count": 1}'),
('E046', 'U007', 'S007', 'purchase', NULL, 'https://example.com/order-confirmation', 'https://example.com/checkout', 'desktop', NOW() - INTERVAL '3 minutes', '{"order_id": "ORD005", "total_amount": 699.99, "item_count": 1, "payment_method": "paypal"}'); 