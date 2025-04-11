# Sentence Stream Pipeline

A simple RisingWave streaming pipeline that processes a stream of sentences, splits them into words, and counts word occurrences in real-time using tumbling time windows.

## Pipeline Overview

This pipeline demonstrates fundamental stream processing concepts:

1. **Ingestion:** Creates a table for sentence data with timestamps
2. **Transformation:** Splits sentences into individual words
3. **Aggregation:** Counts word occurrences using 1-minute tumbling windows
4. **Materialization:** Exposes results as materialized views for querying

## Components

- **Tables:**
  - `sentence_source` - Stores sentences with timestamps
  - `sentence_source_with_watermark` - Applies watermark to handle late-arriving data
- **Materialized Views:**
  - `words_stream` - Splits sentences into individual words
  - `word_counts` - Counts words per 1-minute window
  - `total_word_counts` - Cumulative word counts across all time

## SQL Files

- `create_tables.sql` - Creates the source table and watermark view
- `create_views.sql` - Creates the materialized views for processing and aggregation
- `insert_test_data.sql` - Contains sample data for testing

## Usage

### Setup

1. Start your RisingWave instance
2. Create the pipeline components:

```bash
# Create the source table and watermark view
psql -h localhost -p 4566 -d dev -f create_tables.sql

# Create the materialized views
psql -h localhost -p 4566 -d dev -f create_views.sql
```

### Testing

For testing with sample data:

```bash
# Insert test data
psql -h localhost -p 4566 -d dev -f insert_test_data.sql
```

For continuous data simulation:

```bash
# Run the simulator script (requires psycopg2)
python simulate_stream.py
```

### Querying Results

```sql
-- Query word counts in a specific time window
SELECT * FROM word_counts LIMIT 10;

-- Query total word counts across all time
SELECT * FROM total_word_counts LIMIT 10;
```

## Technical Details

- **Watermarks:** Used to handle late data with a 5-second allowed delay
- **Tumbling Windows:** Non-overlapping 1-minute windows for aggregation
- **String Processing:** Uses `STRING_TO_ARRAY` and `UNNEST` to split sentences
- **Case Normalization:** Converts all words to lowercase for consistent counting

## Scaling Considerations

This pipeline can be extended to:

- Ingest from Kafka or other external message brokers
- Add more complex filtering and enrichment steps
- Implement more sophisticated time windows (sliding, session)
- Connect to downstream systems for alerts or visualizations

## Compatibility Notes

This pipeline is designed specifically for RisingWave, which has PostgreSQL-compatible syntax with some differences:

- Uses regular tables instead of sources for simplicity
- Applies watermarks through a materialized view
- Requires explicit IDs for each record
- Uses the TUMBLE function for window aggregation
