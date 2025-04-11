-- insert_test_data.sql
-- Sample data for testing the IoT sensor network pipeline

-- 1. Insert sensor metadata
INSERT INTO sensors (sensor_id, sensor_type, location_name, latitude, longitude, elevation, installation_date, manufacturer, model, firmware_version, battery_type, status) VALUES
('S001', 'Environmental', 'Downtown San Francisco', 37.7749, -122.4194, 52, NOW() - INTERVAL '180 days', 'SensorCorp', 'EnviroTrack Pro', 'v3.2.1', 'Lithium Ion', 'Active'),
('S002', 'Weather', 'Golden Gate Park', 37.7694, -122.4862, 64, NOW() - INTERVAL '240 days', 'WeatherTech', 'TempHumidPress-X1', 'v2.5.0', 'Solar', 'Active'),
('S003', 'Air Quality', 'Oakland Downtown', 37.8044, -122.2711, 43, NOW() - INTERVAL '120 days', 'AirSense', 'AQ-Monitor 3000', 'v1.9.5', 'Lithium Ion', 'Active'),
('S004', 'Environmental', 'San Jose City Center', 37.3382, -121.8863, 82, NOW() - INTERVAL '300 days', 'SensorCorp', 'EnviroTrack Pro', 'v3.1.0', 'Lithium Ion', 'Active'),
('S005', 'Weather', 'Berkeley Hills', 37.8715, -122.2730, 370, NOW() - INTERVAL '90 days', 'WeatherTech', 'TempHumidPress-X2', 'v3.0.0', 'Solar', 'Active'),
('S006', 'Air Quality', 'Palo Alto', 37.4419, -122.1430, 30, NOW() - INTERVAL '150 days', 'AirSense', 'AQ-Monitor 3000', 'v1.9.8', 'Lithium Ion', 'Active'),
('S007', 'Soil', 'Napa Valley', 38.5025, -122.2654, 240, NOW() - INTERVAL '200 days', 'AgriTech', 'SoilSense Pro', 'v2.1.3', 'Alkaline', 'Active'),
('S008', 'Water Quality', 'Lake Merritt', 37.8012, -122.2583, 5, NOW() - INTERVAL '260 days', 'AquaMonitor', 'H2OQual 500', 'v4.0.2', 'Lithium Ion', 'Active'),
('S009', 'Environmental', 'Treasure Island', 37.8235, -122.3706, 2, NOW() - INTERVAL '320 days', 'SensorCorp', 'EnviroTrack Lite', 'v2.0.1', 'Lithium Ion', 'Maintenance'),
('S010', 'Weather', 'Twin Peaks', 37.7544, -122.4477, 282, NOW() - INTERVAL '100 days', 'WeatherTech', 'TempHumidPress-X1', 'v2.5.2', 'Solar', 'Active');

-- 2. Insert temperature readings - last 24 hours, 4 readings per hour
-- Normal patterns for S001 - Downtown SF
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'TR' || (1000 + (hour_offset * 4) + reading_num)::text,
    'S001',
    'temperature',
    -- Temperature between 15-22C with daily cycle: cooler at night, warmer mid-day
    18 + 4 * SIN(PI() * (hour_offset % 24)::float / 12) + (0.25 * (hour_offset + reading_num) % 2 - 0.25),
    'C',
    -- Battery slowly decreasing from 95% to 90%
    95 - (hour_offset::float / 240 * 5),
    -- Signal strength between -50 and -60 dBm
    -50 - (hour_offset % 10 + 1),
    NOW() - INTERVAL '1 hour' * hour_offset - INTERVAL '15 minute' * reading_num,
    jsonb_build_object(
        'humidity', (65 + (5 * (hour_offset + reading_num) % 2)), 
        'pressure', (1010 + (2.5 * (hour_offset + reading_num) % 2))
    )
FROM 
    generate_series(0, 23) AS hour_offset,
    generate_series(0, 3) AS reading_num;

