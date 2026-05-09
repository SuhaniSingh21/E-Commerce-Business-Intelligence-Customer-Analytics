-- Created and selected the database
CREATE DATABASE IF NOT EXISTS Ecommerce_Analytics_1;
USE Ecommerce_Analytics_1;

-- 1. Date Dimension (Time Intelligence)
CREATE TABLE Date_Dimension (
    date_key INT PRIMARY KEY,
    full_date VARCHAR(20),
    day_of_week VARCHAR(15),
    month_name VARCHAR(15),
    year INT,
    quarter VARCHAR(5),
    season VARCHAR(20),
    is_holiday VARCHAR(10)
);

-- 2. Categories
CREATE TABLE Categories (
    category_id VARCHAR(10) PRIMARY KEY,
    category_name VARCHAR(100),
    parent_category VARCHAR(100)
);

-- 3. Customers
CREATE TABLE Customers (
    customer_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(150),
    gender VARCHAR(10),
    city VARCHAR(50),
    state VARCHAR(50),
    registration_date VARCHAR(20), -- Will convert to DATE after import
    acquisition_channel VARCHAR(50),
    customer_segment VARCHAR(20)
);

-- 4. Products
CREATE TABLE Products (
    product_id VARCHAR(10) PRIMARY KEY,
    product_name VARCHAR(200),
    category_id VARCHAR(10),
    brand VARCHAR(100),
    unit_cost DECIMAL(10, 2),
    unit_price DECIMAL(10, 2),
    stock_quantity INT,
    is_active VARCHAR(10),
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- 5. Orders
CREATE TABLE Orders (
    order_id VARCHAR(10) PRIMARY KEY,
    customer_id VARCHAR(10),
    date_key INT,
    total_order_amount DECIMAL(10, 2),
    order_status VARCHAR(20),
    payment_status VARCHAR(20),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (date_key) REFERENCES Date_Dimension(date_key)
);

-- 6. Order Items (Transactional Detail)
CREATE TABLE Order_Items (
    order_item_id VARCHAR(15) PRIMARY KEY,
    order_id VARCHAR(10),
    product_id VARCHAR(10),
    quantity INT,
    item_price_at_sale DECIMAL(10, 2),
    item_discount_amount DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

SET SQL_SAFE_UPDATES = 0;
-- Converted string dates to MySQL DATE format (YYYY-MM-DD) --
UPDATE Customers SET registration_date = STR_TO_DATE(registration_date, '%d-%m-%Y');
ALTER TABLE Customers MODIFY registration_date DATE;

UPDATE Date_Dimension SET full_date = STR_TO_DATE(full_date, '%d-%m-%Y');
ALTER TABLE Date_Dimension MODIFY full_date DATE;

SET SQL_SAFE_UPDATES = 1;

-- Main Queries--

-- 1.) YoY Revenue Growth and Market Share --
WITH Yearly_Sales AS (
    SELECT 
        d.year,
        c.parent_category,
        SUM(o.total_order_amount) as category_revenue
    FROM Orders o
    JOIN Date_Dimension d ON o.date_key = d.date_key
    JOIN Order_Items oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    JOIN Categories c ON p.category_id = c.category_id
    WHERE o.order_status = 'Completed'
    GROUP BY 1, 2
)
SELECT 
    year,
    parent_category,
    category_revenue,
    SUM(category_revenue) OVER(PARTITION BY year) as total_year_revenue,
    (category_revenue / SUM(category_revenue) OVER(PARTITION BY year)) * 100 as market_share_pct
FROM Yearly_Sales;

-- 2.) RFM Segmentation --
WITH RFM_Base AS (
    SELECT 
        customer_id,
        MAX(date_key) as last_order,
        COUNT(order_id) as freq,
        SUM(total_order_amount) as mon
    FROM Orders WHERE order_status = 'Completed'
    GROUP BY 1
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER(ORDER BY last_order) as r,
        NTILE(5) OVER(ORDER BY freq) as f,
        NTILE(5) OVER(ORDER BY mon) as m
    FROM RFM_Base
)
SELECT *,
    CASE WHEN r >= 4 AND f >= 4 THEN 'Champions'
         WHEN r <= 2 THEN 'At Risk'
         ELSE 'Regular' END as Segment
