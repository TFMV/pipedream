#!/usr/bin/env python3
"""
Sentence Stream Simulator

This script simulates a live stream of sentences by inserting data into the
sentence_source table at regular intervals. It's useful for testing the
RisingWave pipeline when not using the datagen connector.
"""

import psycopg2
import time
import random
from datetime import datetime

# Sample sentences to insert - add more for variety
SENTENCES = [
    "The quick brown fox jumps over the lazy dog.",
    "Stream processing enables real-time analytics and monitoring.",
    "RisingWave is a distributed SQL streaming database.",
    "Data in motion requires different processing paradigms than data at rest.",
    "Streaming analytics helps businesses respond to events in real time.",
    "Kafka is often used as a message broker for streaming applications.",
    "Window functions allow aggregation over specific time periods.",
    "Watermarks help manage late-arriving data in stream processing.",
    "Materialized views in streaming databases maintain up-to-date results.",
    "Continuous queries run forever, unlike traditional batch queries.",
    "Event time and processing time are two different concepts in streaming.",
    "The sentence stream pipeline counts words in real time.",
    "Tumbling windows are fixed size, non-overlapping time intervals.",
    "Machine learning models can be applied to streaming data too.",
    "Distributed stream processing scales to handle high data volumes.",
    "The benefits of streaming include lower latency and real-time insights.",
    "SQL simplifies complex stream processing operations.",
    "Stream processing is a paradigm shift in how we think about data.",
    "Modern businesses require real-time data for decision making.",
    "Streaming enables new applications that weren't possible with batch processing.",
]

# Connection parameters
CONN_PARAMS = {
    "host": "localhost",  # Change as needed
    "port": 4566,  # RisingWave default port
    "dbname": "dev",
    "user": "root",  # Default RisingWave user
    "password": "",  # Default has no password
}


def simulate_stream(interval=2.0, limit=None, start_id=100):
    """
    Simulate a stream by inserting sentences at regular intervals.

    Args:
        interval: Time in seconds between inserts
        limit: Optional limit to number of sentences to insert (None for infinite)
        start_id: Starting ID for the records (should be higher than test data)
    """
    try:
        conn = psycopg2.connect(**CONN_PARAMS)
        cursor = conn.cursor()

        count = 0
        current_id = start_id

        print(f"Starting sentence stream simulation (interval: {interval}s)")
        print("Press Ctrl+C to stop")

        while limit is None or count < limit:
            # Select a random sentence
            sentence = random.choice(SENTENCES)

            # Insert the sentence with current timestamp
            cursor.execute(
                "INSERT INTO sentence_source (id, content, event_time) VALUES (%s, %s, %s)",
                (current_id, sentence, datetime.now()),
            )
            conn.commit()

            # Print feedback
            count += 1
            print(
                f"[{datetime.now().strftime('%H:%M:%S')}] Inserted (ID: {current_id}): {sentence}"
            )

            # Increment ID for next insert
            current_id += 1

            # Wait for the specified interval
            time.sleep(interval)

    except KeyboardInterrupt:
        print("\nStream simulation stopped manually")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if "conn" in locals():
            conn.close()
            print("Connection closed")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Simulate a stream of sentences")
    parser.add_argument(
        "--interval",
        type=float,
        default=2.0,
        help="Time in seconds between inserts (default: 2.0)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit the number of sentences to insert (default: unlimited)",
    )
    parser.add_argument(
        "--start-id",
        type=int,
        default=100,
        help="Starting ID for the inserted records (default: 100)",
    )

    args = parser.parse_args()

    simulate_stream(interval=args.interval, limit=args.limit, start_id=args.start_id)
