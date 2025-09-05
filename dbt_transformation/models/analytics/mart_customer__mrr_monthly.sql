{{ config(
    materialized='view',
    tags=['analytics','reporting','mrr']
) }}

select
  client_code,
  client_name,
  reporting_currency,
  recognition_month,
  sum(mrr_reporting_currency) as mrr_reporting_currency
from {{ ref('fct_mrr_alloc') }}
group by 1,2,3,4
