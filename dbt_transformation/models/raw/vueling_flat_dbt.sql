{{ config(materialized='view') }}

SELECT
  b.value:booking_reference::string AS booking_reference,
  b.value:created_at::timestamp_ntz AS creation_date,
  p.value:name::string AS pax_name,
  p.value:type::string AS pax_type,
  f.value:origin::string AS dep_stn,
  f.value:destination::string AS arr_stn,
  f.value:flight_number::string AS flight_num,
  f.value:departure_date::date AS dep_date,
  b.value:price.currency::string AS currency,
  b.value:price.total::float AS price_total
FROM {{ source('raw','vueling_raw_dbt') }},
     LATERAL FLATTEN(input => value) b,
     LATERAL FLATTEN(input => b.value:passengers) p,
     LATERAL FLATTEN(input => b.value:flights) f
