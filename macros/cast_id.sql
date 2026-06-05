{% macro cast_id(column_name) %}
    cast({{ column_name }} as bigint)
{% endmacro %}
