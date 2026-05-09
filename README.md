**E-Commerce Business Intelligence & Customer Analytics**
# Overview
Modern e-commerce generates massive volumes of transactional and behavioral data. This project builds a complete Relational Database System and executes 15 advanced analytical SQL queries on real-world simulated e-commerce data to help businesses understand customer behavior, identify market trends, and improve strategic decision-making.
# Business Problems Addressed
Are aggressive discounts eroding profit margins?
Which geographic locations are viable for physical store expansion?
How can we prevent high-value (VIP) customer churn?
Which acquisition channels bring the highest customer lifetime value?
What product pairs are most frequently bought together?

# Database Architecture
The database follows a Star Schema design for optimized query performance and data integrity.
                        ┌─────────────────┐
                        │   ORDER_ITEMS   │
                        │   (Fact Table)  │
                        └────────┬────────┘
           ┌────────────┬────────┼────────┬────────────┐
           ▼            ▼        ▼        ▼            ▼
       ORDERS       PRODUCTS  CUSTOMERS  CATEGORIES  DATE_DIMENSION
  order_id        product_id  customer_id  category_id  date_key
  customer_id     category_id  city        parent_cat   year
  date_key        brand        segment                  month
  status          unit_price   channel                  quarter

# Tables
TableDescriptionDate_DimensionTime intelligence — date, month, quarter, season, holiday flagCategoriesProduct categories with parent-child hierarchyCustomersCustomer profiles — demographics, segment, acquisition channelProductsProduct catalog — pricing, stock, brand, categoryOrdersOrder-level records — status, payment, total amountOrder_ItemsLine-item transactions — quantity, price, discount

# Analytical Queries
Revenue Analytics
#QueryBusiness Goal1YoY Revenue Growth & Market ShareTrack revenue trend and category share year-over-year5Month-over-Month (MoM) Revenue GrowthIdentify if the business is growing or declining monthly12Holiday vs. Non-Holiday PerformanceMeasure the true impact of holiday tags on order value
Customer Analytics
#QueryBusiness Goal2RFM SegmentationClassify customers as Champions, At-Risk, or Regular3Behavioral Velocity (Time-to-Second-Purchase)Measure how quickly customers return after the first order8CLV by Acquisition ChannelIdentify which channels bring the highest lifetime-value customers9At-Risk High Spenders (Churn Prevention)Find VIP customers who haven't purchased recently15Brand Loyalty (Repeat Brand Buyers)Discover which brands have the most loyal fan base
Profitability & Operations
#QueryBusiness Goal6High-Discount vs. ProfitabilityDetermine if discounts >15% help or hurt revenue13Discount Impact on ProfitabilityCompare net pricing across full price, small, and deep discount tiers10Return Rate & Brand ReputationIdentify which brands drive the most returns14Return Rate by CategoryFind product categories with quality or satisfaction issues
Market & Geographic Intelligence
#QueryBusiness Goal4Market Basket AnalysisFind the most frequently co-purchased product pairs7Peak Season by CategoryDiscover when each category peaks for targeted campaigns11Geographic Expansion StrategyIdentify top cities by revenue per customer for store expansion

# SQL Techniques Used

Common Table Expressions (CTEs) — WITH clause for readable, multi-step logic (RFM, YoY, MoM, Basket Analysis)
Window Functions — RANK(), LAG(), NTILE(5), ROW_NUMBER(), PARTITION BY
Aggregate Functions — SUM(), COUNT(), AVG(), ROUND(), HAVING
Joins — INNER JOIN across 5+ tables, Self-Join for market basket, USING shorthand
Conditional Logic — CASE WHEN for discount tiers, RFM labels, pricing strategy
Date Functions — STR_TO_DATE() for data type conversion


# Project Structure
ecommerce-sql-analytics/
│
├── sql_ecommerce_project_suhani_.sql   # Main SQL script (schema + all 15 queries)
├── SQL_Ecommerce_ppt_Suhani_Singh.pptx # Project presentation
├── PowerBIproject_Dashboard.pbix       # Power BI dashboard
└── README.md
