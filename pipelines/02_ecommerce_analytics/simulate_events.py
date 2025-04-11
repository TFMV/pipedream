#!/usr/bin/env python3
"""
E-Commerce Event Stream Simulator

This script simulates a continuous stream of e-commerce events by inserting
random events into the user_events table. It's useful for testing the
RisingWave pipeline with realistic user behavior patterns.
"""

import psycopg2
import time
import random
import uuid
import json
from datetime import datetime

# Connection parameters
CONN_PARAMS = {
    "host": "localhost",  # Change as needed
    "port": 4566,  # RisingWave default port
    "dbname": "dev",
    "user": "root",  # Default RisingWave user
    "password": "",  # Default has no password
}

# List of existing product IDs
PRODUCT_IDS = [
    "P001",
    "P002",
    "P003",
    "P004",
    "P005",
    "P006",
    "P007",
    "P008",
    "P009",
    "P010",
]

# List of existing user IDs
USER_IDS = [
    "U001",
    "U002",
    "U003",
    "U004",
    "U005",
    "U006",
    "U007",
    "U008",
    "U009",
    "U010",
]

# Event types with their relative frequencies
EVENT_TYPES = {
    "pageview": 45,
    "product_view": 30,
    "add_to_cart": 15,
    "checkout": 5,
    "purchase": 5,
}

# Page URLs by event type
PAGE_URLS = {
    "pageview": [
        "https://example.com/home",
        "https://example.com/products",
        "https://example.com/categories",
        "https://example.com/blog",
        "https://example.com/about",
    ],
    "product_view": [f"https://example.com/products/{pid}" for pid in PRODUCT_IDS],
    "add_to_cart": [f"https://example.com/products/{pid}" for pid in PRODUCT_IDS],
    "checkout": ["https://example.com/checkout"],
    "purchase": ["https://example.com/order-confirmation"],
}

# Referrer URLs
REFERRER_URLS = [
    "https://google.com",
    "https://bing.com",
    "https://facebook.com",
    "https://instagram.com",
    "https://twitter.com",
    "https://pinterest.com",
    "https://youtube.com",
    None,  # Direct traffic
]

# Device types with their relative frequencies
DEVICE_TYPES = {"mobile": 60, "desktop": 30, "tablet": 10}


def get_random_weighted(options_dict):
    """Get a random item based on weighted frequencies"""
    options = list(options_dict.keys())
    weights = list(options_dict.values())
    return random.choices(options, weights=weights, k=1)[0]


def generate_random_event(event_id, session_id, last_event=None):
    """Generate a random event based on the last event (if any)"""

    # If there's no last event, generate a fresh pageview
    if not last_event:
        event_type = "pageview"
        user_id = random.choice(USER_IDS)
        device_type = get_random_weighted(DEVICE_TYPES)
        product_id = None
        page_url = random.choice(PAGE_URLS[event_type])
        referrer_url = random.choice(REFERRER_URLS)
        event_data = json.dumps({"scroll_depth": random.randint(10, 100)})
    else:
        # Use the same user and device type for continuity
        user_id = last_event[1]
        device_type = last_event[7]

        # Determine the next event type based on the current one
        current_type = last_event[3]

        if current_type == "pageview":
            # After a pageview, could be another pageview or product view
            event_type = random.choices(
                ["pageview", "product_view"], weights=[60, 40], k=1
            )[0]
            if event_type == "pageview":
                product_id = None
                page_url = random.choice(PAGE_URLS[event_type])
                referrer_url = last_event[6]  # Previous page
                event_data = json.dumps({"scroll_depth": random.randint(10, 100)})
            else:  # product_view
                product_id = random.choice(PRODUCT_IDS)
                page_url = f"https://example.com/products/{product_id}"
                referrer_url = last_event[5]  # Previous page
                event_data = json.dumps({"view_duration": random.randint(10, 120)})

        elif current_type == "product_view":
            # After a product view, could view another product, add to cart, or go back to browsing
            event_type = random.choices(
                ["pageview", "product_view", "add_to_cart"], weights=[30, 30, 40], k=1
            )[0]
            if event_type == "pageview":
                product_id = None
                page_url = random.choice(PAGE_URLS[event_type])
                referrer_url = last_event[5]  # Previous page
                event_data = json.dumps({"scroll_depth": random.randint(10, 100)})
            elif event_type == "product_view":
                product_id = random.choice(PRODUCT_IDS)
                page_url = f"https://example.com/products/{product_id}"
                referrer_url = last_event[5]  # Previous page
                event_data = json.dumps({"view_duration": random.randint(10, 120)})
            else:  # add_to_cart
                product_id = last_event[4]  # Use the same product
                page_url = last_event[5]  # Same page
                referrer_url = None
                event_data = json.dumps({"quantity": random.randint(1, 3)})

        elif current_type == "add_to_cart":
            # After adding to cart, could view another product, go to cart, or continue browsing
            event_type = random.choices(
                ["pageview", "product_view", "checkout"], weights=[20, 40, 40], k=1
            )[0]
            if event_type == "pageview":
                if random.random() < 0.7:  # 70% chance to go to cart
                    page_url = "https://example.com/cart"
                else:
                    page_url = random.choice(PAGE_URLS["pageview"])
                product_id = None
                referrer_url = last_event[5]  # Previous page
                event_data = json.dumps({"scroll_depth": random.randint(10, 100)})
            elif event_type == "product_view":
                product_id = random.choice(PRODUCT_IDS)
                page_url = f"https://example.com/products/{product_id}"
                referrer_url = last_event[5]  # Previous page
                event_data = json.dumps({"view_duration": random.randint(10, 120)})
            else:  # checkout
                product_id = None
                page_url = "https://example.com/checkout"
                referrer_url = "https://example.com/cart"
                # Random cart value between $20 and $500
                cart_value = round(random.uniform(20, 500), 2)
                item_count = random.randint(1, 5)
                event_data = json.dumps(
                    {"cart_value": cart_value, "item_count": item_count}
                )

        elif current_type == "checkout":
            # After checkout, high chance of purchase or abandonment
            event_type = random.choices(
                ["pageview", "purchase"], weights=[30, 70], k=1
            )[0]
            if event_type == "pageview":
                product_id = None
                page_url = random.choice(PAGE_URLS["pageview"])
                referrer_url = last_event[5]  # Previous page
                event_data = json.dumps({"scroll_depth": random.randint(10, 100)})
            else:  # purchase
                product_id = None
                page_url = "https://example.com/order-confirmation"
                referrer_url = last_event[5]  # Previous page

                # Extract the cart value and item count from the checkout event
                checkout_data = json.loads(last_event[9])
                cart_value = checkout_data.get("cart_value", 100)
                item_count = checkout_data.get("item_count", 1)

                event_data = json.dumps(
                    {
                        "order_id": f"ORD{random.randint(1000, 9999)}",
                        "total_amount": cart_value,
                        "item_count": item_count,
                        "payment_method": random.choice(
                            ["credit_card", "paypal", "apple_pay", "google_pay"]
                        ),
                    }
                )

        elif current_type == "purchase":
            # After purchase, start a new session
            return None

        else:
            # Default to a pageview for any other event type
            event_type = "pageview"
            product_id = None
            page_url = random.choice(PAGE_URLS[event_type])
            referrer_url = random.choice(REFERRER_URLS)
            event_data = json.dumps({"scroll_depth": random.randint(10, 100)})

    # Create the event record
    event = (
        event_id,
        user_id,
        session_id,
        event_type,
        product_id,
        page_url,
        referrer_url,
        device_type,
        datetime.now(),
        event_data,
    )

    return event


