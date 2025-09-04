-- models/gold/dim_scd2_table.sql

-- References the MY_DBT_DATABASE.SILVER.stg_scd2_table in Snowflake
-- Materialization: View (global configuration in "dbt_transformation\dbt_project.yml")
 

select
    id,
    value,
    num,
    valid_from,
    valid_to
from {{ ref('stg_scd2_table') }}
