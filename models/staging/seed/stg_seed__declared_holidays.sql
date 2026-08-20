with declared_holidays as (

    select * from {{ ref('seed_declared_holidays') }}

)

select
    md5(concat_ws('|', holiday_date::varchar, jurisdiction)) as declared_holiday_id,
    holiday_date,
    holiday_name,
    jurisdiction,
    closure_type,
    is_early_close,
    declared_at,
    declared_by,
    source_reference
from declared_holidays
