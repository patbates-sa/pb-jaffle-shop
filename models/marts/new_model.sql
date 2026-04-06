<<<<<<< HEAD
select * from {{ ref ('cust_fact')}}
=======
SELECT
    *
  FROM {{ ref('pb_jaffle_shop', 'cust_fact') }}
>>>>>>> 587e3a5fb8e2c9b60eb14f89d6f744957c8b4ee2
