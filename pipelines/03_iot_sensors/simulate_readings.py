#!/usr/bin/env python3
"""
IoT Sensor Readings Simulator

This script simulates a continuous stream of IoT sensor readings by inserting
random but realistic data for various sensor types. It's useful for testing
the RisingWave pipeline with streaming data.
"""

import psycopg2
import time
import random
import json
import math
from datetime import datetime, timedelta

# Connection parameters
CONN_PARAMS = {
    "host": "localhost",  # Change as needed
    "port": 4566,  # RisingWave default port
    "dbname": "dev",
    "user": "root",  # Default RisingWave user
    "password": "",  # Default has no password
}

# Sensor types and their respective reading types
SENSOR_TYPES = {
    "S001": {"type": "Environmental", "readings": ["temperature", "humidity"]},
    "S002": {"type": "Weather", "readings": ["temperature", "humidity", "pressure"]},
    "S003": {
        "type": "Air Quality",
        "readings": ["temperature", "humidity", "air_quality"],
    },
    "S004": {"type": "Environmental", "readings": ["temperature", "humidity"]},
    "S005": {
        "type": "Weather",
        "readings": ["temperature", "humidity", "pressure", "wind_speed"],
    },
    "S006": {
        "type": "Air Quality",
        "readings": ["temperature", "humidity", "air_quality"],
    },
    "S007": {
        "type": "Soil",
        "readings": ["soil_moisture", "soil_ph", "soil_temperature"],
    },
    "S008": {
        "type": "Water Quality",
        "readings": ["water_temperature", "dissolved_oxygen", "ph", "turbidity"],
    },
    "S009": {"type": "Environmental", "readings": ["temperature", "humidity"]},
    "S010": {
        "type": "Weather",
        "readings": ["temperature", "humidity", "pressure", "wind_speed"],
    },
}

# Keep track of battery levels and ensure they decrease over time
SENSOR_BATTERY = {
    "S001": 90.0,
    "S002": 85.0,
    "S003": 25.0,
    "S004": 80.0,
    "S005": 95.0,
    "S006": 60.0,
    "S007": 55.0,
    "S008": 73.0,
    "S009": 45.0,
    "S010": 88.0,
}

# Baseline values for each reading type (for realistic data)
BASELINE_VALUES = {
    "temperature": {
        "S001": 18,
        "S002": 17,
        "S003": 19,
        "S004": 22,
        "S005": 17.5,
        "S006": 20,
        "S007": 16,
        "S008": 17,
        "S009": 18.5,
        "S010": 16.5,
    },
    "humidity": {
        "S001": 65,
        "S002": 70,
        "S003": 60,
        "S004": 50,
        "S005": 65,
        "S006": 55,
        "S007": 75,
        "S008": 85,
        "S009": 60,
        "S010": 68,
    },
    "pressure": {"S002": 1010, "S005": 995, "S010": 1005},
    "air_quality": {"S003": 45, "S006": 50},
    "soil_moisture": {"S007": 30},
    "soil_ph": {"S007": 6.5},
    "soil_temperature": {"S007": 15},
    "water_temperature": {"S008": 17},
    "dissolved_oxygen": {"S008": 8},
    "ph": {"S008": 7.2},
    "turbidity": {"S008": 5},
    "wind_speed": {"S005": 8, "S010": 5},
}

# Units for each reading type
READING_UNITS = {
    "temperature": "C",
    "humidity": "%",
    "pressure": "hPa",
    "air_quality": "AQI",
    "soil_moisture": "%",
    "soil_ph": "pH",
    "soil_temperature": "C",
    "water_temperature": "C",
    "dissolved_oxygen": "mg/L",
    "ph": "pH",
    "turbidity": "NTU",
    "wind_speed": "m/s",
}

# Reading ID starting points for each sensor
READING_ID_COUNTERS = {
    "S001": 10000,
    "S002": 20000,
    "S003": 30000,
    "S004": 40000,
    "S005": 50000,
    "S006": 60000,
    "S007": 70000,
    "S008": 80000,
    "S009": 90000,
    "S010": 100000,
}


def get_time_of_day_factor():
    """Returns a factor based on time of day (for simulating daily cycles)"""
    now = datetime.now()
    hour = now.hour
    # Sine wave with period of 24 hours, peak at noon, trough at midnight
    return math.sin(math.pi * hour / 12)