-- Normal patterns for S002 - Golden Gate Park (slightly cooler)
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'TR' || (2000 + (hour_offset * 4) + reading_num)::text,
    'S002',
    'temperature',
    -- Temperature between 14-20C
    17 + 3 * SIN(PI() * (hour_offset % 24)::float / 12) + (0.25 * (hour_offset + reading_num) % 2 - 0.25),
    'C',
    -- Solar battery: higher during day, lower at night
    70 + 20 * SIN(PI() * (hour_offset % 24)::float / 12),
    -- Signal strength between -60 and -70 dBm
    -60 - (hour_offset % 10 + 1),
    NOW() - INTERVAL '1 hour' * hour_offset - INTERVAL '15 minute' * reading_num,
    jsonb_build_object(
        'humidity', (70 + (5 * (hour_offset + reading_num) % 2)), 
        'pressure', (1008 + (2.5 * (hour_offset + reading_num) % 2))
    )
FROM 
    generate_series(0, 23) AS hour_offset,
    generate_series(0, 3) AS reading_num;

-- Anomaly pattern for S003 - Oakland (temperature spike)
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'TR' || (3000 + (hour_offset * 4) + reading_num)::text,
    'S003',
    'temperature',
    CASE
        -- Sudden temperature spike at hours 8-10
        WHEN hour_offset BETWEEN 8 AND 10 THEN 25 + (hour_offset + reading_num) % 2
        ELSE 19 + 3 * SIN(PI() * (hour_offset % 24)::float / 12) + (0.25 * (hour_offset + reading_num) % 2 - 0.25)
    END,
    'C',
    -- Battery level low and decreasing
    30 - (hour_offset::float / 24 * 5),
    -- Signal strength between -70 and -85 dBm
    -70 - (hour_offset % 15 + 1),
    NOW() - INTERVAL '1 hour' * hour_offset - INTERVAL '15 minute' * reading_num,
    jsonb_build_object(
        'humidity', (60 + (7.5 * (hour_offset + reading_num) % 2)), 
        'pressure', (1012 + (2.5 * (hour_offset + reading_num) % 2))
    )
FROM 
    generate_series(0, 23) AS hour_offset,
    generate_series(0, 3) AS reading_num;

-- Normal patterns for S004 - San Jose (warmer)
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'TR' || (4000 + (hour_offset * 4) + reading_num)::text,
    'S004',
    'temperature',
    -- Temperature between 18-26C
    22 + 4 * SIN(PI() * (hour_offset % 24)::float / 12) + (0.25 * (hour_offset + reading_num) % 2 - 0.25),
    'C',
    -- Battery stable around 82%
    82 + ((hour_offset + reading_num) % 2 - 1),
    -- Signal strength between -55 and -65 dBm
    -55 - (hour_offset % 10 + 1),
    NOW() - INTERVAL '1 hour' * hour_offset - INTERVAL '15 minute' * reading_num,
    jsonb_build_object(
        'humidity', (50 + (5 * (hour_offset + reading_num) % 2)), 
        'pressure', (1009 + (2.5 * (hour_offset + reading_num) % 2))
    )
FROM 
    generate_series(0, 23) AS hour_offset,
    generate_series(0, 3) AS reading_num;

-- Normal patterns for S005 - Berkeley Hills (more variable)
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'TR' || (5000 + (hour_offset * 4) + reading_num)::text,
    'S005',
    'temperature',
    -- Temperature between 12-23C (wider range)
    17.5 + 5.5 * SIN(PI() * (hour_offset % 24)::float / 12) + (0.5 * (hour_offset + reading_num) % 2 - 0.5),
    'C',
    -- Solar battery: higher during day, lower at night
    75 + 20 * SIN(PI() * (hour_offset % 24)::float / 12),
    -- Signal strength between -65 and -75 dBm
    -65 - (hour_offset % 10 + 1),
    NOW() - INTERVAL '1 hour' * hour_offset - INTERVAL '15 minute' * reading_num,
    jsonb_build_object(
        'humidity', (60 + (7.5 * (hour_offset + reading_num) % 2)), 
        'pressure', (995 + (5 * (hour_offset + reading_num) % 2))
    )
FROM 
    generate_series(0, 23) AS hour_offset,
    generate_series(0, 3) AS reading_num;