FROM RFM_Scores;

-- 3.) Behavioral Velocity (Time-to-Second-Purchase) --
WITH Second_Order AS (
    SELECT 
        customer_id,
        date_key,
        LAG(date_key) OVER(PARTITION BY customer_id ORDER BY date_key) as prev_date,
        ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY date_key) as rn
    FROM Orders WHERE order_status = 'Completed'
)
SELECT 
    AVG(date_key - prev_date) as avg_days_to_return
FROM Second_Order WHERE rn = 2;

-- 4.) Market Basket Analysis (The "Human Choice")
-- The Business Goal: What are the most common pairs of products bought together?
SELECT 
    p1.product_name AS product_a, 
    p2.product_name AS product_b, 
    COUNT(*) AS times_bought_together
FROM Order_Items oi1
JOIN Order_Items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN Products p1 ON oi1.product_id = p1.product_id
JOIN Products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.product_name, p2.product_name
ORDER BY times_bought_together DESC
LIMIT 5;
-- 5.) Month-over-Month (MoM) Revenue Growth --
-- Goal: Track if the business is growing or shrinking month-to-month.
SELECT 
    d.year, 
    d.month_name, 
    SUM(o.total_order_amount) AS current_month_revenue,
    LAG(SUM(o.total_order_amount)) OVER (ORDER BY d.year, MIN(d.date_key)) AS previous_month_revenue,
    ((SUM(o.total_order_amount) - LAG(SUM(o.total_order_amount)) OVER (ORDER BY d.year, MIN(d.date_key))) / 
    LAG(SUM(o.total_order_amount)) OVER (ORDER BY d.year, MIN(d.date_key))) * 100 AS mom_growth_pct
FROM Orders o
JOIN Date_Dimension d ON o.date_key = d.date_key
WHERE o.order_status = 'Completed'
GROUP BY d.year, d.month_name;
-- 6.) High-Discount vs. Profitability AnalysisGoal:
-- Does a discount $> 15\%$ actually help, or are we just losing money?

SELECT 
    CASE WHEN item_discount_amount > (item_price_at_sale * 0.15) THEN 'High Discount (>15%)'
         ELSE 'Low/No Discount' END AS discount_tier,
    COUNT(order_id) AS total_orders,
    AVG(quantity) AS avg_items_per_order,
    SUM((item_price_at_sale - item_discount_amount) * quantity) AS net_revenue
FROM Order_Items
GROUP BY 1;
-- 7.) Peak Season by Category
-- Goal: Find out when each category (like "Winter Wear") actually peaks.

WITH Category_Monthly_Sales AS (
    SELECT 
        c.parent_category,
        d.month_name,
        SUM(oi.quantity) AS total_units,
        RANK() OVER (PARTITION BY c.parent_category ORDER BY SUM(oi.quantity) DESC) AS sales_rank
    FROM Order_Items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN Products p ON oi.product_id = p.product_id
    JOIN Categories c ON p.category_id = c.category_id
    JOIN Date_Dimension d ON o.date_key = d.date_key
    GROUP BY c.parent_category,d.month_name
)
SELECT parent_category, month_name, total_units
FROM Category_Monthly_Sales
WHERE sales_rank = 1;
-- 8.) CLV by Acquisition Channel
-- Goal: Which channel (Google Ads, Referral, etc.) brings in the biggest spenders?
SELECT 
    c.acquisition_channel,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    SUM(o.total_order_amount) AS total_revenue,
    SUM(o.total_order_amount) / COUNT(DISTINCT c.customer_id) AS avg_lifetime_value
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'Completed'
GROUP BY 1
ORDER BY 4 DESC;

