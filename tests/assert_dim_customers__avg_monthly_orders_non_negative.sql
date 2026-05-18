-- KAN-12: avg_monthly_orders should never be negative
select
    customer_id,
    avg_monthly_orders
from {{ ref('dim_customers') }}
where avg_monthly_orders < 0