def get_reading_value(sensor_id, reading_type):
    """Generate a realistic reading value based on sensor and reading type"""
    baseline = BASELINE_VALUES.get(reading_type, {}).get(sensor_id, 0)
    time_factor = get_time_of_day_factor()

    # Different variation factors for different reading types
    if reading_type == "temperature":
        # Temperature varies with time of day
        variation = 4 * time_factor + (random.random() * 0.6 - 0.3)
        # S003 has occasional anomalies
        if sensor_id == "S003" and random.random() < 0.05:
            variation += 8  # Anomaly spike

    elif reading_type == "humidity":
        # Humidity tends to be inversely related to temperature
        variation = -10 * time_factor + (random.random() * 5 - 2.5)

    elif reading_type == "pressure":
        # Pressure changes more slowly
        variation = random.random() * 6 - 3

    elif reading_type == "air_quality":
        # AQI can spike during certain times
        variation = 10 * time_factor + (random.random() * 8 - 4)
        # S003 has occasional anomalies
        if sensor_id == "S003" and random.random() < 0.05:
            variation += 30  # Anomaly spike

    elif reading_type == "soil_moisture":
        # Soil moisture changes slowly
        variation = random.random() * 5 - 2.5

    elif reading_type == "soil_ph":
        # pH is very stable
        variation = random.random() * 0.3 - 0.15

    elif reading_type == "soil_temperature":
        # Soil temp varies with time but less than air temp
        variation = 2 * time_factor + (random.random() * 0.4 - 0.2)

    elif reading_type == "water_temperature":
        # Water temp varies even less
        variation = 1 * time_factor + (random.random() * 0.4 - 0.2)

    elif reading_type == "dissolved_oxygen":
        # Dissolved O2 can vary with temperature
        variation = -0.5 * time_factor + (random.random() * 0.6 - 0.3)

    elif reading_type == "ph":
        # pH is stable
        variation = random.random() * 0.4 - 0.2

    elif reading_type == "turbidity":
        # Turbidity can vary more
        variation = random.random() * 2 - 1

    elif reading_type == "wind_speed":
        # Wind speed can vary a lot
        variation = 3 * time_factor + (random.random() * 4 - 2)

    else:
        variation = random.random() * 2 - 1

    return baseline + variation


def get_battery_level(sensor_id):
    """Update and return the battery level for a sensor"""
    global SENSOR_BATTERY

    # Battery behavior depends on sensor type
    if sensor_id in ["S002", "S005", "S010"]:  # Solar-powered sensors
        time_factor = get_time_of_day_factor()
        # Battery charges during day, drains at night
        change = 0.1 * time_factor  # Small change
        SENSOR_BATTERY[sensor_id] = min(100, max(1, SENSOR_BATTERY[sensor_id] + change))
    else:
        # Regular batteries just drain slowly
        SENSOR_BATTERY[sensor_id] = max(
            1, SENSOR_BATTERY[sensor_id] - random.uniform(0.01, 0.05)
        )

    return SENSOR_BATTERY[sensor_id]


def get_signal_strength(sensor_id):
    """Generate a realistic signal strength value"""
    # Base signal strengths for different sensors
    base_strengths = {
        "S001": -55,
        "S002": -65,
        "S003": -75,
        "S004": -60,
        "S005": -70,
        "S006": -65,
        "S007": -72,
        "S008": -68,
        "S009": -80,
        "S010": -62,
    }

    base = base_strengths.get(sensor_id, -70)
    # Add random variation
    variation = random.randint(-5, 5)

    return base + variation


def generate_additional_data(sensor_id, reading_type):
    """Generate additional data in JSON format based on reading type"""
    data = {}

    if reading_type == "temperature":
        if "humidity" in SENSOR_TYPES[sensor_id]["readings"]:
            data["humidity"] = BASELINE_VALUES.get("humidity", {}).get(
                sensor_id, 60
            ) + (random.random() * 10 - 5)
        if "pressure" in SENSOR_TYPES[sensor_id]["readings"]:
            data["pressure"] = BASELINE_VALUES.get("pressure", {}).get(
                sensor_id, 1010
            ) + (random.random() * 5 - 2.5)

    elif reading_type == "humidity":
        if "temperature" in SENSOR_TYPES[sensor_id]["readings"]:
            data["temperature"] = BASELINE_VALUES.get("temperature", {}).get(
                sensor_id, 20
            ) + (random.random() * 2 - 1)

    elif reading_type == "air_quality":
        data["pm25"] = 12 + (random.random() * 8)
        data["pm10"] = 25 + (random.random() * 15)
        data["o3"] = 0.03 + (random.random() * 0.02)
        data["no2"] = 0.02 + (random.random() * 0.015)

    elif reading_type == "soil_moisture":
        data["depth"] = 10
        data["temperature"] = BASELINE_VALUES.get("soil_temperature", {}).get(
            sensor_id, 15
        ) + (random.random() * 2 - 1)

    elif reading_type == "soil_ph":
        data["depth"] = 10
        data["moisture"] = BASELINE_VALUES.get("soil_moisture", {}).get(
            sensor_id, 30
        ) + (random.random() * 5 - 2.5)

    elif reading_type == "water_temperature":
        data["depth"] = 0.5

    elif reading_type == "dissolved_oxygen":
        data["temperature"] = BASELINE_VALUES.get("water_temperature", {}).get(
            sensor_id, 17
        ) + (random.random() * 1 - 0.5)
        data["depth"] = 0.5

    elif reading_type == "pressure":
        data["altitude"] = random.randint(0, 400)

    elif reading_type == "wind_speed":
        data["direction"] = random.randint(0, 359)

    return json.dumps(data)


