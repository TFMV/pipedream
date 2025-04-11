-- create_views.sql
-- Processes the sentence stream, splits into words, and aggregates word counts

-- Step 1: Create a view that splits sentences into words
-- Using string_to_array and unnest to split sentences by space
CREATE MATERIALIZED VIEW words_stream AS
SELECT
    id,
    event_time,
    event_time_with_watermark,
    LOWER(word) AS word  -- Convert to lowercase for consistent counting
FROM
    sentence_source_with_watermark,
    UNNEST(STRING_TO_ARRAY(content, ' ')) AS word
WHERE
    word <> '';  -- Filter out empty strings

-- Step 2: Create a materialized view with tumbling window to count words
CREATE MATERIALIZED VIEW word_counts AS
SELECT
    window_start,
    window_end,
    word,
    COUNT(*) AS count
FROM
    TUMBLE(words_stream, event_time_with_watermark, INTERVAL '1 minute')
GROUP BY
    window_start, window_end, word
ORDER BY
    window_start DESC, count DESC;

-- Step 3: Create a materialized view for total counts across all time
-- This provides a cumulative view without windowing
CREATE MATERIALIZED VIEW total_word_counts AS
SELECT
    word,
    COUNT(*) AS total_count
FROM
    words_stream
GROUP BY
    word
ORDER BY
    total_count DESC; 