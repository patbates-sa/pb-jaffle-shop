SELECT
    customer_id,
    first_name || ' ' || last_name AS customer_name,
    number_of_orders
FROM {{ ref('pb_jaffle_shop', 'dim_customers') }}
