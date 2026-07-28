-- DBT-19: fail if any customer has a negative avg_monthly_orders value
select
    customer_id,
    avg_monthly_orders
from {{ ref('dim_customers') }}
where avg_monthly_orders < 0
