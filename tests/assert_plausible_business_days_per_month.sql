-- A month outside 17-23 business days means a bad seed edit. This is the
-- test that catches a fat-fingered holiday date before the exported
-- calendar reaches the scheduler.
with monthly as (

    select
        calendar_month,
        sum(case when is_business_day then 1 else 0 end) as business_day_count
    from {{ ref('dim_business_calendar') }}
    where date_day >= '2025-01-01'
      and date_day <  '2036-01-01'
    group by 1

)

select *
from monthly
where business_day_count not between 17 and 23