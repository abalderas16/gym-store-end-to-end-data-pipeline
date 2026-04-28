-- =========================================================
-- GYM STORE END-TO-END DATA ENGINEER PIPELINE PROJECT
-- SPRINT 2: DDL FOUNDATION
-- DUCKDB / MOTHERDUCK READY
-- =========================================================

-- =========================================================
-- DROP OBJECTS (FACT FIRST, THEN DIMS, THEN VIEWS, THEN RAW)
-- =========================================================

DROP TABLE IF EXISTS fact_order_lines;

DROP TABLE IF EXISTS dim_order;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_ship_location;
DROP TABLE IF EXISTS dim_date;

DROP VIEW IF EXISTS stg_orders;
DROP VIEW IF EXISTS stg_order_items;
DROP VIEW IF EXISTS stg_products;
DROP VIEW IF EXISTS stg_customers;
DROP VIEW IF EXISTS stg_ship_locations;

DROP TABLE IF EXISTS raw_orders;
DROP TABLE IF EXISTS raw_order_items;
DROP TABLE IF EXISTS raw_products;
DROP TABLE IF EXISTS raw_customers;
DROP TABLE IF EXISTS raw_ship_locations;

-- =========================================================
-- RAW LAYER TABLES
-- =========================================================
--Why use VARCHAR? We do not want the raw load to fail just because the incoming source is dirty. 
-- ---------------------------------
-- raw_orders
-- Stores order header data as received
-- ---------------------------------
CREATE TABLE raw_orders (
    raw_order_id VARCHAR,
    raw_customer_id VARCHAR,
    raw_order_date VARCHAR,
    raw_order_status VARCHAR,
    raw_payment_method VARCHAR,
    raw_total_order_amount VARCHAR,
    raw_ship_location_id VARCHAR,
    source_file_name VARCHAR,
    load_timestamp TIMESTAMP
);

-- ---------------------------------
-- raw_order_items
-- Stores order line data as received
-- ---------------------------------
CREATE TABLE raw_order_items (
    raw_order_line_id VARCHAR,
    raw_order_id VARCHAR,
    raw_product_id VARCHAR,
    raw_quantity VARCHAR,
    raw_price_per_unit VARCHAR,
    raw_total_line_amount VARCHAR,
    source_file_name VARCHAR,
    load_timestamp TIMESTAMP
);

-- ---------------------------------
-- raw_products
-- Stores product catalog data as received
-- ---------------------------------
CREATE TABLE raw_products (
    raw_product_id VARCHAR,
    raw_product_name VARCHAR,
    raw_category VARCHAR,
    raw_brand VARCHAR,
    raw_unit_price VARCHAR,
    raw_is_active VARCHAR,
    source_file_name VARCHAR,
    load_timestamp TIMESTAMP
);

-- ---------------------------------
-- raw_customers
-- Stores customer data as received
-- ---------------------------------
CREATE TABLE raw_customers (
    raw_customer_id VARCHAR,
    raw_customer_name VARCHAR,
    raw_email VARCHAR,
    raw_loyalty_tier VARCHAR,
    raw_customer_state VARCHAR,
    source_file_name VARCHAR,
    load_timestamp TIMESTAMP
);

-- ---------------------------------
-- raw_ship_locations
-- Stores shipping location data as received
-- ---------------------------------
CREATE TABLE raw_ship_locations (
    raw_ship_location_id VARCHAR,
    raw_shipping_city VARCHAR,
    raw_shipping_state VARCHAR,
    raw_shipping_zip VARCHAR,
    raw_shipping_country VARCHAR,
    raw_shipping_region VARCHAR,
    source_file_name VARCHAR,
    load_timestamp TIMESTAMP
);

-- =========================================================
-- STAGING LAYER VIEWS
-- Cleaned / standardized views over raw tables
-- =========================================================
/*I used views instead of staging table because this is a clean and smart Version 1 design. Raw data stays untouched, staging logic is visible and reusable, you can inspect cleaned data anytime. Later I will convert staging views into staging tables for a more production-like pipeline*/

-- ---------------------------------
-- stg_orders
-- ---------------------------------
CREATE VIEW stg_orders AS
SELECT
    CAST(TRIM(raw_order_id) AS BIGINT)                  AS order_id,
    CAST(TRIM(raw_customer_id) AS BIGINT)               AS customer_id,
    CAST(TRIM(raw_order_date) AS DATE)                  AS order_date,
    UPPER(TRIM(raw_order_status))                     AS order_status,
    UPPER(TRIM(raw_payment_method))                   AS payment_method,
    CAST(TRIM(raw_total_order_amount) AS DECIMAL(12,2)) AS total_order_amount,
    CAST(TRIM(raw_ship_location_id) AS BIGINT)          AS ship_location_id,
    source_file_name,
    load_timestamp
FROM raw_orders;

-- ---------------------------------
-- stg_order_items
-- ---------------------------------
CREATE VIEW stg_order_items AS
SELECT
    CAST(TRIM(raw_order_line_id) AS BIGINT)                 AS order_line_id,
    CAST(TRIM(raw_order_id) AS BIGINT)                      AS order_id,
    CAST(TRIM(raw_product_id) AS BIGINT)                    AS product_id,
    CAST(TRIM(raw_quantity) AS INTEGER)                     AS quantity,
    CAST(TRIM(raw_price_per_unit) AS DECIMAL(12,2))         AS price_per_unit,
    CAST(TRIM(raw_total_line_amount) AS DECIMAL(12,2))      AS total_line_amount,
    source_file_name,
    load_timestamp
