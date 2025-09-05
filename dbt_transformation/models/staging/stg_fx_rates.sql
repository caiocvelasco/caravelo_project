{{ config(materialized='table', tags=['staging','mrr','fx']) }}

select
  to_date(value:"date"::string)        as rate_date,
  value:"currency"::string             as currency,
  value:"eur_per_unit"::number(18,6)   as eur_per_unit
from {{ source('raw','fx_rates_raw_dbt') }}
where rate_date is not null
