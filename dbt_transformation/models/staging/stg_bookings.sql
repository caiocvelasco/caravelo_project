-- This model has one row per booking × passenger × flight segment.

{{ config(materialized='table', schema=env_var('SNOWFLAKE_SCHEMA_STAGING')) }}

WITH amadeus AS (
  SELECT
    record_locator        AS booking_id,
    creation_date         AS booking_created_at,
    pax_name              AS passenger_name,
    pax_type              AS passenger_type,
    dep_stn               AS origin,
    arr_stn               AS destination,
    flight_num            AS flight_number,
    dep_date              AS departure_date,
    booking_sts           AS status,
    fare_basis            AS fare_basis,
    tkt_number            AS ticket_number,
    CAST(NULL AS STRING)  AS class,
    CAST(NULL AS STRING)  AS currency,
    CAST(NULL AS NUMBER(12,2)) AS price_total,
    'Amadeus'             AS source_system,
    CURRENT_TIMESTAMP     AS loaded_at
  FROM {{ ref('amadeus_flat_dbt') }}
),
sabre AS (
  SELECT
    pnr                   AS booking_id,
    create_date_utc       AS booking_created_at,
    passenger_name        AS passenger_name,
    CAST(NULL AS STRING)  AS passenger_type,
    origin                AS origin,
    destination           AS destination,
    flight_number         AS flight_number,
    departuredate         AS departure_date,
    status                AS status,
    CAST(NULL AS STRING)  AS fare_basis,
    ticketnumber          AS ticket_number,
    class                 AS class,
    CAST(NULL AS STRING)  AS currency,
    CAST(NULL AS NUMBER(12,2)) AS price_total,
    'Sabre'               AS source_system,
    CURRENT_TIMESTAMP     AS loaded_at
  FROM {{ ref('sabre_flat_dbt') }}
),
vueling AS (
  SELECT
    booking_reference     AS booking_id,
    creation_date         AS booking_created_at,
    pax_name              AS passenger_name,
    pax_type              AS passenger_type,
    dep_stn               AS origin,
    arr_stn               AS destination,
    flight_num            AS flight_number,
    dep_date              AS departure_date,
    CAST(NULL AS STRING)  AS status,
    CAST(NULL AS STRING)  AS fare_basis,
    CAST(NULL AS STRING)  AS ticket_number,
    CAST(NULL AS STRING)  AS class,
    currency              AS currency,
    price_total           AS price_total,
    'Vueling'             AS source_system,
    CURRENT_TIMESTAMP     AS loaded_at
  FROM {{ ref('vueling_flat_dbt') }}
)

SELECT * FROM amadeus
UNION ALL
SELECT * FROM sabre
UNION ALL
SELECT * FROM vueling
