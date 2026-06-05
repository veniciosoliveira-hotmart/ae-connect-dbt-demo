{% macro cast_string(column_name, upper_case=true) %}
    {% if upper_case %}
        upper(cast({{ column_name }} as text))
    {%- else %}
        cast({{ column_name }} as text)
    {%- endif %}
{% endmacro %}
