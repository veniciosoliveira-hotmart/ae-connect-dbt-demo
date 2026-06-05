{% macro cast_float(column_name) %}
    cast({{ column_name }} as float)
{% endmacro %}
