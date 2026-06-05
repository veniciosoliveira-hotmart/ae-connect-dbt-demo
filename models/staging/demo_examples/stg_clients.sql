{{ config(
    materialized = 'table',
    tags = 'staging'
) }}




with source as (

    select * from {{ ref('clientes') }}

),

cast_types as (

    select
        {{ cast_date('data_cadastro') }}              as hub_transaction_date,
        {{ generate_index_mod10('id') }}              as hub_index_client_id_mod10,
        {{ cast_id('id') }}                           as client_id,
        {{ cast_string('nome') }}                     as client_name,
        {{ cast_string('email', upper_case=false) }}  as client_email,
        {{ cast_string('cidade') }}                   as city

    from source
)

select * from cast_types
