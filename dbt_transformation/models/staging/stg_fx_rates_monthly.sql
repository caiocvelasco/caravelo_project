{{ config(materialized='table', tags=['staging','mrr','fx']) }}

with r as (
  select date_trunc('month', rate_date) as fx_month, currency, eur_per_unit, rate_date
  from {{ ref('stg_fx_rates') }}
),
rk as (
  select *, row_number() over(partition by currency, fx_month order by rate_date desc) rn
  from r
)
select currency, fx_month, eur_per_unit
from rk
where rn = 1