-- 3. Insert humidity readings - last 24 hours, 4 readings per hour for first 3 sensors
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'HR' || (1000 + (hour_offset * 4) + reading_num)::text,
    'S00' || (sensor_num)::text,
    'humidity',
    -- Humidity between 60-80%, slightly inverse to temperature
    70 - 10 * SIN(PI() * (hour_offset % 24)::float / 12) + (2.5 * (hour_offset + reading_num) % 2 - 2.5),
    '%',
    -- Use same battery values as temperature readings
    CASE 
        WHEN sensor_num = 1 THEN 95 - (hour_offset::float / 240 * 5)
        WHEN sensor_num = 2 THEN 70 + 20 * SIN(PI() * (hour_offset % 24)::float / 12)
        WHEN sensor_num = 3 THEN 30 - (hour_offset::float / 24 * 5)
    END,
    -- Signal strength
    -50 - (10 * sensor_num * (hour_offset % 1 + 1))::int,
    NOW() - INTERVAL '1 hour' * hour_offset - INTERVAL '15 minute' * reading_num,
    jsonb_build_object(
        'temperature', CASE 
            WHEN sensor_num = 1 THEN (18 + 4 * SIN(PI() * (hour_offset % 24)::float / 12))
            WHEN sensor_num = 2 THEN (17 + 3 * SIN(PI() * (hour_offset % 24)::float / 12))
            WHEN sensor_num = 3 THEN CASE
                WHEN hour_offset BETWEEN 8 AND 10 THEN (25 + (hour_offset + reading_num) % 2)
                ELSE (19 + 3 * SIN(PI() * (hour_offset % 24)::float / 12))
            END
        END
    )
FROM 
    generate_series(0, 23) AS hour_offset,
    generate_series(0, 3) AS reading_num,
    generate_series(1, 3) AS sensor_num;

-- 4. Insert air quality readings for S003 and S006
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'AR' || (sensor_id_num * 1000 + (hour_offset * 4) + reading_num)::text,
    'S00' || sensor_id_num::text,
    'air_quality',
    -- AQI between 30-60, with a spike for S003 during the temperature anomaly
    CASE
        WHEN sensor_id_num = 3 AND hour_offset BETWEEN 8 AND 10 THEN 85 + (5 * (hour_offset + reading_num) % 2)
        ELSE 45 + 15 * SIN(PI() * (hour_offset % 24)::float / 12) + (2.5 * (hour_offset + reading_num) % 2 - 2.5)
    END,
    'AQI',
    -- Battery levels
    CASE 
        WHEN sensor_id_num = 3 THEN 30 - (hour_offset::float / 24 * 5)
        WHEN sensor_id_num = 6 THEN 65 - (hour_offset::float / 48 * 5)
    END,
    -- Signal strength
    -65 - (hour_offset % 15 + 1)::int,
    NOW() - INTERVAL '1 hour' * hour_offset - INTERVAL '15 minute' * reading_num,
    jsonb_build_object(
        'pm25', (12 + (4 * (hour_offset + reading_num) % 2)), 
        'pm10', (25 + (7.5 * (hour_offset + reading_num) % 2)), 
        'o3', (0.03 + (0.01 * (hour_offset + reading_num) % 2)), 
        'no2', (0.02 + (0.0075 * (hour_offset + reading_num) % 2))
    )
FROM 
    generate_series(0, 23) AS hour_offset,
    generate_series(0, 3) AS reading_num,
    generate_series(3, 6, 3) AS sensor_id_num;

-- 5. Insert soil moisture and pH readings for S007
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'SM' || (1000 + hour_offset)::text,
    'S007',
    'soil_moisture',
    -- Soil moisture 25-35%
    30 + (2.5 * (hour_offset % 2) - 2.5),
    '%',
    -- Battery decreasing from 60%
    60 - (hour_offset::float / 24 * 3),
    -- Signal strength
    -72 - (hour_offset % 8 + 1)::int,
    NOW() - INTERVAL '1 hour' * hour_offset,
    jsonb_build_object(
        'depth', 10, 
        'temperature', (15 + (1.5 * (hour_offset % 2)))
    )
