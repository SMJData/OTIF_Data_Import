-- OntimeDelivery: export order OTIF tracking (Late, Early, Ontime).
-- Preserve BAQ columns until their definitions are confirmed.
select * from {{ source('export_orders', 'ontime_delivery') }}

