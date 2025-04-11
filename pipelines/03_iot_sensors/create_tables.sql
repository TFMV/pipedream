-- create_tables.sql
-- Creates the base tables for the IoT sensor network pipeline

-- 1. Sensor metadata table - reference data
CREATE TABLE sensors (
    sensor_id VARCHAR PRIMARY KEY,
    sensor_type VARCHAR,
    location_name VARCHAR,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    elevation DOUBLE PRECISION,
    installation_date TIMESTAMP,
    manufacturer VARCHAR,
    model VARCHAR,
    firmware_version VARCHAR,
    battery_type VARCHAR,
    status VARCHAR
);

-- 2. Sensor readings table - the main event stream
CREATE TABLE sensor_readings (
    reading_id VARCHAR PRIMARY KEY,
    sensor_id VARCHAR,
    reading_type VARCHAR,  -- temperature, humidity, pressure, air_quality, etc.
    reading_value DOUBLE PRECISION,
    reading_unit VARCHAR,  -- C, F, %, hPa, AQI, etc.
    battery_level DOUBLE PRECISION,
    signal_strength INT,
    reading_time TIMESTAMP,
    reading_data JSONB    -- additional reading-specific data
);

-- 3. Maintenance events table
CREATE TABLE maintenance_events (
    event_id VARCHAR PRIMARY KEY,
    sensor_id VARCHAR,
    event_type VARCHAR,  -- battery_replacement, calibration, repair, etc.
    technician_id VARCHAR,
    event_time TIMESTAMP,
    notes VARCHAR
);

-- 4. Alerts table
CREATE TABLE alerts (
    alert_id VARCHAR PRIMARY KEY,
    sensor_id VARCHAR,
    alert_type VARCHAR,  -- high_temp, low_battery, connection_lost, etc.
    severity VARCHAR,    -- info, warning, critical
    alert_time TIMESTAMP,
    resolved_time TIMESTAMP,
    is_resolved BOOLEAN,
    notes VARCHAR
);

-- 5. Create a watermarked view for sensor readings stream
CREATE MATERIALIZED VIEW sensor_readings_watermarked AS
SELECT 
    reading_id,
    sensor_id,
    reading_type,
    reading_value,
    reading_unit,
    battery_level,
    signal_strength,
    reading_time,
    reading_data,
    (reading_time - INTERVAL '1 minute') AS reading_time_watermark
FROM 
    sensor_readings; 