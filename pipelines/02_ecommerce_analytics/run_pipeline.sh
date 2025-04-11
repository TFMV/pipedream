#!/bin/bash
# Script to set up and run the e-commerce analytics pipeline

set -e  # Exit on any error

# Configuration - adjust as needed
RW_HOST="localhost"
RW_PORT="4566"
RW_DB="dev"
RW_USER="root"
RW_PSQL="psql -h $RW_HOST -p $RW_PORT -d $RW_DB -U $RW_USER"

echo "=== Setting up E-Commerce Analytics Pipeline ==="

# Check if RisingWave is running
echo "Checking RisingWave connection..."
if ! $RW_PSQL -c "SELECT version();" > /dev/null 2>&1; then
    echo "Error: Cannot connect to RisingWave. Please ensure it's running."
    exit 1
fi

echo "Connection successful!"

# Clean up existing objects if they exist
echo -e "\n=== Cleaning up existing objects ==="
$RW_PSQL <<EOF
DROP MATERIALIZED VIEW IF EXISTS anomaly_detection CASCADE;
DROP MATERIALIZED VIEW IF EXISTS product_performance CASCADE;
DROP MATERIALIZED VIEW IF EXISTS revenue_tracker CASCADE;
DROP MATERIALIZED VIEW IF EXISTS funnel_analysis CASCADE;
DROP MATERIALIZED VIEW IF EXISTS product_view_metrics CASCADE;
DROP MATERIALIZED VIEW IF EXISTS pageview_metrics CASCADE;
DROP MATERIALIZED VIEW IF EXISTS user_events_watermarked CASCADE;
DROP TABLE IF EXISTS user_events CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS products CASCADE;
EOF

# Create tables
echo -e "\n=== Creating tables and base watermarked view ==="
$RW_PSQL -f create_tables.sql

# Create views
echo -e "\n=== Creating materialized views ==="
$RW_PSQL -f create_views.sql

# Insert sample data
read -p "Do you want to insert sample test data? (y/n): " insert_data
if [[ $insert_data == "y" || $insert_data == "Y" ]]; then
    echo -e "\n=== Inserting sample data ==="
    $RW_PSQL -f insert_test_data.sql
fi

# Display sample queries to run
echo -e "\n=== Pipeline setup complete! ==="
echo "Here are some sample queries to try:"
echo ""
echo "Check overall conversion funnel metrics:"
echo "$RW_PSQL -c 'SELECT * FROM funnel_analysis;'"
echo ""
echo "View revenue in the last hour (sliding window):"
echo "$RW_PSQL -c 'SELECT * FROM revenue_tracker ORDER BY window_start DESC;'"
echo ""
echo "Check product performance metrics:"
echo "$RW_PSQL -c 'SELECT * FROM product_performance ORDER BY estimated_revenue DESC LIMIT 10;'"
echo ""
echo "Look for anomalies in purchase patterns:"
echo "$RW_PSQL -c 'SELECT * FROM anomaly_detection WHERE is_anomaly = TRUE;'" 