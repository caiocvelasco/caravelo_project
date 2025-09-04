-- models/silver/stg_scd2_table.sql

-- References the MY_DBT_DATABASE.BRONZE.SOURCE_A in Snowflake
-- References the MY_DBT_DATABASE.BRONZE.SOURCE_B in Snowflake
-- Materialization: Table (global configuration in "dbt_transformation\dbt_project.yml")

{{ config(
    materialized='incremental',
    unique_key=['ID', 'DT_PART'] 
) }}
  

-- Define the latest date to be processed
-- In incremental runs, only select data from the most recent partition    
-- Complete Table before SCD Type 2: Table a left joined with b
with cte_source_a_b as (
    select 
        a.ID, 
        a.DT_PART, 
        b.NUM, 
        a.VALUE
    from {{ source('bronze', 'source_a') }} as a
    left join {{ source('bronze', 'source_b') }} as b
        on a.ID = b.ID
        and a.DT_PART = b.DT_PART
    
    {% if is_incremental() %}
    where a.DT_PART > (select max(DT_PART) from {{ this }})  -- Only process new partitions -- {{ this }} is the database representation of the current model (https://docs.getdbt.com/reference/dbt-jinja-functions/this)

    UNION ALL

    select
        ID, 
        DT_PART,
        NUM, 
        VALUE
    from {{ this }}
    WHERE VALID_TO is NULL
    {% endif %}
),

hash_table as (
	select *
	    , hash(* exclude (DT_PART)) as _hash
        , LAG(_hash) over (partition by ID order by DT_PART) as _previous_hash
	    , COALESCE(_hash != _previous_hash, TRUE) as _value_changed
	from cte_source_a_b 
)

select * exclude (_previous_hash, _value_changed)
    , DT_PART AS VALID_FROM
    , LEAD(DT_PART) over (partition by ID order by DT_PART) as VALID_TO
from hash_table
WHERE _value_changed = TRUE