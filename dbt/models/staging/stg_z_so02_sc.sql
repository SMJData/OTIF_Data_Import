-- z_SO02-SC: week-wise export sales orders by part and product attributes.
-- Preserve BAQ columns until their definitions are confirmed.
select * from {{ source('export_orders', 'z_so02_sc') }}

