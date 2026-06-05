{% macro generate_index_mod10(column_name) %}
    mod(abs(hashtext(cast({{ column_name }} as text))), 10)
{% endmacro %}
