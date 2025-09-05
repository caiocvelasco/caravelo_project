{{ config(materialized='table', schema=env_var('SNOWFLAKE_SCHEMA_ANALYTICS')) }}

WITH base AS (
  SELECT
    -- Natural keys from the sources
    booking_id,                       -- Original booking reference (PNR / Record Locator / booking_reference)
    source_system,                    -- Source system (Amadeus / Sabre / Vueling)

    -- Surrogate key to ensure uniqueness across different systems
    MD5(source_system || '|' || booking_id) AS booking_sk, -- Safe unique key across systems

    -- Descriptive attributes
    MIN(booking_created_at) AS booking_created_at, -- Earliest creation timestamp for the booking

    -- Optional quick attributes for BI visualization (not guaranteed unique or canonical)
    ANY_VALUE(origin) AS any_origin,       -- A sample origin airport for the booking (for dashboards/labels)
    ANY_VALUE(destination) AS any_destination -- A sample destination airport for the booking
  FROM {{ ref('stg_bookings') }}
  GROUP BY booking_id, source_system
)

SELECT * FROM base
