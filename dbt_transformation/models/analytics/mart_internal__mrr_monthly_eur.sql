{{ config(
    materialized='view',
    tags=['analytics','reporting','mrr']
) }}

select
  recognition_month,
  sum(mrr_eur) as mrr_eur
from {{ ref('fct_mrr_alloc') }}
group by 1
