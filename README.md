# Pipedream: Stream Processing Pipelines with RisingWave

<p align="center">
  <picture>
    <source srcset="https://raw.githubusercontent.com/risingwavelabs/risingwave/main/.github/RisingWave-logo-dark.svg" width="500px" media="(prefers-color-scheme: dark)">
    <img src="https://raw.githubusercontent.com/risingwavelabs/risingwave/main/.github/RisingWave-logo-light.svg" width="500px">
  </picture>
</p>

A collection of stream processing pipelines demonstrating the capabilities of [RisingWave](https://risingwave.com/), a PostgreSQL-compatible streaming database. This repository accompanies a Medium article series on building real-time data pipelines.

## Overview

Pipedream provides three progressive stream processing pipelines, each demonstrating increasingly complex use cases and techniques:

1. **Log Analytics Pipeline** - Process web server logs for real-time monitoring
2. **E-commerce Analytics Pipeline** - Track user behavior, product performance, and sales metrics
3. **IoT Sensor Network Pipeline** - Monitor sensor data with geospatial analytics

Each pipeline is self-contained with fully documented SQL scripts, sample data, and detailed explanations.

## Getting Started

### Prerequisites

- [RisingWave](https://docs.risingwave.com/docs/current/install-risingwave-docker/) installed locally or in the cloud
- `psql` command-line client for PostgreSQL

### Setup

1. Clone this repository
2. Start your RisingWave instance
3. Choose a pipeline to explore and follow its README

```bash
# Example setup for the Log Analytics Pipeline
cd pipelines/01_sentence_stream
psql -h localhost -p 4566 -d dev -f create_tables.sql
psql -h localhost -p 4566 -d dev -f create_views.sql
psql -h localhost -p 4566 -d dev -f insert_test_data.sql
```

## Pipeline Details

### 1. Log Analytics Pipeline

A beginner-friendly pipeline that processes web server logs:

- **Core Features**: Text parsing, timestamp handling, tumbling windows
- **SQL Techniques**: String functions, windowing, aggregation
- **Skills Demonstrated**: Basic stream processing, time-series analysis

[View Log Analytics Pipeline →](pipelines/01_sentence_stream/)

### 2. E-commerce Analytics Pipeline

An intermediate-level pipeline focused on business analytics:

- **Core Features**: Funnel analysis, conversion tracking, product performance
- **SQL Techniques**: JOIN operations, sliding windows, complex aggregations
- **Skills Demonstrated**: Business metrics, multi-table streaming queries

[View E-commerce Analytics Pipeline →](pipelines/02_ecommerce_analytics/)

### 3. IoT Sensor Network Pipeline

An advanced pipeline for sensor data processing:

- **Core Features**: Geospatial analysis, anomaly detection, predictive maintenance
- **SQL Techniques**: JSON processing, statistical calculations, multi-dimensional analysis
- **Skills Demonstrated**: Complex event processing, time-series analysis, predictive analytics

[View IoT Sensor Network Pipeline →](pipelines/03_iot_sensors/)

## RisingWave Limitations and Best Practices

When working with RisingWave, be aware of certain constraints and best practices:

- Use `DOUBLE PRECISION` instead of `DECIMAL` for numeric computations
- Always include explicit `PARTITION BY` clauses in window functions
- Use `jsonb_build_object()` instead of string concatenation for JSON
- Avoid `random()` in favor of deterministic alternatives for test data
- Reference source stream timestamps instead of `NOW()` in streaming contexts

For a comprehensive list of limitations and solutions, see our [limitations documentation](research/limitations.md).

## Related Medium Article

This repository accompanies a Medium article series on building stream processing pipelines with RisingWave. The article provides additional context, visualizations, and step-by-step explanations of these pipelines.

[Read the Medium Article →](https://medium.com/@mcgeehan/pipedream-building-stream-processing-pipelines-with-risingwave)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
