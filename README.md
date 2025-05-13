# dbre-pg16-extended: PostgreSQL 16 Extended Features and Use Cases Demo

This repository provides a collection of SQL scripts to demonstrate various advanced features and use cases in PostgreSQL 16. It includes examples of table partitioning with `pg_partman`, setting up an analytical data warehouse schema, and comparing normalized versus JSONB data models for e-commerce scenarios. Several useful PostgreSQL extensions are also showcased.

## Project Structure

The SQL script sets up three distinct databases, each tailored for specific demonstrations:

1.  `partitioning_test`: Focuses on time-based table partitioning using `pg_partman` and demonstrates various extensions like `pg_cron`, `vector`, `bloom`, etc.
2.  `analytical`: Implements a star schema for a data warehouse, complete with dimension and fact tables, and functions for data generation and cleanup.
3.  `json_demo`: Compares a traditional normalized database schema with a JSONB-based approach for handling semi-structured order data.

## Setup Instructions

1.  **Ensure PostgreSQL 16 is installed and running.**
2.  **Create the necessary databases:**
    ```sql
    CREATE DATABASE partitioning_test;
    CREATE DATABASE analytical;
    CREATE DATABASE json_demo;
    ```
3.  **Connect to each database sequentially and run the corresponding sections of the main SQL script.**
    For example, to set up the `partitioning_test` database:
    ```bash
$ docker exec -it pg16-extended bash
   psql -U postgres
postgres=# \l
                                                          List of databases
       Name        |  Owner   | Encoding | Locale Provider |  Collate   |   Ctype    | ICU Locale | ICU Rules |   Access privileges
-------------------+----------+----------+-----------------+------------+------------+------------+-----------+-----------------------
 analytical        | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           |
 json_demo         | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           |
 partitioning_test | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           |
 postgres          | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           |
 template0         | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/postgres          +
                   |          |          |                 |            |            |            |           | postgres=CTc/postgres
 template1         | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8 |            |           | =c/postgres          +
                   |          |          |                 |            |            |            |           | postgres=CTc/postgres
(6 rows)

postgres=#
    ```

## Database Details

### 1. `partitioning_test` Database

This database is designed to showcase table partitioning and the utility of several PostgreSQL extensions.

* **Schema `partman`**: Houses objects related to the `pg_partman` extension.
* **Extensions Used**:
    * `pg_partman`: For automating time-based and serial partitioning.
    * `pg_cron`: For scheduling PostgreSQL jobs (e.g., partition maintenance). *Note: Ensure `cron.database_name = 'partitioning_test'` is set in `postgresql.conf` or via `ALTER SYSTEM` for `pg_cron` to function correctly with this database.*
    * `vector`: For working with vector embeddings (e.g., for AI/ML applications).
    * `bloom`: Provides Bloom filter access method for faster lookups on certain data types.
    * `hstore`: For storing key-value pairs.
    * `postgres_fdw`: For accessing data in other PostgreSQL databases (Foreign Data Wrapper).
    * `pgcrypto`: For cryptographic functions.
    * `pg_stat_statements`: For tracking execution statistics of SQL statements.
* **Search Path**: The search path is set to `public, partman` for this database.
* **Tables**:
    * `table_a`: A regular table with a timestamp, UUID, and text data. Includes sample data.
    * `table_b_partitioned`: A table partitioned by `timestamp` (range partitioning).
        * **Partitioning Strategy**: Managed by `pg_partman`, with a 7-day interval for partitions. `p_premake = 3` means `pg_partman` will maintain 3 future partitions.
    * `earthquakes`: Stores JSONB data representing earthquake features, including nested location data.
    * `regions`: Stores geographical region boundaries.
* **Functions**:
    * `dbre_populate_partitioned_table()`: A PL/pgSQL function to insert sample data into `table_b_partitioned` with options to specify the number of records, date ranges, or a specific date for data generation.

### 2. `analytical` Database

This database demonstrates a typical data warehouse setup using a star schema.

* **Extensions Used**: Similar to `partitioning_test` (excluding `pg_cron` specific setup in this script, but it can be used).
    * `pg_partman`, `vector`, `bloom`, `hstore`, `postgres_fdw`, `pgcrypto`, `pg_stat_statements`.
