{{ config(materialized='table', tags=['staging','mrr','events']) }}

select
  value:"eventId"::string                                        as event_id,
  value:"event"::string                                          as event_name,
  lower(value:"success"::string) = 'true'                        as is_success,
  value:"clientCode"::string                                     as client_code,
  value:"subscriptionId"::string                                 as subscription_id,
  value:"invoiceId"::string                                      as invoice_id,
  value:"currency"::string                                       as currency_native,
  to_decimal(value:"amount"::string)                             as amount_native,
  to_timestamp_ntz(value:"eventDateTime"::string, 'DD/Mon/YYYY:HH24:MI:SS TZHTZM') as event_ts_utc,
  to_date(value:"invoiceDate"::string)                           as invoice_date,
  to_date(value:"paidFromDate"::string)                          as paid_from_date,
  to_date(value:"quotaFromDate"::string)                         as quota_from_date,
  to_date(value:"quotaToDate"::string)                           as quota_to_date,
  upper(coalesce(value:"billingPeriod"::string, ''))             as billing_period_hint,
  value:"baseProduct"::string                                    as base_product,
  value:"phase"::string                                          as phase,
  value:"hub"::string                                            as hub
from {{ source('raw','subscription_events_raw_dbt') }}
