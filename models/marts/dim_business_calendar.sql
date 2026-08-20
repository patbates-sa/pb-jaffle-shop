-- models/marts/calendar/dim_business_calendar.sql
--
-- Authoritative business-day calendar. One row per date.
-- Consumed by transformation models, by the AutoSys calendar export, and by
-- the semantic layer as a time spine.
--
-- Depends on: seed_declared_holidays
-- Optional:   seed_fiscal_periods (see "Fiscal periods" below before enabling)

{{ config(
    materialized='table',
    tags=['calendar', 'governed']
) }}

with spine as (

    {{ dbt.date_spine(
        datepart="day",
        start_date="cast('2015-01-01' as date)",
        end_date="cast('2036-01-01' as date)"
    ) }}

),

days as (

    select cast(date_day as date) as date_day
    from spine

),

-- 1900-01-01 was a Monday, so this yields 0=Mon .. 5=Sat, 6=Sun on every
-- platform. Avoids the dialect trap: Snowflake DAYOFWEEK returns 0=Sunday
-- while Databricks DAYOFWEEK returns 1=Sunday, which silently inverts the
-- weekend flags when a project targets both.
weekdays as (

    select
        date_day,
        mod({{ dbt.datediff("cast('1900-01-01' as date)", 'date_day', 'day') }}, 7)
            as day_of_week_monday_zero
    from days

),

holidays as (

    select
        holiday_date,
        holiday_name,
        closure_type,
        is_early_close
    from {{ ref('seed_declared_holidays') }}
    where jurisdiction = '{{ var("calendar_jurisdiction", "US") }}'

),

classified as (

    select
        w.date_day,
        w.day_of_week_monday_zero,
        w.day_of_week_monday_zero in (5, 6)             as is_weekend,

        h.holiday_name,
        h.closure_type,
        coalesce(h.is_early_close, false)               as is_early_close,

        -- Market / processing business day: closed weekends and full closures.
        -- An early close is still a business day.
        case
            when w.day_of_week_monday_zero in (5, 6)    then false
            when h.closure_type = 'full_closure'        then false
            else true
        end                                             as is_business_day,

        -- Retail trading day: Monday to Saturday, closed Sundays and full
        -- closures. Used by fct_weekly_revenue. Keep this separate from
        -- is_business_day -- a shop and a settlement process do not share a
        -- definition of "open".
        case
            when w.day_of_week_monday_zero = 6          then false
            when h.closure_type = 'full_closure'        then false
            else true
        end                                             as is_trading_day,

        date_trunc('week', w.date_day)                  as week_start,
        date_trunc('month', w.date_day)                 as calendar_month

    from weekdays w
    left join holidays h
        on w.date_day = h.holiday_date

),

sequenced as (

    select
        *,

        -- Ordinal position of this business day within the calendar month.
        -- Underpins "third business day after month open" style rules.
        sum(case when is_business_day then 1 else 0 end) over (
            partition by calendar_month
            order by date_day
            rows between unbounded preceding and current row
        )                                               as business_day_of_month,

        max(case when is_business_day then date_day end) over (
            partition by calendar_month
        )                                               as last_business_day_of_month,

        -- IGNORE NULLS is supported on Snowflake, Databricks and DuckDB.
        -- Verify before porting elsewhere.
        lag(case when is_business_day then date_day end) ignore nulls over (
            order by date_day
        )                                               as prior_business_day,

        lead(case when is_business_day then date_day end) ignore nulls over (
            order by date_day
        )                                               as next_business_day

    from classified

)

select
    date_day,
    is_business_day,
    is_trading_day,
    is_weekend,
    is_early_close,
    holiday_name,
    closure_type,
    week_start,
    calendar_month,
    business_day_of_month,
    prior_business_day,
    next_business_day,
    date_day = last_business_day_of_month               as is_last_business_day_of_month
from sequenced