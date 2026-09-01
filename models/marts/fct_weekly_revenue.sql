{{ config(materialized='table') }}

with calendar as (

    select
        date_day,
        is_trading_day,
        is_early_close,
        holiday_name,
        date_trunc('week', date_day) as week_start
    from {{ ref('dim_business_calendar') }}

),

daily_revenue as (

    select
        order_date,
        sum(amount) as revenue,
        count(*) as order_count
    from {{ ref('fct_orders') }}
    group by 1

),

-- Left join FROM the calendar, not from the orders. A closed day has no
-- orders at all, so joining the other way would drop it silently and the
-- trading-day count would never notice it was missing.
joined as (

    select
        c.week_start,
        c.date_day,
        c.is_trading_day,
        c.is_early_close,
        c.holiday_name,
        coalesce(r.revenue, 0) as revenue,
        coalesce(r.order_count, 0) as order_count
    from calendar c
    left join daily_revenue r
        on c.date_day = r.order_date
    where c.date_day between
        (select min(order_date) from daily_revenue)
        and (select max(order_date) from daily_revenue)

)

select
    week_start,

    sum(revenue) as revenue,
    sum(order_count) as order_count,

    count(*) as calendar_days,
    sum(case when is_trading_day then 1 else 0 end) as trading_days,
    sum(case when is_early_close then 1 else 0 end) as early_close_days,

    -- The comparable measure. Denominator reflects days actually open. Just a small change
    sum(revenue) / nullif(sum(case when is_trading_day then 1 else 0 end), 0)
        as revenue_per_trading_day,

    -- Revenue that landed on a day the calendar says was closed. Should be
    -- zero. Anything else is a data-quality signal, not a business result.
    sum(case when not is_trading_day then revenue else 0 end)
        as revenue_on_closed_days,

    -- Names the reason a week is short, so a reader does not have to guess.
    max(case when not is_trading_day then holiday_name end) as closure_in_week

from joined
group by 1
order by 1
