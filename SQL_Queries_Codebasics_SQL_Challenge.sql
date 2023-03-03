# Codebasics_SQL_Challenge

# Request 1: Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

# Query:

SELECT 
  DISTINCT(market) 
FROM 
  dim_customer 
WHERE 
  customer = "Atliq Exclusive" 
  AND region = "APAC";
  
# Output:

+-------------+
| market      |
+-------------+
| India       |
| Indonesia   |
| Japan       |
| Philiphines |
| South Korea |
| Australia   |
| Newzealand  |
| Bangladesh  |
+-------------+

# Request 2: What is the percentage of unique product increase in 2021 vs 2020?

# Query:

WITH uniq_prod_in_2020 AS (
  SELECT 
    count(
      DISTINCT(product_code)
    ) AS unique_products_2020 
  FROM 
    fact_sales_monthly 
  WHERE 
    fiscal_year = 2020
), 
uniq_prod_in_2021 AS (
  SELECT 
    count(
      DISTINCT(product_code)
    ) AS unique_products_2021 
  FROM 
    fact_sales_monthly 
  WHERE 
    fiscal_year = 2021
) 
SELECT 
  unique_products_2020, 
  unique_products_2021, 
  round(
    (
      unique_products_2021 - unique_products_2020
    )* 100 / unique_products_2020, 
    2
  ) AS percentage_change 
FROM 
  uniq_prod_in_2020 CROSS 
  JOIN uniq_prod_in_2021;


# Output:

+----------------------+----------------------+-------------------+
| unique_products_2020 | unique_products_2021 | percentage_change |
+----------------------+----------------------+-------------------+
|                  245 |                  334 |             36.33 |
+----------------------+----------------------+-------------------+

# Request 3: Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.

# Query:

SELECT 
  segment, 
  count(
    DISTINCT(product_code)
  ) AS product_count 
FROM 
  dim_product 
GROUP BY 
  segment 
ORDER BY 
  product_count DESC;
  
# Output: 

+-------------+---------------+
| segment     | product_count |
+-------------+---------------+
| Notebook    |           129 |
| Accessories |           116 |
| Peripherals |            84 |
| Desktop     |            32 |
| Storage     |            27 |
| Networking  |             9 |
+-------------+---------------+

# Request 4: Which segment had the most increase in unique products in 2021 vs 2020?

# Query:

WITH uniq_prod_count_2020 AS (
  SELECT 
    p.segment, 
    COUNT(
      DISTINCT(p.product_code)
    ) AS product_count_2020, 
    fiscal_year 
  FROM 
    dim_product p 
    JOIN fact_sales_monthly s USING (product_code) 
  WHERE 
    fiscal_year = 2020 
  GROUP BY 
    segment
), 
uniq_prod_count_2021 AS (
  SELECT 
    p.segment, 
    COUNT(
      DISTINCT(p.product_code)
    ) AS product_count_2021, 
    fiscal_year 
  FROM 
    dim_product p 
    JOIN fact_sales_monthly s USING (product_code) 
  WHERE 
    fiscal_year = 2021 
  GROUP BY 
    segment
) 
SELECT 
  segment, 
  product_count_2020, 
  product_count_2021, 
  product_count_2021 - product_count_2020 AS difference 
from 
  uniq_prod_count_2020 
  JOIN uniq_prod_count_2021 USING (segment) 
GROUP BY 
  segment 
ORDER BY 
  difference DESC;
  
# Output:

+-------------+--------------------+--------------------+------------+
| segment     | product_count_2020 | product_count_2021 | difference |
+-------------+--------------------+--------------------+------------+
| Accessories |                 69 |                103 |         34 |
| Notebook    |                 92 |                108 |         16 |
| Peripherals |                 59 |                 75 |         16 |
| Desktop     |                  7 |                 22 |         15 |
| Storage     |                 12 |                 17 |          5 |
| Networking  |                  6 |                  9 |          3 |
+-------------+--------------------+--------------------+------------+

# Request 5: Get the products that have the highest and lowest manufacturing costs.

# Query:

