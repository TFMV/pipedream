# Pipedream: Stream Processing Pipelines with RisingWave

*Where real-time data meets developer experience*

![Header Image](https://raw.githubusercontent.com/risingwavelabs/risingwave/main/.github/RisingWave-logo-light.svg)

Today is Friday, April 11th. It's 5AM where I am. The sky is still dark. The coffee's gone cold, and I've switched to Redbull. I've been working on this article - and the GitHub repo that goes with it - since around 2AM.
I'm half data architect, half data engineer. Or maybe half software engineer too - I've stopped keeping track of the fractions. What I do know is this: I've been building data pipelines for twenty years. I've worked with dozens - maybe hundreds - of frameworks.
 I'm obsessive about data systems. I study them. I try to break them. And when I find something interesting, I write about it.
A couple weeks ago, someone on LinkedIn asked me to review a new platform. I won't name it here. I gave it a fair shot - two solid hours - and came away with nothing but parser errors and frustration. In that moment, I wrote a critical article. I called it Pipedream. It wasn't very kind. I deleted it almost immediately.
My mother always told me: if you don't have anything nice to say, don't say anything at all. She's probably right.
 Good thing I pulled it. I'd been stuck in a loop, making the same dumb mistake again and again. Total waste of time - and entirely my fault. That kind of thing gets under my skin. I needed a win.
RisingWave had been sitting quietly in the back of my mind - a kind of ace up my sleeve. I'd been watching it evolve, waiting for the right moment to dive in. This time, I did.
And it turns out, it wasn't just promising. It was a joy.
This article is still called Pipedream - but this time, it's about RisingWave: the most promising data platform I've used in decades. Maybe ever.
I'll circle back to that other platform eventually. I always do. But not today.

## First Things Last

Let's get this out of the way up front - RisingWave is not ready for production. Not yet. But that's not what this piece is about.

I've spent enough time with early-stage technologies to spot the difference between "promising but unfinished" and "fundamentally flawed." RisingWave firmly occupies the former category. The core architecture is sound. The SQL implementation is thoughtful. The gaps are ones that will close with time, not fundamental design issues that will require painful rewrites.

What's missing? Production hardening. Enterprise features like role-based access control. The battle scars that only come from running under load in diverse environments. There are still rough edges in error messages that leave you scratching your head. Documentation that assumes knowledge you might not have. And the inevitable performance tuning for edge cases that only emerge at scale.

But crucially, the system makes correct trade-offs. Where options existed, the RisingWave team has consistently chosen developer experience over theoretical purity, pragmatic solutions over academic elegance. When something doesn't quite work how you expect, there's usually a reasonable explanation - and an alternative approach that does work.

I've implemented systems with Kafka Streams where everything was a fight. I've battled Flink jobs that required days of tuning to avoid out-of-memory errors. I've seen promising prototypes collapse under their own complexity. RisingWave feels different. It feels like a genuine paradigm shift - the kind that comes along maybe once a decade in our field.

This isn't a launch announcement. It's a signal. A moment in time when something rare happened in streaming: I reached for a tool I'd never used before… and it just made sense.

## What Is RisingWave?

I've had a front-row seat to the streaming data parade. From the early days of homebrew ETL scripts to the Hadoop revolution, through the Kafka ecosystem explosion, and now into the cloudy, containerized present. In all that time, I've never seen a platform that feels quite like RisingWave.

It occupies a space I've been waiting for someone to fill: a streaming database. Not a message queue with a query layer bolted on. Not a batch system pretending to be real-time. A database, designed from first principles, that treats streams as its native abstraction.

What does that mean in practice? It means:

- **PostgreSQL compatibility** that actually works. Your existing SQL knowledge transfers seamlessly.
- **Stream-table duality** without the ceremony. Tables are streams. Streams are tables. No philosophical debates required.
- **Materialized views** that continuously update. Write a query once, get answers forever.
- **Time-based processing** that doesn't make you want to tear your hair out.

Under the hood, RisingWave employs what database folks call a "cloud-native, disaggregated architecture" - separating compute from storage with a Meta node to coordinate it all. Born in the cloud era (unlike older frameworks like Flink, which emerged during the Hadoop days), RisingWave's design makes elastic scaling natural, not a bolt-on afterthought. This architecture lets it recover from failures in seconds rather than minutes and scales to handle massive state without breaking a sweat.

While Confluent and Databricks have been busy retrofitting SQL onto their existing platforms, RisingWave built a streaming engine with SQL as its mother tongue. For those of us who've spent years translating between languages and paradigms, it's like suddenly discovering that everyone in the room speaks your native language.

For this deep dive, I've used the self-hosted Docker setup. You can grab it from the [official RisingWave repository](https://github.com/risingwavelabs/risingwave) if you want to follow along.

## The Pipedream Project

Every technical talk I've ever attended shows the same thing: perfect, pristine pipelines flowing from left to right. Colored boxes. Crisp arrows. Everything just works.

Real pipelines aren't like that. They're messy. They have edge cases. They break in ways you never anticipated. And fixing them often means venturing into territories where documentation fears to tread.

That's why I built [Pipedream](https://github.com/tfmv/pipedream) – not to showcase ideal scenarios, but to document what actually happens when the rubber meets the road. It's a collection of three progressively complex streaming pipelines built on RisingWave, warts and all:

| Pipeline | Description | Skills Demonstrated |
|----------|-------------|---------------------|
| [01_sentence_stream](https://github.com/tfmv/pipedream/tree/main/pipelines/01_sentence_stream) | Text-based stream with basic time windows | Parsing, timestamps, simple aggregations |
| [02_ecommerce_analytics](https://github.com/tfmv/pipedream/tree/main/pipelines/02_ecommerce_analytics) | User behavior and conversion tracking | Joins, sliding windows, funnel metrics |
| [03_iot_sensors](https://github.com/tfmv/pipedream/tree/main/pipelines/03_iot_sensors) | Sensor data with geospatial context | Anomaly detection, complex event processing |

Think of them as three progressively difficult bike trails. The first gets you comfortable with the basics. The second introduces challenging terrain. The third throws in some jumps and hairpin turns.

Each pipeline is fully functional – not conceptual. You'll find SQL scripts, sample data, and detailed READMEs documenting both what worked and what didn't. These represent my actual journey with RisingWave, complete with the dead ends and "aha" moments.

## Building a Real Pipeline in RisingWave

Let's talk e-commerce. I've chosen the second pipeline to dig into because it hits that sweet spot – complex enough to be interesting, but not so specialized that you need domain expertise to follow along.

In the world I normally inhabit, building this pipeline would require:

- A Kafka cluster for ingestion
- A fleet of Flink jobs for processing
- A data warehouse for serving results
- Orchestration to keep it all running
- A team of specialists to manage each layer

That's the modern data stack. We've normalized its complexity. We've accepted its cost.

RisingWave offers a different path. Watch what happens when we build this e-commerce pipeline from scratch.

We start with two simple tables – products and user events:

```sql
CREATE TABLE products (
    product_id VARCHAR PRIMARY KEY,
    name VARCHAR,
    category VARCHAR,
    price DOUBLE PRECISION,
    inventory INT,
    created_at TIMESTAMP
);

CREATE TABLE user_events (
    event_id VARCHAR PRIMARY KEY,
    user_id VARCHAR,
    session_id VARCHAR,
    event_type VARCHAR,
    page_id VARCHAR,
    product_id VARCHAR,
    event_time TIMESTAMP,
    device_type VARCHAR,
    referrer VARCHAR,
    event_data JSONB
);
```

Nothing fancy here. Standard PostgreSQL syntax. Familiar territory.

Now, to handle late-arriving data (because networks are messy and clocks are never synchronized), we create a watermarked view:

```sql
CREATE MATERIALIZED VIEW user_events_watermarked AS
SELECT 
    *,
    -- Allow events up to 2 minutes late
    event_time - INTERVAL '2 minutes' AS event_time_watermark
FROM 
    user_events;
```

Here's where things get interesting. With this foundation, we can build a conversion funnel analysis that updates automatically as new events arrive:

```sql
CREATE MATERIALIZED VIEW funnel_analysis AS
SELECT
    window_start,
    COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN session_id END) AS pageview_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN session_id END) AS product_view_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN session_id END) AS cart_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) AS purchase_sessions,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN session_id END), 0) AS overall_conversion_rate,
    COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN session_id END) / 
        NULLIF(COUNT(DISTINCT CASE WHEN event_type = 'product_view' THEN session_id END), 0) AS product_to_purchase_rate
FROM
    TUMBLE(user_events_watermarked, event_time, INTERVAL '1 hour')
GROUP BY
    window_start
ORDER BY
    window_start DESC;
```

There's no separate processing tier. No Scala or Java to write. Just SQL – the language we've been using for decades. But this view doesn't just execute and return results; it continuously updates as new events flow in.

Need a sliding window analysis to track revenue trends? RisingWave provides the HOP function:

```sql
CREATE MATERIALIZED VIEW revenue_tracker AS
SELECT
    window_start,
    window_end,
    COUNT(DISTINCT user_id) AS unique_users,
    COUNT(*) AS purchase_count,
    SUM(event_data->>'total_amount')::DOUBLE PRECISION AS revenue
FROM
    HOP(
        user_events_watermarked, 
        event_time, 
        INTERVAL '5 minutes',  -- Hop size (window slides every 5 min)
        INTERVAL '1 hour'      -- Window size (each window is 1 hour)
    )
WHERE
    event_type = 'purchase'
GROUP BY
    window_start, window_end
ORDER BY
    window_start DESC;
```

Perhaps most impressive is RisingWave's ability to join streams with static data without complex machinations. Flink and Kafka Streams often require special considerations for joining streams with lookup tables, but in RisingWave, it's just a standard SQL JOIN. This simplicity is by design – the team built the system top-down for SQL workloads rather than retrofitting SQL onto a general dataflow engine.

We just write SQL—like we always wanted to.

## Pain Points and Workarounds

I've spent twenty years getting burned by overpromising technologies. I approach every new system with healthy skepticism. So when I tell you that RisingWave delivered, understand that I was actively looking for its breaking points.

I found some, of course. No technology is perfect, and RisingWave is still young. Rather than detail each issue here, I've documented them all in a comprehensive [limitations guide](https://github.com/tfmv/pipedream/blob/main/research/limitations.md) that catalogs constraints and offers workarounds. This guide covers syntax restrictions, function limitations, and other quirks I discovered while building these pipelines.

The key pattern I noticed is that RisingWave's constraints are largely surface-level. They don't fundamentally limit what you can accomplish, just how you express it. For instance, the system restricts how you can use `NOW()` in streaming contexts, but this actually makes sense once you understand the underlying model – streaming systems need to reason about event time rather than processing time for consistency. These limitations didn't derail our pipelines; they just required adjusting our mental model.

Having worked extensively with Flink (where state management is a manual art) and ksqlDB (where SQL feels artificially constrained), I found RisingWave's approach refreshingly straightforward. When you hit an edge, the fix is usually obvious once you understand the why behind the limitation.

## How It Compares

I've spent time with most of the major players in this space. Each has its strengths and distinct personality:

**Apache Flink** is like that brilliant colleague who can solve any problem but talks exclusively in academic papers. Immensely powerful, but with a learning curve that resembles the north face of the Eiger. Where Flink offers near-infinite flexibility, RisingWave trades some of that power for approachability.

In benchmarks, RisingWave has shown impressive performance, outperforming Flink in 22 out of 27 queries in a standard streaming benchmark. Some complex queries ran up to 660 times faster on RisingWave than on Flink. This isn't just marketing – RisingWave's architecture allows it to optimize for SQL patterns that Flink's more general purpose design can't.

**Materialize** shares RisingWave's SQL-centric worldview, but differs in its foundational architecture. Built on Timely Dataflow, Materialize pioneered concepts that RisingWave has refined. The key difference is RisingWave's unified storage and compute layer, which simplifies operations but may sacrifice some flexibility.

Materialize is essentially single-node and in-memory at its core, while RisingWave is distributed by design. This means RisingWave can handle larger data volumes by scaling horizontally, while Materialize excels at ultra-low latency on smaller datasets. There's also a licensing difference – RisingWave is Apache 2.0, while Materialize uses the more restrictive Business Source License.

**ksqlDB** is purpose-built for Kafka's ecosystem. It's like a specialized tool – perfect if your needs align with its capabilities, limiting if they don't. RisingWave takes a more general-purpose approach to streaming analytics.

Unlike ksqlDB, which is tied to Kafka, RisingWave can ingest from diverse systems and output to many targets. ksqlDB also lacks many SQL features and struggles with composability – you can't easily join intermediate results in complex processing graphs. RisingWave lets you define multiple views that can feed each other arbitrarily, enabling much richer pipelines.

But here's the thing: the most revealing comparison isn't between RisingWave and other streaming technologies. It's between RisingWave and traditional databases. The mental model transfer is nearly perfect. If you know PostgreSQL, you already know 90% of what you need to work with RisingWave.

That's not an accident. It's a deliberate design choice that prioritizes developer experience above all else.

## Where This Is Going

I've witnessed enough technological shifts to recognize patterns. We're watching a fundamental change in how data systems evolve – from batch-first to stream-first thinking.

The next five years will likely bring:

1. **The collapse of the batch/streaming divide**. Future systems won't distinguish between the two – streaming will be the default, with batch as a special case of finite streams.

2. **The simplification of data architectures**. The current stack is unsustainably complex. Systems like RisingWave hint at a future where separate ingestion, processing, and serving layers converge.

3. **The democratization of real-time analytics**. As streaming becomes more accessible through familiar interfaces like SQL, the pool of people who can work with real-time data expands dramatically.

4. **The return of SQL supremacy**. After years of fragmentation into specialized languages and frameworks, SQL is reclaiming its position as the lingua franca of data – now enhanced with streaming semantics.

RisingWave's standout feature – "time travel queries" – offers a glimpse of this future. Using the syntax `SELECT * FROM table_name FOR SYSTEM_TIME AS OF <timestamp>;`, analysts can query a table's contents at a past point in time. This treats the streaming engine like a time machine, avoiding the need for manual snapshotting or log analysis. For debugging, auditing, and forensic work, this capability is transformative.

For those of us who've spent careers juggling tools, frameworks, and paradigms, this evolution is long overdue. The promise of systems like RisingWave isn't just technical elegance – it's sanity. It's the ability to solve real problems without first constructing enormously complex infrastructure.

If streaming databases continue on this trajectory, we might finally achieve what's always been tantalizingly out of reach: data systems that are both powerful and comprehensible. Fast and reliable. Sophisticated and approachable.

The future of data engineering might be SQL again – only smarter.

## Try It Yourself

It's 5:45AM now. I've gone through another can of Redbull. But I'm not tired – I'm energized. That's what happens when you find a tool that makes hard problems feel solvable.

The real test of any technology isn't what I tell you about it – it's what you can build with it. Pipedream gives you a starting point: three fully-functional pipelines of increasing complexity, ready to deploy and explore.

The repository includes:

- Complete SQL scripts for tables, views, and sample data
- Detailed READMEs explaining each pipeline's architecture
- Sample queries to explore the results
- Documentation of the limitations and workarounds I discovered

You can find the complete project at [https://github.com/tfmv/pipedream](https://github.com/tfmv/pipedream).

I welcome your contributions, feedback, and especially your own pipeline ideas. Because while stream processing may still feel hard sometimes, the only way to make it easier is to build, share, and learn together.

---

*Thomas McGeehan is a data engineer and writer specializing in streaming architectures and real-time analytics. He can be found on [GitHub](https://github.com/tfmv) and [Twitter](https://twitter.com/mcgeehan), usually thinking about data problems at unreasonable hours – like 5AM on a Friday morning.*
