# E-Commerce Business Intelligence & Customer Analytics
Data Management Using SQL | MySQL Workbench

# Overview
Built a complete relational database system on 40,000+ records of simulated e-commerce data, designed around a Star Schema with 6 tables. Executed 15 advanced analytical SQL queries to answer real business questions around revenue, customer behavior, profitability, and market expansion.

# Business Problems Addressed

Are aggressive discounts eroding profit margins?
Which cities are viable for physical store expansion?
How can we prevent high-value (VIP) customer churn?
Which acquisition channels bring the highest lifetime value?
What product pairs are most frequently bought together?


# Database Schema
Six tables: Date_Dimension, Categories, Customers, Products, Orders, Order_Items (fact table) — linked via foreign key constraints following a Star Schema design.

Analytical Queries
#QueryCategory1YoY Revenue Growth & Market ShareRevenue2RFM Customer SegmentationCustomer3Behavioral Velocity (Time-to-Second-Purchase)Customer4Market Basket AnalysisMarket Intelligence5Month-over-Month Revenue GrowthRevenue6High-Discount vs. ProfitabilityProfitability7Peak Season by CategoryMarket Intelligence8CLV by Acquisition ChannelCustomer9At-Risk High Spenders (Churn Prevention)Customer10Return Rate & Brand ReputationOperations11Geographic Expansion StrategyMarket Intelligence12Holiday vs. Non-Holiday PerformanceRevenue13Discount Impact on ProfitabilityProfitability14Return Rate by CategoryOperations15Brand Loyalty (Repeat Brand Buyers)Customer

# SQL Techniques Used
CTEs, Window Functions (RANK, LAG, NTILE, ROW_NUMBER), Aggregate Functions, Multi-table Joins & Self-Joins, CASE WHEN conditional logic, STR_TO_DATE for data cleaning, PARTITION BY for group-level analysis.

# Tools
MySQL 8.0 · MySQL Workbench · Power BI

# How to Run

Open sql_ecommerce_project_suhani_.sql in MySQL Workbench
Import your CSV data into the respective tables
Run the script — it creates the schema, converts date formats, and executes all 15 queries
