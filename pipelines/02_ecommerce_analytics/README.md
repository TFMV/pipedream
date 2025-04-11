# E-Commerce Real-Time Analytics Pipeline

A comprehensive RisingWave streaming pipeline that processes e-commerce user events in real-time, providing dashboards for product performance, conversion metrics, and anomaly detection.

## Pipeline Overview

This pipeline demonstrates a business-focused streaming application that would be valuable in a real-world e-commerce setting:

1. **Data Collection**: Tracks user events (pageviews, product views, cart actions, purchases)
2. **Real-Time Analytics**: Computes metrics including conversion rates, revenue, product performance
3. **Window Analysis**: Uses both sliding and tumbling windows to analyze trends over time
4. **Anomaly Detection**: Identifies unusual patterns in purchase behavior

## Components

### Base Tables

- `products` - Reference data for products (name, category, price, inventory)
- `users` - User demographic information
- `user_events` - Main event stream capturing all user interactions
- `user_events_watermarked` - Adds watermarks for handling late-arriving data

### Materialized Views

- `pageview_metrics` - Traffic statistics by page, device type, and referrer
- `product_view_metrics` - Product popularity tracking
- `funnel_analysis` - Conversion rates through the purchase funnel
- `revenue_tracker` - Sales tracking with sliding windows (5-min windows over a 1-hour period)
- `product_performance` - Comprehensive product metrics (views, cart additions, purchases)
- `anomaly_detection` - Z-score based anomaly detection for purchase patterns

## SQL Files

- `create_tables.sql` - Creates the base tables and watermarked view
- `create_views.sql` - Creates the materialized views for analytics
- `insert_test_data.sql` - Inserts sample data for testing

## Advanced Features Showcased

1. **JOIN Operations**: Combining streaming event data with reference product data
2. **Sliding Windows**: Using HOP windows for revenue tracking (vs. tumbling windows in Pipeline 01)
3. **Complex Aggregations**: Boolean aggregation for funnel stages and conditional counting
4. **Statistical Analysis**: Computing Z-scores for anomaly detection using window functions
5. **JSONB Support**: Using JSON fields for flexible event data storage

## Usage

### Setup

1. Start your RisingWave instance
2. Create the pipeline components:

```bash
# Create the base tables and watermarked view
psql -h localhost -p 4566 -d dev -f create_tables.sql

# Create the materialized views
psql -h localhost -p 4566 -d dev -f create_views.sql
```

### Testing

```bash
# Insert test data
psql -h localhost -p 4566 -d dev -f insert_test_data.sql
```

### Querying Results

```sql
-- Check overall conversion funnel metrics
SELECT * FROM funnel_analysis;

-- View revenue in the last hour (sliding window)
SELECT * FROM revenue_tracker ORDER BY window_start DESC;

-- Check product performance metrics
SELECT * FROM product_performance ORDER BY estimated_revenue DESC LIMIT 10;

-- Look for anomalies in purchase patterns
SELECT * FROM anomaly_detection WHERE is_anomaly = TRUE;
```

## Business Value

This pipeline provides real-time insights that transform e-commerce operations:

- **Marketing Teams**: Track conversion rates and campaign performance in real-time
- **Inventory Management**: Monitor product popularity and sales velocity
- **Customer Experience**: Identify and resolve funnel drop-off points quickly
- **Revenue Optimization**: Detect purchasing anomalies that might indicate problems or opportunities
- **Executive Dashboards**: Provide up-to-the-minute business performance metrics

## Technical Notes

- The pipeline uses a 2-minute watermark to account for network delays and late-arriving events
- Sliding windows in the revenue tracker allow for trend analysis with overlapping time periods
- The anomaly detection uses a 24-hour lookback period for establishing normal patterns
