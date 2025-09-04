{% test date_format(model, column_name) %}

with date_validation as (

    select
        {{ column_name }}::text as date_column
    from {{ model }}

)

select
    date_column
from date_validation
where date_column !~ '^\d{4}-\d{2}-\d{2}$'

{% endtest %}