{{ config(
    materialized='view',
    tags=['analytics','fact','mrr']
) }}

with e as ( select * from {{ ref('stg_subscription_events') }} ),
c as ( select * from {{ ref('stg_clients') }} ),

enriched as (
  select
    e.event_id, e.event_name, e.is_success,
    e.client_code, c.client_name, c.reporting_timezone, c.reporting_currency,
    e.subscription_id, e.invoice_id, e.currency_native, e.amount_native,
    e.event_ts_utc, e.invoice_date, e.paid_from_date, e.quota_from_date, e.quota_to_date,
    e.base_product, e.phase, e.hub,

    coalesce(
      e.quota_from_date,
      e.paid_from_date,
      e.invoice_date,
      convert_timezone('UTC', c.reporting_timezone, e.event_ts_utc)::date
    ) as recognition_date,

    date_trunc('month',
      coalesce(
        e.quota_from_date,
        e.paid_from_date,
        e.invoice_date,
        convert_timezone('UTC', c.reporting_timezone, e.event_ts_utc)::date
      )
    ) as recognition_month,

    case
      when upper(coalesce(e.billing_period_hint,'')) in ('MONTHLY','QUARTERLY','ANNUAL') then e.billing_period_hint
      when datediff('day', e.quota_from_date, e.quota_to_date) between 80 and 100 then 'QUARTERLY'
      when datediff('day', e.quota_from_date, e.quota_to_date) between 360 and 370 then 'ANNUAL'
      else 'MONTHLY'
    end as billing_period
  from e
  left join c using (client_code)
  where e.is_success
),

allocated as (
  select
    *,
    case billing_period
      when 'MONTHLY'   then amount_native
      when 'QUARTERLY' then amount_native / 3
      when 'ANNUAL'    then amount_native / 12
    end as mrr_native
  from enriched
),

fxm as ( select * from {{ ref('stg_fx_rates_monthly') }} ),

fx_join as (
  select
    a.*,
    fn.eur_per_unit as eur_per_unit_native,
    fr.eur_per_unit as eur_per_unit_reporting
  from allocated a
  left join fxm fn
    on fn.currency = a.currency_native
   and fn.fx_month = a.recognition_month
  left join fxm fr
    on fr.currency = a.reporting_currency
   and fr.fx_month = a.recognition_month
)

select
  client_code, client_name, reporting_currency, reporting_timezone,
  subscription_id, invoice_id, base_product, billing_period,
  recognition_month,
  currency_native, amount_native, mrr_native,
  (mrr_native * eur_per_unit_native)                                                   as mrr_eur,
  case when eur_per_unit_reporting is not null and eur_per_unit_reporting > 0
       then (mrr_native * eur_per_unit_native) / eur_per_unit_reporting
       else null end                                                                   as mrr_reporting_currency,
  eur_per_unit_native, eur_per_unit_reporting
from fx_join
