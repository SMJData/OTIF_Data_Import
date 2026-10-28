-- z_SO02-SC: week-wise export sales orders by part and product attributes.
select * from {{ ref('stg_z_so02_sc') }}

