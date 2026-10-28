-- macros/generate_schema_name.sql
-- Overrides dbt's default schema naming behaviour.
-- By default dbt prepends the target schema to custom schema names
-- e.g. "public_silver", "public_gold" — this macro prevents that
-- and uses the custom schema name exactly as specified in dbt_project.yml.

{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}