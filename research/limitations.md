# RisingWave Streaming Database Limitations and Constraints

This document summarizes the constraints and issues encountered while implementing our streaming data pipelines with RisingWave.

## General Limitations

1. **SQL Dialect Restrictions**
   - RisingWave implements a subset of PostgreSQL SQL dialect
   - Not all PostgreSQL functions are available or behave identically
   - Some functions may require different syntax or alternatives

2. **Streaming Query Limitations**
   - Certain operations are restricted in streaming contexts compared to batch processing
   - Special considerations are needed for window functions, aggregations, and joins

## Pipeline-Specific Issues

### 1. Log Analytics Pipeline

Our first pipeline focused on parsing and analyzing web server logs. Key issues encountered:

1. **Text Parsing Limitations**
   - Limited regex pattern matching capabilities compared to PostgreSQL
   - Required simpler expressions for log parsing
   - More complex text transformations needed to be pre-processed before ingestion

2. **Timestamp Handling**
   - Timezone handling requires explicit conversion functions
   - `TO_TIMESTAMP` function parameters differ slightly from PostgreSQL

### 2. E-commerce Analytics Pipeline

The e-commerce pipeline tracked user behavior, product performance, and sales metrics. Several compatibility issues emerged:

1. **Data Type Compatibility**
   - `DECIMAL` type caused problems in some aggregation contexts
   - Solution: Use `DOUBLE PRECISION` instead for reliable computation
   - This affects precision when dealing with currency values

2. **Window Function Requirements**
   - Window functions require explicit `PARTITION BY` clauses in RisingWave
   - More verbose syntax compared to PostgreSQL defaults
   - Example:

     ```sql
     -- PostgreSQL allows:
     ROW_NUMBER() OVER (ORDER BY timestamp)
     
     -- RisingWave requires:
     ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY timestamp)
     ```

3. **Timestamp Handling**
   - Time-based calculations require standardized approaches
   - Explicit casting and formatting needed for consistent results

### 3. IoT Sensor Network Pipeline

The IoT pipeline processes sensor data streams with geospatial analytics. This pipeline revealed several significant constraints:

1. **Random Function Unavailable**
   - The `random()` function isn't supported in RisingWave
   - Solution: Used deterministic alternatives for test data generation
   - Example: Replaced `random() * X` with patterns using modulo operations for variation

   ```sql
   -- Original:
   value + (random() * 5 - 2.5)
   
   -- Fixed:
   value + (2.5 * (hour_offset % 2) - 2.5)
   ```

2. **NOW() Usage Restrictions**
   - `NOW()` function is restricted in some streaming query contexts
   - Issue: Can't use `NOW()` for time comparisons in materialized views
   - Solution: Reference reading_time from source stream

   ```sql
   -- Original problematic code:
   WHEN NOW() - s.installation_date > INTERVAL '365 days' THEN 'Routine'
   
   -- Fixed approach:
   WHEN cs.reading_time > s.installation_date + INTERVAL '365 days' THEN 'Routine'
   ```

3. **JSON Handling Differences**
   - PostgreSQL's `json_build_object()` function isn't available
   - RisingWave uses `jsonb_build_object()` instead
   - Solution: Replaced all JSON string concatenation with proper JSONB functions

   ```sql
   -- Original that failed:
   '{"humidity": ' || (65 + random() * 10)::text || '}'
   
   -- Fixed approach:
   jsonb_build_object('humidity', (65 + (5 * (hour_offset + reading_num) % 2)))
   ```

## Best Practices

Based on these experiences, we recommend the following best practices when working with RisingWave:

1. **Data Types**
   - Prefer `DOUBLE PRECISION` over `DECIMAL` for numeric values in calculations
   - Use appropriate casting when mixing data types

2. **Window Functions**
   - Always include explicit `PARTITION BY` clauses in window functions
   - Test window function behavior with small datasets before scaling

3. **Timestamps and Time Calculations**
   - Avoid using `NOW()` in streaming contexts where timestamps from the source stream are available
   - Use explicit interval addition/subtraction rather than timestamp differences

4. **JSON Data**
   - Use `jsonb_build_object()` for creating JSON structures
   - Avoid string concatenation approaches for JSON

5. **Test Data Generation**
   - Use deterministic patterns instead of random functions
   - Create variation through modulo operations, sine waves, or other predictable patterns