FROM raw_order_items;

-- ---------------------------------
-- stg_products
-- ---------------------------------
CREATE VIEW stg_products AS
SELECT
    CAST(TRIM(raw_product_id) AS BIGINT)                    AS product_id,
    TRIM(raw_product_name)                                  AS product_name,
    LOWER(TRIM(raw_category))                             AS category,
    TRIM(raw_brand)                                         AS brand,
    CAST(TRIM(raw_unit_price) AS DECIMAL(12,2))             AS unit_price,
    CASE
        WHEN LOWER(TRIM(raw_is_active)) IN ('true', '1', 'yes', 'y') THEN TRUE
        ELSE FALSE
    END                                                     AS is_active,
    source_file_name,
    load_timestamp
FROM raw_products;

-- ---------------------------------
-- stg_customers
-- ---------------------------------
CREATE VIEW stg_customers AS
SELECT
    CAST(TRIM(raw_customer_id) AS BIGINT)                   AS customer_id,
    TRIM(raw_customer_name)                                 AS customer_name,
    LOWER(TRIM(raw_email))                                  AS email,
    UPPER(TRIM(raw_loyalty_tier))                         AS loyalty_tier,
    UPPER(TRIM(raw_customer_state))                       AS customer_state,
    source_file_name,
    load_timestamp
FROM raw_customers;

-- ---------------------------------
-- stg_ship_locations
-- ---------------------------------
CREATE VIEW stg_ship_locations AS
SELECT
    CAST(TRIM(raw_ship_location_id) AS BIGINT)              AS ship_location_id,
    UPPER(TRIM(raw_shipping_city))                        AS shipping_city,
    UPPER(TRIM(raw_shipping_state))                       AS shipping_state,
    TRIM(raw_shipping_zip)                                  AS shipping_zip,
    UPPER(TRIM(raw_shipping_country))                       AS shipping_country,
    UPPER(TRIM(raw_shipping_region))                      AS shipping_region,
    source_file_name,
    load_timestamp
FROM raw_ship_locations;

-- =========================================================
-- WAREHOUSE DIMENSION TABLES
-- =========================================================

-- ---------------------------------
-- dim_order
-- One row per order
-- ---------------------------------
CREATE TABLE dim_order (
    order_id BIGINT PRIMARY KEY,
    customer_id BIGINT NOT NULL,
    order_date DATE NOT NULL,
    order_status VARCHAR,
    payment_method VARCHAR,
    total_order_amount DECIMAL(12,2)
);

-- ---------------------------------
-- dim_product
-- One row per product
-- ---------------------------------
CREATE TABLE dim_product (
    product_id BIGINT PRIMARY KEY,
    product_name VARCHAR NOT NULL,
    category VARCHAR,
    brand VARCHAR,
    unit_price DECIMAL(12,2),
    is_active BOOLEAN
);

-- ---------------------------------
-- dim_customer
-- One row per customer
-- ---------------------------------
CREATE TABLE dim_customer (
    customer_id BIGINT PRIMARY KEY,
    customer_name VARCHAR,
    email VARCHAR,
    loyalty_tier VARCHAR,
    customer_state VARCHAR
);

-- ---------------------------------
-- dim_ship_location
-- One row per shipping location
-- ---------------------------------
CREATE TABLE dim_ship_location (
    ship_location_id BIGINT PRIMARY KEY,
    shipping_city VARCHAR,
    shipping_state VARCHAR,
    shipping_zip VARCHAR,
    shipping_country VARCHAR,
    shipping_region VARCHAR
);

-- ---------------------------------
-- dim_date
-- One row per calendar date
-- date_key example: 20260421
-- ---------------------------------
CREATE TABLE dim_date (
    date_key BIGINT PRIMARY KEY,
    full_date DATE NOT NULL,
    day_of_week INTEGER,
    day_name VARCHAR,
    day_of_month INTEGER,
    month_number INTEGER,
    month_name VARCHAR,
    quarter_number INTEGER,
    year_number INTEGER,
    is_weekend BOOLEAN
);

-- =========================================================
-- WAREHOUSE FACT TABLE
-- =========================================================

-- ---------------------------------
-- fact_order_lines
-- One row per order line
-- ---------------------------------
CREATE TABLE fact_order_lines (
    order_line_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,
    ship_location_id BIGINT NOT NULL,
    date_key BIGINT NOT NULL,
    quantity INTEGER NOT NULL,
    price_per_unit DECIMAL(12,2) NOT NULL,
    total_line_amount DECIMAL(12,2) NOT NULL,

    FOREIGN KEY (order_id) REFERENCES dim_order(order_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    FOREIGN KEY (ship_location_id) REFERENCES dim_ship_location(ship_location_id),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);

-- =========================================================
-- SHOW TABLES
-- =========================================================
SELECT * FROM stg_orders;
SELECT * FROM stg_order_items;
SELECT * FROM stg_products;
SELECT * FROM stg_customers;
SELECT * FROM stg_ship_locations;
