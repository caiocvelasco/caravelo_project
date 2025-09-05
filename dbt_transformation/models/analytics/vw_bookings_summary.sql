-- A high-level summary by route and source system.
-- One row = source system + origin + destination

{{ config(materialized='view', schema=env_var('SNOWFLAKE_SCHEMA_ANALYTICS')) }}

SELECT
  source_system,  -- Amadeus / Sabre / Vueling (origin of the data)

  origin,         -- Departure airport (IATA code, e.g. MAD, LHR)
  destination,    -- Arrival airport (IATA code, e.g. JFK, DOH)

  COUNT(*) AS segments,  
  -- Total passenger-flight segments (1 row per passenger per flight).
  -- If 2 passengers are booked on the same flight, this counts as 2
  -- (think like this: "seats sold on this leg").

  COUNT(DISTINCT booking_id) AS bookings,  
  -- Number of unique bookings (PNR/Record Locator).
  -- Groups multiple passengers under the same booking reference.

  COUNT(DISTINCT passenger_name) AS passengers  
  -- Number of distinct passengers (by name) for this route/system.
  -- Lets us see true pax volume, not just rows.

FROM {{ ref('stg_bookings') }}
GROUP BY 1,2,3
