SELECT
    *
  FROM {{ ref('pb_jaffle_shop', 'cust_fact') }}