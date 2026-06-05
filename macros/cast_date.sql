{% macro cast_date(column_name) %}
    cast({{ column_name }} as date)
{% endmacro %}