def simulate_sensor_readings(interval=5.0, limit=None, verbose=True):
    """
    Simulate IoT sensor readings with realistic data patterns.

    Args:
        interval: Time in seconds between readings
        limit: Optional limit to number of readings (None for infinite)
        verbose: Whether to print reading details
    """
    try:
        conn = psycopg2.connect(**CONN_PARAMS)
        cursor = conn.cursor()

        count = 0

        print(f"Starting IoT sensor readings simulation (interval: {interval}s)")
        print("Press Ctrl+C to stop")

        while limit is None or count < limit:
            # Select a random sensor
            sensor_id = random.choice(list(SENSOR_TYPES.keys()))

            # Select a random reading type for this sensor
            reading_type = random.choice(SENSOR_TYPES[sensor_id]["readings"])

            # Generate a unique reading ID
            reading_id = f"{reading_type[0].upper()}{READING_ID_COUNTERS[sensor_id]}"
            READING_ID_COUNTERS[sensor_id] += 1

            # Generate the reading values
            reading_value = get_reading_value(sensor_id, reading_type)
            reading_unit = READING_UNITS.get(reading_type, "")
            battery_level = get_battery_level(sensor_id)
            signal_strength = get_signal_strength(sensor_id)
            reading_time = datetime.now()
            reading_data = generate_additional_data(sensor_id, reading_type)

            # Insert the reading
            cursor.execute(
                """
                INSERT INTO sensor_readings 
                (reading_id, sensor_id, reading_type, reading_value, reading_unit, 
                 battery_level, signal_strength, reading_time, reading_data)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    reading_id,
                    sensor_id,
                    reading_type,
                    reading_value,
                    reading_unit,
                    battery_level,
                    signal_strength,
                    reading_time,
                    reading_data,
                ),
            )
            conn.commit()

            # Check for conditions that might trigger alerts
            if battery_level < 20 and random.random() < 0.3:
                # Create a low battery alert
                alert_id = f"A{1000 + count}"
                cursor.execute(
                    """
                    INSERT INTO alerts
                    (alert_id, sensor_id, alert_type, severity, alert_time, is_resolved, notes)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        alert_id,
                        sensor_id,
                        "low_battery",
                        "warning",
                        reading_time,
                        False,
                        f"Battery level below 20% ({battery_level:.1f}%)",
                    ),
                )
                conn.commit()
                if verbose:
                    print(
                        f"[{reading_time.strftime('%H:%M:%S')}] ALERT: Low battery for {sensor_id} ({battery_level:.1f}%)"
                    )

            if (
                reading_type == "temperature"
                and reading_value > BASELINE_VALUES["temperature"][sensor_id] + 8
                and random.random() < 0.5
            ):
                # Create a high temperature alert
                alert_id = f"A{2000 + count}"
                cursor.execute(
                    """
                    INSERT INTO alerts
                    (alert_id, sensor_id, alert_type, severity, alert_time, is_resolved, notes)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        alert_id,
                        sensor_id,
                        "high_temperature",
                        "warning",
                        reading_time,
                        False,
                        f"Temperature spike detected: {reading_value:.1f}°C",
                    ),
                )
                conn.commit()
                if verbose:
                    print(
                        f"[{reading_time.strftime('%H:%M:%S')}] ALERT: Temperature spike for {sensor_id} ({reading_value:.1f}°C)"
                    )

            # Create random maintenance event (very rarely)
            if random.random() < 0.01:
                event_id = f"M{1000 + count}"
                event_types = [
                    "battery_replacement",
                    "calibration",
                    "cleaning",
                    "firmware_update",
                ]
                event_type = random.choice(event_types)
                technician_id = f"T{random.randint(1, 5):03d}"
                notes = f"Scheduled {event_type}"

                cursor.execute(
                    """
                    INSERT INTO maintenance_events
                    (event_id, sensor_id, event_type, technician_id, event_time, notes)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (
                        event_id,
                        sensor_id,
                        event_type,
                        technician_id,
                        reading_time,
                        notes,
                    ),
                )
                conn.commit()

                # Reset battery level if it was a battery replacement
                if event_type == "battery_replacement":
                    SENSOR_BATTERY[sensor_id] = random.uniform(90, 100)

                if verbose:
                    print(
                        f"[{reading_time.strftime('%H:%M:%S')}] MAINTENANCE: {event_type} for {sensor_id}"
                    )

            # Print feedback
            count += 1
            if verbose:
                print(
                    f"[{reading_time.strftime('%H:%M:%S')}] Inserted {reading_type} reading for {sensor_id}: {reading_value:.2f} {reading_unit} (Battery: {battery_level:.1f}%)"
                )

            # Wait for the specified interval
            time.sleep(interval)

    except KeyboardInterrupt:
        print("\nSensor simulation stopped manually")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if "conn" in locals():
            conn.close()
            print("Connection closed")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Simulate a stream of IoT sensor readings"
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=5.0,
        help="Time in seconds between readings (default: 5.0)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit the number of readings to insert (default: unlimited)",
    )
    parser.add_argument("--quiet", action="store_true", help="Reduce output verbosity")

    args = parser.parse_args()

    simulate_sensor_readings(
        interval=args.interval, limit=args.limit, verbose=not args.quiet
    )