SELECT 
  p.product_code, 
  concat(p.product, " (", p.variant, ")") AS product, 
  m.manufacturing_cost 
FROM 
  dim_product p 
  JOIN fact_manufacturing_cost m USING (product_code) 
WHERE 
  manufacturing_cost =(
    SELECT 
      max(manufacturing_cost) 
    FROM 
      fact_manufacturing_cost
  ) 
  OR manufacturing_cost =(
    SELECT 
      min(manufacturing_cost) 
    FROM 
      fact_manufacturing_cost
  ) 
ORDER BY 
  manufacturing_cost DESC;

# Output: 

+--------------+------------------------------------+--------------------+
| product_code | product                            | manufacturing_cost |
+--------------+------------------------------------+--------------------+
| A6120110206  | AQ HOME Allin1 Gen 2 (Plus 3)      |           240.5364 |
| A2118150101  | AQ Master wired x1 Ms (Standard 1) |             0.8920 |
+--------------+------------------------------------+--------------------+ 

# Request 6: Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.

# Query:

SELECT 
  c.customer_code, 
  c.customer, 
  d.fiscal_year, 
  round(
    avg(d.pre_invoice_discount_pct), 
    4
  ) AS average_discount_percentage 
FROM 
  fact_pre_invoice_deductions d 
  JOIN dim_customer c using (customer_code) 
WHERE 
  fiscal_year = 2021 
  AND market = "India" 
GROUP BY 
  d.fiscal_year, 
  c.customer_code, 
  c.customer 
ORDER BY 
  average_discount_percentage DESC 
LIMIT 
  5;

# Output:

+---------------+----------+-------------+-----------------------------+
| customer_code | customer | fiscal_year | average_discount_percentage |
+---------------+----------+-------------+-----------------------------+
|      90002009 | Flipkart |        2021 |                      0.3083 |
|      90002006 | Viveks   |        2021 |                      0.3038 |
|      90002003 | Ezone    |        2021 |                      0.3028 |
|      90002002 | Croma    |        2021 |                      0.3025 |
|      90002016 | Amazon   |        2021 |                      0.2933 |
+---------------+----------+-------------+-----------------------------+

# Request 7: Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.

# Query:

SELECT 
  MONTHNAME(s.date) AS MONTH, 
  s.fiscal_year, 
  ROUND(
    SUM(g.gross_price * s.sold_quantity), 
    2
  ) AS gross_sales_amount 
FROM 
  dim_customer c 
  JOIN fact_sales_monthly s ON c.customer_code = s.customer_code 
  JOIN fact_gross_price g ON s.product_code = g.product_code 
WHERE 
  c.customer = "Atliq Exclusive" 
GROUP BY 
  MONTHNAME(s.date), 
  fiscal_year 
ORDER BY 
  s.fiscal_year;

# Output:

+-----------+-------------+--------------------+
| MONTH     | fiscal_year | gross_sales_amount |
+-----------+-------------+--------------------+
| September |        2020 |         9092670.34 |
| October   |        2020 |        10378637.60 |
| November  |        2020 |        15231894.97 |
| December  |        2020 |         9755795.06 |
| January   |        2020 |         9584951.94 |
| February  |        2020 |         8083995.55 |
| March     |        2020 |          766976.45 |
| April     |        2020 |          800071.95 |
| May       |        2020 |         1586964.48 |
| June      |        2020 |         3429736.57 |
| July      |        2020 |         5151815.40 |
| August    |        2020 |         5638281.83 |
| September |        2021 |        19530271.30 |
| October   |        2021 |        21016218.21 |
| November  |        2021 |        32247289.79 |
| December  |        2021 |        20409063.18 |
| January   |        2021 |        19570701.71 |
| February  |        2021 |        15986603.89 |
| March     |        2021 |        19149624.92 |
| April     |        2021 |        11483530.30 |
| May       |        2021 |        19204309.41 |
| June      |        2021 |        15457579.66 |
| July      |        2021 |        19044968.82 |
| August    |        2021 |        11324548.34 |
+-----------+-------------+--------------------+

# Request 8: In which quarter of 2020, got the maximum total_sold_quantity?

# Query: 

