# Gym Store End-to-End Data Engineering Pipeline

This project simulates a real-world Data Engineering pipeline for a gym product store.

## Pipeline Flow

Raw Data → Staging Views → Dimension Tables → Fact Table → Data Quality Checks → Power BI Dashboard

## Tools Used

- SQL
- DuckDB / MotherDuck
- VS Code
- GitHub
- Power BI

## What I Built

### 1. Raw Layer
The raw layer stores incoming source data exactly as received. I used VARCHAR columns to prevent the load from failing when source data is messy.

### 2. Staging Layer
The staging layer cleans and standardizes the raw data using SQL views. This includes trimming spaces, changing case, converting data types, and preparing data for warehouse tables.

### 3. Warehouse Layer
The warehouse uses a star schema design with dimension tables and a fact table.

Dimension tables:
- dim_order
- dim_product
- dim_customer
- dim_ship_location
- dim_date

Fact table:
- fact_order_lines

### 4. Data Quality
The project includes checks for missing keys, invalid quantities, negative prices, and orphan records.

## Goal

The goal of this project is to practice real Data Engineering concepts including raw ingestion, transformation, data modeling, warehouse design, and analytics preparation.
