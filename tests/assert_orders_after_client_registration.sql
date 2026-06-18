-- Teste singular (customizado): um pedido nunca pode ser realizado antes da
-- data de cadastro do cliente que o efetuou.
--
-- Faz o join de stg_orders com stg_clients pelo client_id e retorna todos os
-- pedidos cuja data do pedido (hub_transaction_date) seja anterior à data de
-- cadastro do cliente. Um teste que passa retorna zero linhas; qualquer linha
-- retornada é uma violação.
--
-- Nota para a demo: com os dados atuais das seeds este teste FALHA em exatamente
-- uma linha — o pedido order_id 15 (client_id 17) foi feito em 2023-09-18, mas o
-- cliente 17 só foi cadastrado em 2023-11-02. Ótimo exemplo de como o dbt captura
-- um problema real de qualidade de dados que os testes de integridade
-- referencial sozinhos não detectariam.

with orders as (

    select
        order_id,
        client_id,
        hub_transaction_date as order_date
    from {{ ref('stg_orders') }}

),

clients as (

    select
        client_id,
        hub_transaction_date as registration_date
    from {{ ref('stg_clients') }}

),

violations as (

    select
        o.order_id,
        o.client_id,
        o.order_date,
        c.registration_date
    from orders o
    inner join clients c
        on o.client_id = c.client_id
    where o.order_date < c.registration_date

)

select * from violations
