{{ config(
    materialized='view',
    tags=['analytics','dim','mrr']
) }}

select * from {{ ref('stg_clients') }}
