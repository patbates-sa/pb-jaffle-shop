with
    customers as (select * from {{ ref("stg_jaffle_shop__customers") }}),
    orders as (select * from {{ ref("fct_orders") }}),
    customer_orders as (
        select
            customer_id,
            min(order_date) as first_order_date,
            max(order_date) as most_recent_order_date,
            cast(count(order_id) as number(18,0)) as number_of_orders,
            cast(sum(amount) as number(38,6)) as lifetime_value
        from orders
        group by 1
        order by 1
    ),
    final as (
        select
            customers.customer_id,
            customers.first_name,
            customers.last_name,
            customer_orders.first_order_date,
            customer_orders.most_recent_order_date,
            cast(coalesce(customer_orders.number_of_orders, 0) as number(18,0)) as number_of_orders,

            cast(customer_orders.lifetime_value as number(38,6)) as lifetime_value,
            cast(
                case
                    when customer_orders.first_order_date is null then 0
                    else coalesce(customer_orders.number_of_orders, 0)
                        / greatest(
                            datediff(month, customer_orders.first_order_date, customer_orders.most_recent_order_date) + 1,
                            1
                        )
                end as number(18,2)
            ) as average_monthly_orders
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
    lifetime_value,
    average_monthly_orders
from final
