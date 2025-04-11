-- create_tables.sql
-- Creates the source table for the sentence stream

-- Create a table for sentences with a timestamp field for event time
CREATE TABLE sentence_source (
    id BIGINT,              -- Unique identifier for each sentence
    content VARCHAR,        -- The actual sentence content
    event_time TIMESTAMP,   -- Event timestamp for windowing
    PRIMARY KEY (id)
);

-- Create a view that includes watermarks for late-arriving data
CREATE MATERIALIZED VIEW sentence_source_with_watermark AS
SELECT 
    id,
    content,
    event_time,
    (event_time - INTERVAL '5 second') AS event_time_with_watermark
FROM 
    sentence_source; 