def simulate_user_sessions(interval=1.0, limit=None, verbose=True):
    """
    Simulate user sessions with realistic event sequences.

    Args:
        interval: Time in seconds between event inserts
        limit: Optional limit to number of events to insert (None for infinite)
        verbose: Whether to print event details
    """
    try:
        conn = psycopg2.connect(**CONN_PARAMS)
        cursor = conn.cursor()

        count = 0
        active_sessions = {}  # session_id -> last_event
        next_event_id = 1000  # Start event IDs from 1000

        # Get the highest existing event_id to avoid duplicates
        cursor.execute(
            "SELECT MAX(CAST(SUBSTRING(event_id FROM 2) AS INT)) FROM user_events"
        )
        result = cursor.fetchone()
        if result[0]:
            next_event_id = result[0] + 1

        print(f"Starting e-commerce event simulation (interval: {interval}s)")
        print("Press Ctrl+C to stop")

        while limit is None or count < limit:
            # Randomly decide if we're continuing an existing session or starting a new one
            if (
                active_sessions and random.random() < 0.8
            ):  # 80% chance to continue an active session
                # Pick a random active session
                session_id = random.choice(list(active_sessions.keys()))
                last_event = active_sessions[session_id]

                # Generate the next event in this session
                event_id = f"E{next_event_id}"
                next_event_id += 1

                event = generate_random_event(event_id, session_id, last_event)

                # If the session is complete (e.g., after purchase), remove it from active sessions
                if not event:
                    del active_sessions[session_id]
                    continue

                # Update the active session with this event
                active_sessions[session_id] = event
            else:
                # Start a new session
                session_id = f"S{1000 + len(active_sessions)}"
                event_id = f"E{next_event_id}"
                next_event_id += 1

                event = generate_random_event(event_id, session_id)
                active_sessions[session_id] = event

            # Insert the event
            cursor.execute(
                """
                INSERT INTO user_events 
                (event_id, user_id, session_id, event_type, product_id, page_url, referrer_url, device_type, event_time, event_data)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """,
                event,
            )
            conn.commit()

            # Print feedback
            count += 1
            if verbose:
                print(
                    f"[{datetime.now().strftime('%H:%M:%S')}] Inserted {event[3]} event for user {event[1]} (Session: {event[2]})"
                )

            # Randomly remove some completed sessions to avoid too many active sessions
            if len(active_sessions) > 10:
                keys_to_remove = random.sample(list(active_sessions.keys()), 2)
                for key in keys_to_remove:
                    del active_sessions[key]

            # Wait for the specified interval
            time.sleep(interval)

    except KeyboardInterrupt:
        print("\nEvent simulation stopped manually")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        if "conn" in locals():
            conn.close()
            print("Connection closed")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Simulate a stream of e-commerce events"
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=1.0,
        help="Time in seconds between events (default: 1.0)",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=None,
        help="Limit the number of events to insert (default: unlimited)",
    )
    parser.add_argument("--quiet", action="store_true", help="Reduce output verbosity")

    args = parser.parse_args()

    simulate_user_sessions(
        interval=args.interval, limit=args.limit, verbose=not args.quiet
    )
