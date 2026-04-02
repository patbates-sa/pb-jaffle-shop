SELECT
    *
  FROM {{ ref('pb_jaffle_shop', 'dim_customers') }}
  