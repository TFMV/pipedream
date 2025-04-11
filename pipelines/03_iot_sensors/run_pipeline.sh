#!/bin/bash
# Script to set up and run the IoT sensor network pipeline

set -e  # Exit on any error

# Configuration - adjust as needed
RW_HOST="localhost"
RW_PORT="4566"
RW_DB="dev"
RW_USER="root"
RW_PSQL="psql -h $RW_HOST -p $RW_PORT -d $RW_DB -U $RW_USER"

echo "=== Setting up IoT Sensor Network Pipeline ==="

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
DROP MATERIALIZED VIEW IF EXISTS geo_readings CASCADE;
DROP MATERIALIZED VIEW IF EXISTS maintenance_needed CASCADE;
DROP MATERIALIZED VIEW IF EXISTS temperature_anomalies CASCADE;
DROP MATERIALIZED VIEW IF EXISTS battery_level_trends CASCADE;
DROP MATERIALIZED VIEW IF EXISTS regional_temperature CASCADE;
DROP MATERIALIZED VIEW IF EXISTS hourly_temperature_stats CASCADE;
DROP MATERIALIZED VIEW IF EXISTS current_sensor_status CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sensor_readings_watermarked CASCADE;
DROP TABLE IF EXISTS alerts CASCADE;
DROP TABLE IF EXISTS maintenance_events CASCADE;
DROP TABLE IF EXISTS sensor_readings CASCADE;
DROP TABLE IF EXISTS sensors CASCADE;
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
echo "View current status of all sensors:"
echo "$RW_PSQL -c 'SELECT * FROM current_sensor_status;'"
echo ""
echo "Check for temperature anomalies:"
echo "$RW_PSQL -c 'SELECT * FROM temperature_anomalies WHERE is_anomaly = TRUE;'"
echo ""
echo "View sensors needing maintenance:"
echo "$RW_PSQL -c \"SELECT * FROM maintenance_needed WHERE maintenance_priority IN ('Immediate', 'Soon');\""
echo ""
echo "View regional temperature averages:"
echo "$RW_PSQL -c 'SELECT * FROM regional_temperature ORDER BY hour DESC, avg_temp DESC LIMIT 10;'" 