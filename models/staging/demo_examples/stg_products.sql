{{ config(
    materialized = 'table',
    tags = 'staging'
) }}



with source as (

    select * from {{ ref('produtos') }}

),

cast_types as (
    select
        {{ generate_index_mod10('id') }}   as hub_index_product_id_mod10,
        {{ cast_id('id') }}                as product_id,
        {{ cast_string('nome') }}          as product_name,
        {{ cast_string('categoria') }}     as product_category,
        {{ cast_float('preco') }}          as product_price
    from 
        source
)

select * from cast_types
