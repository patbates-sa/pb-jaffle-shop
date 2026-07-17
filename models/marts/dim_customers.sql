with
    customers as (select * from {{ ref("stg_jaffle_shop__customers") }}),
    orders as (
        select
            customer_id,
            order_date,
            order_id,
            amount
        from {{ ref("fct_orders") }}),
    customer_orders as (
        select
            customer_id,
            min(order_date) as first_order_date,
            max(order_date) as most_recent_order_date,
            cast(count(order_id) as number(18,0)) as number_of_orders,
            cast(sum(amount) as number(38,6)) as lifetime_value
        from orders
        group by customer
  
    ),
    final as (
        select
            customers.customer_id,
            customers.first_name,
            customers.last_name,
            customer_orders.first_order_date,
            customer_orders.most_recent_order_date,
            cast(coalesce(customer_orders.number_of_orders, 0) as number(18,0)) as number_of_orders,
            cast(
                case
                    when customer_orders.first_order_date is null then null
                    else customer_orders.number_of_orders::float
                    / nullif(
                        datediff(
                            month,
                            customer_orders.first_order_date,
                            customer_orders.most_recent_order_date
                        ) + 1,
                        0
                    )
                end as number(38,6)
            ) as average_monthly_orders,
            cast(
                case
                    when customer_orders.first_order_date is null then null
                    else customer_orders.number_of_orders::float
                    / nullif(
                        datediff(
                            month,
                            customer_orders.first_order_date,
                            customer_orders.most_recent_order_date
                        ) + 1,
                        0
                    )
                end as number(38,6)
            ) as max_monthly_orders,
            cast(customer_orders.lifetime_value as number(38,6)) as lifetime_value
        from customers
        left join customer_orders using (customer_id)
    )
select
    customer_id,
    first_name,
    last_name,
    first_order_date,
    most_recent_order_date,
    number_of_orders,
    average_monthly_orders,
    max_monthly_orders,
    lifetime_value
from final
