-- create_views.sql
-- Creates the materialized views for IoT sensor analytics

-- 1. Current sensor status - latest reading from each sensor
CREATE MATERIALIZED VIEW current_sensor_status AS
SELECT DISTINCT ON (sensor_id)
    sr.sensor_id,
    s.sensor_type,
    s.location_name,
    s.latitude,
    s.longitude,
    sr.reading_type,
    sr.reading_value,
    sr.reading_unit,
    sr.battery_level,
    sr.signal_strength,
    sr.reading_time,
    s.status
FROM
    sensor_readings_watermarked sr
JOIN
    sensors s ON sr.sensor_id = s.sensor_id
ORDER BY
    sr.sensor_id, sr.reading_time DESC;

-- 2. Hourly temperature statistics
CREATE MATERIALIZED VIEW hourly_temperature_stats AS
SELECT
    sensor_id,
    DATE_TRUNC('hour', reading_time) AS hour,
    AVG(reading_value) AS avg_temp,
    MIN(reading_value) AS min_temp,
    MAX(reading_value) AS max_temp,
    COUNT(*) AS reading_count
FROM
    sensor_readings_watermarked
WHERE
    reading_type = 'temperature'
GROUP BY
    sensor_id, DATE_TRUNC('hour', reading_time);

-- 3. Regional temperature aggregation
CREATE MATERIALIZED VIEW regional_temperature AS
SELECT
    s.location_name,
    DATE_TRUNC('hour', sr.reading_time) AS hour,
    AVG(sr.reading_value) AS avg_temp
FROM
    sensor_readings_watermarked sr
JOIN
    sensors s ON sr.sensor_id = s.sensor_id
WHERE
    sr.reading_type = 'temperature'
GROUP BY
    s.location_name, DATE_TRUNC('hour', sr.reading_time);

-- 4. Battery level monitoring with sliding windows
CREATE MATERIALIZED VIEW battery_level_trends AS
SELECT
    window_start,
    window_end,
    sensor_id,
    AVG(battery_level) AS avg_battery,
    MIN(battery_level) AS min_battery,
    MAX(battery_level) AS max_battery,
    CASE
        WHEN MIN(battery_level) < 20 THEN 'Critical'
        WHEN MIN(battery_level) < 40 THEN 'Warning'
        ELSE 'Normal'
    END AS battery_status
FROM
    HOP(sensor_readings_watermarked, reading_time_watermark, INTERVAL '1 hour', INTERVAL '24 hours')
GROUP BY
    window_start, window_end, sensor_id;

-- 5. Anomaly detection for temperature readings
CREATE MATERIALIZED VIEW temperature_anomalies AS
WITH sensor_baselines AS (
    SELECT
        sensor_id,
        AVG(reading_value) OVER (
            PARTITION BY sensor_id
            ORDER BY reading_time
            ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
        ) AS avg_temp,
        MAX(reading_value) OVER (
            PARTITION BY sensor_id
            ORDER BY reading_time
            ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
        ) AS max_temp,
        MIN(reading_value) OVER (
            PARTITION BY sensor_id
            ORDER BY reading_time
            ROWS BETWEEN 24 PRECEDING AND 1 PRECEDING
        ) AS min_temp,
        reading_value AS current_temp,
        reading_time
    FROM
        sensor_readings_watermarked
    WHERE
        reading_type = 'temperature'
)
SELECT
    sensor_id,
    reading_time,
    current_temp,
    avg_temp,
    min_temp,
    max_temp,
    CASE
        WHEN avg_temp IS NULL THEN FALSE
        WHEN current_temp > avg_temp + 10 THEN TRUE
        WHEN current_temp < avg_temp - 10 THEN TRUE
        ELSE FALSE
    END AS is_anomaly,
    CASE
        WHEN current_temp > avg_temp + 10 THEN 'High temperature anomaly'
        WHEN current_temp < avg_temp - 10 THEN 'Low temperature anomaly'
        ELSE 'Normal'
    END AS anomaly_type
FROM
    sensor_baselines
WHERE
    avg_temp IS NOT NULL;

-- 6. Maintenance scheduling view
CREATE MATERIALIZED VIEW maintenance_needed AS
SELECT
    s.sensor_id,
    s.location_name,
    s.latitude,
    s.longitude,
    s.sensor_type,
    cs.battery_level,
    cs.signal_strength,
    cs.reading_time,
    CASE
        WHEN cs.battery_level < 20 THEN 'Immediate'
        WHEN cs.battery_level < 40 THEN 'Soon'
        WHEN cs.signal_strength < -90 THEN 'Soon'
        WHEN cs.reading_time > s.installation_date + INTERVAL '365 days' THEN 'Routine'
        ELSE 'Not needed'
    END AS maintenance_priority,
    CASE
        WHEN cs.battery_level < 40 THEN 'Battery replacement'
        WHEN cs.signal_strength < -90 THEN 'Signal check'
        WHEN cs.reading_time > s.installation_date + INTERVAL '365 days' THEN 'Annual inspection'
        ELSE NULL
    END AS maintenance_type,
    (SELECT MAX(event_time) FROM maintenance_events me WHERE me.sensor_id = s.sensor_id) AS last_maintenance
FROM
    sensors s
JOIN
    current_sensor_status cs ON s.sensor_id = cs.sensor_id;

-- 7. Sensor readings with geospatial context
CREATE MATERIALIZED VIEW geo_readings AS
SELECT
    sr.reading_id,
    sr.sensor_id,
    s.latitude,
    s.longitude,
    s.location_name,
    sr.reading_type,
    sr.reading_value,
    sr.reading_unit,
    sr.reading_time
FROM
    sensor_readings_watermarked sr
JOIN
    sensors s ON sr.sensor_id = s.sensor_id; 