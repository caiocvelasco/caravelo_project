{{ config(materialized='view') }}

SELECT
  SPLIT_PART(value:c1::string, ',', 1) AS record_locator,
  TO_TIMESTAMP_NTZ(SPLIT_PART(value:c1::string, ',', 2)) AS creation_date,
  SPLIT_PART(value:c1::string, ',', 3) AS pax_type,
  SPLIT_PART(value:c1::string, ',', 4) AS pax_name,
  SPLIT_PART(value:c1::string, ',', 5) AS dep_stn,
  SPLIT_PART(value:c1::string, ',', 6) AS arr_stn,
  SPLIT_PART(value:c1::string, ',', 7) AS flight_num,
  TO_DATE(SPLIT_PART(value:c1::string, ',', 8)) AS dep_date,
  SPLIT_PART(value:c1::string, ',', 9) AS booking_sts,
  SPLIT_PART(value:c1::string, ',', 10) AS fare_basis,
  SPLIT_PART(value:c1::string, ',', 11) AS tkt_number
FROM {{ source('raw','amadeus_raw_dbt') }}
