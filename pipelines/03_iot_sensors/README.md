# IoT Sensor Network Pipeline

A sophisticated RisingWave streaming pipeline for processing and analyzing IoT sensor data with geospatial context, demonstrating real-time monitoring, anomaly detection, and predictive maintenance.

## Pipeline Overview

This pipeline demonstrates a comprehensive IoT monitoring solution that would be valuable for smart cities, environmental monitoring, or industrial applications:

1. **Data Collection**: Captures readings from diverse sensor types (environmental, weather, air quality, soil, water)
2. **Real-Time Monitoring**: Tracks current conditions across geographical locations
3. **Anomaly Detection**: Identifies unusual patterns in temperature and other readings
4. **Maintenance Planning**: Proactively schedules sensor maintenance based on battery levels and signal strength

## Components

### Base Tables

- `sensors` - Metadata about sensor devices including location coordinates, type, and status
- `sensor_readings` - Time-series data from various sensor types with reading value and unit
- `maintenance_events` - Records of maintenance activities performed on sensors
- `alerts` - System alerts for anomalous conditions or maintenance needs

### Materialized Views

- `current_sensor_status` - Latest reading from each sensor
- `hourly_temperature_stats` - Temperature statistics aggregated hourly
- `regional_temperature` - Temperature averages by geographic region
- `battery_level_trends` - Battery level monitoring with sliding windows
- `temperature_anomalies` - Anomaly detection for temperature readings
- `maintenance_needed` - Predictive maintenance scheduling
- `geo_readings` - Sensor readings with geospatial context

## SQL Files

- `create_tables.sql` - Creates the base tables and watermarked view
- `create_views.sql` - Creates the materialized views for analytics
- `insert_test_data.sql` - Inserts sample data for testing

## Advanced Features Showcased

1. **Geospatial Analysis**: Working with latitude/longitude data for region-based analysis
2. **Time-Series Processing**: Analyzing trends and patterns in time-series sensor data
3. **Anomaly Detection**: Identifying outliers based on historical patterns
4. **Predictive Maintenance**: Scheduling proactive maintenance based on sensor readings
5. **Diverse Data Types**: Handling multiple sensor types and measurements in a unified pipeline
6. **JSON Processing**: Using JSONB for flexible sensor data storage

## Sample Data

The pipeline includes test data for:

- 10 sensors across the San Francisco Bay Area, including San Francisco, Oakland, Berkeley, San Jose, and Napa Valley
- 24 hours of readings with 15-minute intervals (4 readings per hour)
- Multiple sensor types: temperature, humidity, air quality, soil moisture, water quality
- Normal daily patterns and simulated anomalies
- Historical maintenance records and active alerts

## Usage

### Setup

1. Start your RisingWave instance
2. Create the pipeline components:

```bash
# Create the base tables
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
-- View current status of all sensors
SELECT * FROM current_sensor_status;

-- Check for temperature anomalies
SELECT * FROM temperature_anomalies WHERE is_anomaly = TRUE;

-- View sensors needing maintenance
SELECT * FROM maintenance_needed WHERE maintenance_priority IN ('Immediate', 'Soon');

-- View regional temperature averages
SELECT * FROM regional_temperature 
ORDER BY hour DESC, avg_temp DESC 
LIMIT 10;
```

## Business Applications

This pipeline provides real-time insights for various use cases:

- **Environmental Monitoring**: Track temperature, humidity, and air quality across urban areas
- **Smart Agriculture**: Monitor soil conditions in vineyards or farms
- **Water Quality Management**: Monitor lake and reservoir conditions
- **Urban Planning**: Correlate environmental factors with urban features
- **Maintenance Operations**: Optimize field technician schedules and routes
- **Emergency Response**: Detect rapid changes in environmental conditions that may indicate emergencies

## Technical Notes

- The pipeline uses a 1-minute watermark to handle late-arriving data
- Anomaly detection uses a 24-hour lookback window for establishing normal patterns
- The maintenance scheduling algorithm considers battery level, signal strength, and time since last maintenance