SELECT 
  CASE WHEN MONTH(date) IN (9, 10, 11) THEN "Q1" WHEN MONTH(date) IN (12, 1, 2) THEN "Q2" WHEN MONTH(date) IN (3, 4, 5) THEN "Q3" ELSE "Q4" END AS quarter, 
  SUM(sold_quantity) AS total_sold_quantity 
FROM 
  fact_sales_monthly 
WHERE 
  fiscal_year = 2020 
GROUP BY 
  quarter 
ORDER BY 
  total_sold_quantity DESC;
  
# Output:

+---------+---------------------+
| quarter | total_sold_quantity |
+---------+---------------------+
| Q1      |             7005619 |
| Q2      |             6649642 |
| Q4      |             5042541 |
| Q3      |             2075087 |
+---------+---------------------+

# Request 9: Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?

# Query: 

WITH gross_sales_per_channel AS (
  SELECT 
    c.channel, 
    ROUND(
      SUM(g.gross_price * sold_quantity)/ 1000000, 
      2
    ) as gross_sales_mln 
  FROM 
    dim_customer c 
    JOIN fact_sales_monthly s ON c.customer_code = s.customer_code 
    JOIN fact_gross_price g ON s.product_code = g.product_code 
  WHERE 
    s.fiscal_year = 2021 
  GROUP BY 
    c.channel
) 
SELECT 
  gross_sales_per_channel.*, 
  ROUND(
    gross_sales_mln * 100 / SUM(gross_sales_mln) OVER(), 
    2
  ) AS percentage 
FROM 
  gross_sales_per_channel 
ORDER BY 
  percentage DESC;
  
# Output:

+-------------+-----------------+------------+
| channel     | gross_sales_mln | percentage |
+-------------+-----------------+------------+
| Retailer    |         1924.17 |      73.22 |
| Direct      |          406.69 |      15.48 |
| Distributor |          297.18 |      11.31 |
+-------------+-----------------+------------+

# Request 10: Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

Query: 

WITH sold_quant_by_product_division AS (
  SELECT 
    p.division, 
    p.product_code, 
    concat(p.product, " (", p.variant, ")") AS product, 
    SUM(s.sold_quantity) total_sold_quantity 
  FROM 
    fact_sales_monthly s 
    JOIN dim_product p ON s.product_code = p.product_code 
  WHERE 
    fiscal_year = 2021 
  GROUP BY 
    p.division, 
    p.product_code, 
    concat(p.product, " (", p.variant, ")")
), 
prod_rank_by_sold_quant AS (
  SELECT 
    *, 
    DENSE_RANK() OVER (
      PARTITION BY division 
      ORDER BY 
        total_sold_quantity DESC
    ) AS rank_order 
  FROM 
    sold_quant_by_product_division
) 
SELECT 
  * 
FROM 
  prod_rank_by_sold_quant 
WHERE 
  rank_order <= 3;
  
# Output:

+----------+--------------+--------------------------------+---------------------+------------+
| division | product_code | product                        | total_sold_quantity | rank_order |
+----------+--------------+--------------------------------+---------------------+------------+
| N & S    | A6720160103  | AQ Pen Drive 2 IN 1 (Premium)  |              701373 |          1 |
| N & S    | A6818160202  | AQ Pen Drive DRC (Plus)        |              688003 |          2 |
| N & S    | A6819160203  | AQ Pen Drive DRC (Premium)     |              676245 |          3 |
| P & A    | A2319150302  | AQ Gamers Ms (Standard 2)      |              428498 |          1 |
| P & A    | A2520150501  | AQ Maxima Ms (Standard 1)      |              419865 |          2 |
| P & A    | A2520150504  | AQ Maxima Ms (Plus 2)          |              419471 |          3 |
| PC       | A4218110202  | AQ Digit (Standard Blue)       |               17434 |          1 |
| PC       | A4319110306  | AQ Velocity (Plus Red)         |               17280 |          2 |
| PC       | A4218110208  | AQ Digit (Premium Misty Green) |               17275 |          3 |
+----------+--------------+--------------------------------+---------------------+------------+





