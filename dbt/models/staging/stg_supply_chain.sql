-- SupplyChain: export order status tracking.
-- Preserve BAQ columns until their definitions are confirmed.
select * from {{ source('export_orders', 'supply_chain') }}

