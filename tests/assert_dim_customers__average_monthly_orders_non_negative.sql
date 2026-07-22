-- DBT-18: fail if any customer has a negative average_monthly_orders value
select
    customer_id,
    average_monthly_orders
from {{ ref('dim_customers') }}
where average_monthly_orders < 0
