/* ===============================
   Superstore SQL Analysis (SQLite)
   Table: sales
   =============================== */

-- 1) Sanity check
SELECT COUNT(*) AS rows_cnt FROM sales;

-- 2) Core KPIs
SELECT
  SUM(sales) AS total_sales,
  SUM(profit) AS total_profit,
  COUNT(DISTINCT order_id) AS total_orders,
  SUM(quantity) AS total_quantity,
  ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales),0), 2) AS profit_margin_pct
FROM sales;

-- 3) Sales & Profit by Category
SELECT
  category,
  ROUND(SUM(sales),2) AS total_sales,
  ROUND(SUM(profit),2) AS total_profit
FROM sales
GROUP BY category
ORDER BY total_sales DESC;

-- 4) Sales by Month (YYYY-MM)
SELECT
  substr(order_date,1,7) AS month,
  ROUND(SUM(sales),2) AS monthly_sales,
  ROUND(SUM(profit),2) AS monthly_profit
FROM sales
GROUP BY month
ORDER BY month;

-- 5) Sales by Region
SELECT
  region,
  ROUND(SUM(sales),2) AS total_sales,
  ROUND(SUM(profit),2) AS total_profit
FROM sales
GROUP BY region
ORDER BY total_sales DESC;

-- 6) Avg shipping days by ship mode
SELECT
  ship_mode,
  ROUND(AVG(julianday(ship_date) - julianday(order_date)),2) AS avg_shipping_days
FROM sales
GROUP BY ship_mode;

-- 7) Discount buckets (CTE)
WITH discount_buckets AS (
  SELECT
    CASE
      WHEN discount = 0 THEN '0%'
      WHEN discount <= 0.10 THEN '0-10%'
      WHEN discount <= 0.20 THEN '10-20%'
      WHEN discount <= 0.30 THEN '20-30%'
      ELSE '30%+'
    END AS bucket,
    sales,
    profit
  FROM sales
)
SELECT
  bucket,
  ROUND(SUM(sales),2)  AS total_sales,
  ROUND(SUM(profit),2) AS total_profit,
  ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales),0), 2) AS margin_pct
FROM discount_buckets
GROUP BY bucket
ORDER BY
  CASE bucket
    WHEN '0%' THEN 1
    WHEN '0-10%' THEN 2
    WHEN '10-20%' THEN 3
    WHEN '20-30%' THEN 4
    ELSE 5
  END;

-- 8) Loss-making products (profit < 0)
SELECT
  product_name,
  ROUND(SUM(sales),2) AS sales,
  ROUND(SUM(profit),2) AS profit
FROM sales
GROUP BY product_name
HAVING SUM(profit) < 0
ORDER BY profit ASC;

-- 9) Window function: ranking products within category
WITH prod AS (
  SELECT
    category,
    product_name,
    SUM(sales) AS sales
  FROM sales
  GROUP BY category, product_name
)
SELECT
  category,
  product_name,
  ROUND(sales,2) AS sales,
  DENSE_RANK() OVER (PARTITION BY category ORDER BY sales DESC) AS rank_in_category
FROM prod
ORDER BY category, rank_in_category;