* **Dimension Tables**:
    * `dim_dates`: Stores date-related attributes (day of week, month, quarter, year, holiday flag).
    * `dim_users`: Stores user information, including segment, country, signup date, and activity status.
    * `dim_products`: Stores product details like category, subcategory, price tier, and featured status.
    * `dim_campaigns`: Stores marketing campaign information, including type, channel, start and end dates.
* **Fact Tables**:
    * `fact_user_events`: Records user interactions like purchases, add_to_cart, product views, and searches.
    * `fact_transactions`: Records detailed transaction data, linking users, products, campaigns, and dates, including quantity, revenue, and discount.
* **Functions**:
    * `public.dbre_cleanup_all_data()`: Truncates all fact and dimension tables in the `analytical` database.
    * `dbre_generate_high_volume_data()`: Populates the dimension and fact tables with a large volume of synthetic data (365 dates, 5,000 users, 5,000 products, 200 campaigns, 1,000,000 transactions, and 1,000,000 user events). It also creates indexes on fact tables for better query performance.
    * `dbre_count_all_tables()`: Returns a table with the name and row count of each table in the `public` schema.

### 3. `json_demo` Database

This database is set up to compare and contrast a normalized relational model with a denormalized JSONB-based model for an e-commerce orders system.

* **Normalized Tables**:
    * `customers`: Stores customer information.
    * `addresses`: Stores customer billing and shipping addresses.
    * `orders`: Stores order header information, linking to customer and addresses.
    * `products`: Stores product catalog information.
    * `order_items`: Stores individual items within an order (line items).
* **JSONB Table**:
    * `orders_jsonb`: Stores order data in a single JSONB column. This `data` column typically includes customer details, addresses, and line items nested within the JSON structure.
* **Indexes**:
    * Standard B-tree indexes on foreign keys and frequently queried columns in normalized tables.
    * GIN index on `orders_jsonb ((data->'customer'->'customer_id'))` for efficient querying of customer ID within the JSONB structure.
    * B-tree index on `orders_jsonb(order_date)`.
* **Functions**:
    * `dbre_populate_orders_demo(sample_size INTEGER DEFAULT 1000)`: Populates both the normalized tables and the `orders_jsonb` table with a specified number of sample orders. For each order, it creates a customer, addresses, order details, and multiple order items, storing them in both relational and JSONB formats.
* **Analysis**: The script includes `ANALYZE VERBOSE` commands for all tables to update statistics, which is crucial for the query planner to generate efficient execution plans, especially when comparing query performance between normalized and JSONB approaches.

## Key Features Demonstrated

* **Advanced Table Partitioning**: Using `pg_partman` for automated time-series data management.
* **Data Warehousing Schema**: Implementation of a star schema with dimension and fact tables.
* **High-Volume Data Generation**: PL/pgSQL functions to create large datasets for performance testing and analytical queries.
* **JSONB Data Modeling**: Comparison of normalized relational design versus storing complex, semi-structured data using JSONB.
* **PostgreSQL Extensions**: Utilization of various powerful extensions like `pg_cron` for job scheduling, `vector` for similarity searches, `bloom` for efficient filtering, `hstore` for key-value data, `postgres_fdw` for federated queries, `pgcrypto` for data encryption, and `pg_stat_statements` for query performance monitoring.
* **Data Ingestion and Management Functions**: Custom PL/pgSQL functions for populating tables and cleaning up data.

## How to Use

1.  **Initialization**: Follow the setup instructions to create databases and run the main SQL script.
2.  **Data Population**:
    * For `partitioning_test`: Use `SELECT dbre_populate_partitioned_table(...);`
    * For `analytical`: Use `SELECT dbre_generate_high_volume_data();`
    * For `json_demo`: Use `SELECT dbre_populate_orders_demo(...);`
3.  **Exploration**:
    * Examine table structures (`\d table_name`).
    * Query the data in each database.
    * Analyze query plans (`EXPLAIN ANALYZE SELECT ...`).
    * Explore `pg_partman`'s control tables (e.g., `partman.part_config`).
    * Test the performance of queries on normalized vs. JSONB tables in `json_demo`.
    * Schedule jobs using `pg_cron` if configured.

This repository serves as a practical guide and sandbox for exploring these extended PostgreSQL capabilities.
