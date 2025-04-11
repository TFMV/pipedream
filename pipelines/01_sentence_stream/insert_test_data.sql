-- insert_test_data.sql
-- Sample data for testing the sentence stream pipeline
-- Can be used if you're not using the datagen connector or for specific test cases

-- Inserting sample sentences with timestamps
-- Note: When using for testing, you may need to manually create a regular table instead of a source
--       by removing the connector properties and using:
--       CREATE TABLE sentence_source (...) instead of CREATE SOURCE

-- Sample data with literary quotes
INSERT INTO sentence_source (id, content, event_time) VALUES
(1, 'The quick brown fox jumps over the lazy dog.', NOW()),
(2, 'To be or not to be that is the question.', NOW() - INTERVAL '10 second'),
(3, 'It was the best of times it was the worst of times.', NOW() - INTERVAL '20 second'),
(4, 'All happy families are alike each unhappy family is unhappy in its own way.', NOW() - INTERVAL '30 second'),
(5, 'Call me Ishmael some years ago never mind how long precisely.', NOW() - INTERVAL '40 second'),
(6, 'It is a truth universally acknowledged that a single man in possession of a good fortune must be in want of a wife.', NOW() - INTERVAL '50 second'),
(7, 'In a hole in the ground there lived a hobbit.', NOW() - INTERVAL '60 second'),
(8, 'The sky above the port was the color of television tuned to a dead channel.', NOW() - INTERVAL '70 second'),
(9, 'You miss one hundred percent of the shots you do not take.', NOW() - INTERVAL '80 second'),
(10, 'Life is what happens when you are busy making other plans.', NOW() - INTERVAL '90 second');

-- For continuous testing, you can run additional inserts with current timestamps
INSERT INTO sentence_source (id, content, event_time) VALUES
(11, 'Data streaming is a powerful paradigm for real time analytics.', NOW()),
(12, 'RisingWave processes streams of data with SQL simplicity.', NOW()),
(13, 'Stream processing enables businesses to react to events as they happen.', NOW()); 