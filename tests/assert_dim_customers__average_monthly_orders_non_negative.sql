-- KAN-8: assert that average_monthly_orders has no negative values
select
    customer_id,
    average_monthly_orders
from {{ ref('dim_customers') }}
where average_monthly_orders < 0
