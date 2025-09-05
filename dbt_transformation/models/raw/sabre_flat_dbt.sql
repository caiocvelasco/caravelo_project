{{ config(materialized='view') }}

SELECT
  SPLIT_PART(value:c1::string, ',', 1)  AS pnr,
  TO_TIMESTAMP_NTZ(SPLIT_PART(value:c1::string, ',', 2)) AS create_date_utc,
  SPLIT_PART(value:c1::string, ',', 3)  AS passenger_name,
  SPLIT_PART(value:c1::string, ',', 4)  AS frequent_flyer_number,
  SPLIT_PART(value:c1::string, ',', 5)  AS origin,
  SPLIT_PART(value:c1::string, ',', 6)  AS destination,
  SPLIT_PART(value:c1::string, ',', 7)  AS flight_number,
  TO_DATE(SPLIT_PART(value:c1::string, ',', 8)) AS departuredate,
  SPLIT_PART(value:c1::string, ',', 9)  AS status,
  SPLIT_PART(value:c1::string, ',', 10) AS class,
  SPLIT_PART(value:c1::string, ',', 11) AS ticketnumber
FROM {{ source('raw','sabre_raw_dbt') }}