-- 9.) "At-Risk" High Spenders (Churn Prevention)
-- Goal: Find customers who spent a lot in the past but haven't bought anything recently.
SELECT 
    c.name,
    c.email,
    MAX(d.full_date) AS last_purchase_date,
    SUM(o.total_order_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Date_Dimension d ON o.date_key = d.date_key
WHERE c.customer_segment = 'VIP' 
GROUP BY c.customer_id
HAVING MAX(d.full_date) < '2024-06-01' -- Change date based on your latest data
ORDER BY total_spent DESC;

-- 10.) Return Rate & Brand Reputation
-- Goal: Is a specific brand causing all our returns?
SELECT 
    p.brand,
    COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) AS total_returns,
    COUNT(o.order_id) AS total_orders,
    (COUNT(CASE WHEN o.order_status = 'Returned' THEN 1 END) / COUNT(o.order_id)) * 100 AS return_rate_pct
FROM Products p
JOIN Order_Items oi ON p.product_id = oi.product_id
JOIN Orders o ON oi.order_id = o.order_id
GROUP BY 1
HAVING total_orders > 10
ORDER BY return_rate_pct DESC;

-- 11.) Geographic Expansion Strategy
-- Goal: Where should we open our next physical store?
SELECT 
    city, 
    state, 
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(total_order_amount) AS total_revenue,
    -- This calculates the average spend per person in that city
    ROUND(SUM(total_order_amount) / COUNT(DISTINCT customer_id), 2) AS avg_revenue_per_customer
FROM Customers
JOIN Orders USING (customer_id)
WHERE order_status = 'Completed'
-- We include BOTH city and state to keep MySQL happy
GROUP BY city, state
HAVING total_customers > 5
ORDER BY avg_revenue_per_customer DESC
LIMIT 10;

-- 12.) Holiday vs. Non-Holiday Performance
-- The Business Goal: Does the "Holiday" tag actually drive more expensive orders?
SELECT 
    d.is_holiday,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(o.total_order_amount), 2) AS average_order_value,
    SUM(o.total_order_amount) AS total_revenue
FROM Orders o
JOIN Date_Dimension d ON o.date_key = d.date_key
GROUP BY d.is_holiday;

-- 13.) Discount Impact on Profitability
-- The Business Goal: Are big discounts (over 15%) killing our profits or helping us sell more?
SELECT 
    CASE 
        WHEN item_discount_amount > (item_price_at_sale * 0.15) THEN 'Deep Discount (>15%)'
        WHEN item_discount_amount > 0 THEN 'Small Discount'
        ELSE 'Full Price'
    END AS pricing_strategy,
    COUNT(*) AS units_sold,
    ROUND(AVG(item_price_at_sale - item_discount_amount), 2) AS avg_net_price
FROM Order_Items
GROUP BY 1;
-- 14.) Return Rate by Category
-- The Business Goal: Which product categories are most likely to be returned? (Useful for finding quality issues).
SELECT 
    c.parent_category,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS total_returns,
    ROUND(SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) / COUNT(o.order_id) * 100, 2) AS return_rate_pct
FROM Orders o
JOIN Order_Items oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
JOIN Categories c ON p.category_id = c.category_id
GROUP BY c.parent_category
ORDER BY return_rate_pct DESC;

-- 15.) Brand Loyalty (Repeat Brand Buyers)
-- The Business Goal: Which brand has the most "fans" (customers who bought from the same brand more than once)?
SELECT 
    p.brand, 
    COUNT(o.order_id) AS total_purchases,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    -- Ratio of purchases to customers (higher means more repeat buying)
    ROUND(COUNT(o.order_id) / COUNT(DISTINCT o.customer_id), 2) AS loyalty_score
FROM Order_Items oi
JOIN Products p ON oi.product_id = p.product_id
JOIN Orders o ON oi.order_id = o.order_id
GROUP BY p.brand
HAVING unique_customers > 5
ORDER BY loyalty_score DESC;



