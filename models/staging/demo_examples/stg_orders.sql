{{ config(
    materialized = 'table',
    tags = 'staging'
) }}



with source as (

    select * from {{ ref('pedidos') }}

),

cast_types as (

    select
        {{ cast_date('data_pedido') }}             as hub_transaction_date,
        {{ generate_index_mod10('cliente_id') }}   as hub_index_client_id_mod10,
        {{ generate_index_mod10('produto_id') }}   as hub_index_product_id_mod10,
        {{ cast_id('id') }}                        as order_id,
        {{ cast_id('cliente_id') }}                as client_id,
        {{ cast_id('produto_id') }}                as product_id,
        {{ cast_string('status') }}                as order_status
    from 
        source
)

select * from cast_types
