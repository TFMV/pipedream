#!/bin/bash
# Script to set up and run the sentence stream pipeline

set -e  # Exit on any error

# Configuration - adjust as needed
RW_HOST="localhost"
RW_PORT="4566"
RW_DB="dev"
RW_USER="root"
RW_PSQL="psql -h $RW_HOST -p $RW_PORT -d $RW_DB -U $RW_USER"

echo "=== Setting up Sentence Stream Pipeline ==="

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
DROP MATERIALIZED VIEW IF EXISTS total_word_counts CASCADE;
DROP MATERIALIZED VIEW IF EXISTS word_counts CASCADE;
DROP MATERIALIZED VIEW IF EXISTS words_stream CASCADE;
DROP MATERIALIZED VIEW IF EXISTS sentence_source_with_watermark CASCADE;
DROP TABLE IF EXISTS sentence_source CASCADE;
EOF

# Create tables
echo -e "\n=== Creating source table ==="
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

# Ask if user wants to run the simulator
read -p "Do you want to run the sentence stream simulator? (y/n): " run_simulator
if [[ $run_simulator == "y" || $run_simulator == "Y" ]]; then
    echo -e "\n=== Running stream simulator ==="
    echo "Tip: You can open another terminal and run queries to see the results in real-time"
    echo "Example: $RW_PSQL -c 'SELECT * FROM total_word_counts LIMIT 10;'"
    echo ""
    ./simulate_stream.py
else
    echo -e "\n=== Pipeline setup complete! ==="
    echo "To query word counts, run:"
    echo "$RW_PSQL -c 'SELECT * FROM word_counts LIMIT 10;'"
    echo ""
    echo "To query total word counts, run:"
    echo "$RW_PSQL -c 'SELECT * FROM total_word_counts LIMIT 10;'"
fi 