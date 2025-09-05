{{ config(materialized='table', tags=['staging','mrr']) }}

select
  value:"clientCode"::string           as client_code,
  value:"client_name"::string          as client_name,
  value:"reporting_timezone"::string   as reporting_timezone,
  value:"reporting_currency"::string   as reporting_currency
from {{ source('raw','clients_config_raw_dbt') }}