FROM 
    generate_series(0, 23) AS hour_offset;

INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'SP' || (1000 + hour_offset)::text,
    'S007',
    'soil_ph',
    -- pH slightly acidic, 6.2-6.8
    6.5 + (0.15 * (hour_offset % 2) - 0.15),
    'pH',
    -- Battery decreasing from 60% (same as moisture sensor)
    60 - (hour_offset::float / 24 * 3),
    -- Signal strength
    -72 - (hour_offset % 8 + 1)::int,
    NOW() - INTERVAL '1 hour' * hour_offset,
    jsonb_build_object(
        'depth', 10, 
        'moisture', (30 + (2.5 * (hour_offset % 2) - 2.5))
    )
FROM 
    generate_series(0, 23) AS hour_offset;

-- 6. Insert water quality readings for S008
INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'WT' || (1000 + hour_offset)::text,
    'S008',
    'water_temperature',
    -- Water temperature 16-18°C
    17 + (0.5 * (hour_offset % 2) - 0.5),
    'C',
    -- Battery stable around 75%
    75 + ((hour_offset % 2) - 1),
    -- Signal strength
    -68 - (hour_offset % 7 + 1)::int,
    NOW() - INTERVAL '1 hour' * hour_offset,
    jsonb_build_object('depth', 0.5)
FROM 
    generate_series(0, 23) AS hour_offset;

INSERT INTO sensor_readings (reading_id, sensor_id, reading_type, reading_value, reading_unit, battery_level, signal_strength, reading_time, reading_data)
SELECT 
    'WD' || (1000 + hour_offset)::text,
    'S008',
    'dissolved_oxygen',
    -- Dissolved oxygen 7-9 mg/L
    8 + (0.5 * (hour_offset % 2) - 0.5),
    'mg/L',
    -- Battery stable around 75%
    75 + ((hour_offset % 2) - 1),
    -- Signal strength
    -68 - (hour_offset % 7 + 1)::int,
    NOW() - INTERVAL '1 hour' * hour_offset,
    jsonb_build_object(
        'temperature', (17 + (0.5 * (hour_offset % 2) - 0.5)), 
        'depth', 0.5
    )
FROM 
    generate_series(0, 23) AS hour_offset;

-- 7. Insert maintenance events
INSERT INTO maintenance_events (event_id, sensor_id, event_type, technician_id, event_time, notes) VALUES
('M001', 'S003', 'battery_replacement', 'T001', NOW() - INTERVAL '60 days', 'Routine battery replacement'),
('M002', 'S007', 'calibration', 'T002', NOW() - INTERVAL '45 days', 'Calibrated soil moisture and pH sensors'),
('M003', 'S009', 'repair', 'T001', NOW() - INTERVAL '5 days', 'Fixed loose connection, replaced weatherproofing'),
('M004', 'S001', 'firmware_update', 'T003', NOW() - INTERVAL '30 days', 'Updated to firmware v3.2.1'),
('M005', 'S005', 'cleaning', 'T002', NOW() - INTERVAL '20 days', 'Cleaned solar panel and sensor housing');

-- 8. Insert alerts
INSERT INTO alerts (alert_id, sensor_id, alert_type, severity, alert_time, resolved_time, is_resolved, notes) VALUES
('A001', 'S003', 'low_battery', 'warning', NOW() - INTERVAL '2 days', NULL, FALSE, 'Battery level below 30%'),
('A002', 'S009', 'connection_lost', 'critical', NOW() - INTERVAL '6 days', NOW() - INTERVAL '5 days', TRUE, 'No data received for over 24 hours'),
('A003', 'S003', 'high_temperature', 'warning', NOW() - INTERVAL '10 hours', NOW() - INTERVAL '7 hours', TRUE, 'Temperature spike detected'),
('A004', 'S003', 'high_aqi', 'warning', NOW() - INTERVAL '9 hours', NULL, FALSE, 'Air quality index exceeding 80'),
('A005', 'S007', 'low_battery', 'info', NOW() - INTERVAL '1 day', NULL, FALSE, 'Battery level below 60%, schedule replacement'); 