WITH dim_customers AS (
  SELECT
    *
  FROM {{ ref('pb_jaffle_shop', 'dim_customers') }}
), fct_orders AS (
  SELECT
    *
  FROM {{ ref('pb_jaffle_shop', 'fct_orders') }}
), join_1 AS (
  SELECT
    *
  FROM dim_customers
  JOIN fct_orders
    USING (CUSTOMER_ID)
), cust_fact_sql AS (
  SELECT
    *
  FROM join_1
)
SELECT
*
FROM cust_fact_sql