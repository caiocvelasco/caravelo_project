-- This macro makes sure your database schemas' names are respected
-- https://docs.getdbt.com/docs/build/custom-schemas#how-does-dbt-generate-a-models-schema-name

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- else -%}

        {{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}