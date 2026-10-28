-- OntimeDelivery: export order OTIF tracking (Late, Early, Ontime).
select * from {{ ref('stg_ontime_delivery') }}

