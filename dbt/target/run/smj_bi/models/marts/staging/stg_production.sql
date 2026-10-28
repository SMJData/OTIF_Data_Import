
  
    

  create  table "postgres"."gold"."stg_production__dbt_tmp"
  
  
    as
  
  (
    -- models/staging/stg_production.sql
-- Staging model for raw Epicor production efficiency data.
-- Responsibilities:
--   - Rename columns to clean snake_case (drop vendor prefixes)
--   - Cast all columns to correct data types
--   - Fix 24:00 → 00:00 clock-out edge case
--   - Derive shift from clock-in hour
--   - Map ResourceGrpID → Line and Division
--   - Split CommercialSize1/2 → brand_pack and config
--   - No OEE metric calculations — those live in marts

with source as (

    select * from "postgres"."raw"."Production"

),

cleaned as (

    select
        -- ── Keys & identifiers ─────────────────────────────────────────
        labordtl_jobnum                                         as job_num,
        labordtl_resourcegrpid                                  as resource_grp_id,
        labordtl_employeenum                                    as employee_num,
        labordtl_createdby                                      as created_by,
        labordtl_changedby                                      as changed_by,
        rowident                                                as row_ident,

        -- ── Date ───────────────────────────────────────────────────────
        -- Source arrives as text e.g. "2026-06-01 00:00:00"
        cast(
            split_part(labordtl_clockindate, ' ', 1) as date
        )                                                       as clock_in_date,

        extract(year from cast(
            split_part(labordtl_clockindate, ' ', 1) as date
        ))::int                                                 as year,

        extract(month from cast(
            split_part(labordtl_clockindate, ' ', 1) as date
        ))::int                                                 as month_num,

        to_char(cast(
            split_part(labordtl_clockindate, ' ', 1) as date
        ), 'Month')                                             as month_name,

        extract(day from cast(
            split_part(labordtl_clockindate, ' ', 1) as date
        ))::int                                                 as day,

        -- ── Clock times ────────────────────────────────────────────────
        -- Display times already in HH:MM format
        cast(labordtl_dspclockintime as time)                   as dsp_clock_in_time,

        -- Handle 24:00 edge case for midnight clock-outs
        cast(
            case
                when labordtl_dspclockouttime = '24:00' then '00:00'
                else labordtl_dspclockouttime
            end as time
        )                                                       as dsp_clock_out_time,

        -- ── Shift derivation ───────────────────────────────────────────
        -- Based on clock-in hour — avoids fragile string matching
        case
            when extract(hour from cast(labordtl_dspclockintime as time)) >= 7
             and extract(hour from cast(labordtl_dspclockintime as time)) < 19
            then 'AM'
            when extract(hour from cast(labordtl_dspclockintime as time)) >= 19
              or extract(hour from cast(labordtl_dspclockintime as time)) < 7
            then 'PM'
            else null
        end                                                     as shift,

        -- ── Line and Division from ResourceGrpID ───────────────────────
        case labordtl_resourcegrpid
            when 'FPBHL2' then 'Bottling Hall'
            when 'FPBHL3' then 'Bottling Hall'
            when 'FPBHL4' then 'Bottling Hall'
            when 'FPBHL5' then 'Bottling Hall'
            when 'FPBHL6' then 'Bottling Hall'
            when 'FPTEL3' then 'Tetra'
            when 'FPTEL4' then 'Tetra'
            when 'FPTEL5' then 'Tetra'
            when 'MAINTC' then 'Maintenance'
            else null
        end                                                     as line,

        case labordtl_resourcegrpid
            when 'FPBHL2' then 'Bottling Hall'
            when 'FPBHL3' then 'Bottling Hall'
            when 'FPBHL4' then 'Bottling Hall'
            when 'FPBHL5' then 'Bottling Hall'
            when 'FPBHL6' then 'Bottling Hall'
            when 'FPTEL3' then 'Tetra'
            when 'FPTEL4' then 'Tetra'
            when 'FPTEL5' then 'Tetra'
            when 'MAINTC' then 'Maintenance'
            else null
        end                                                     as division,

        -- ── Brand / Product ────────────────────────────────────────────
        part_commercialbrand                                    as brand,
        part_commercialsize1                                    as brand_pack,
        part_commercialsize2                                    as config,
        part_partdescription                                    as part_description,
        part_partnum                                            as part_num,
        part_classid                                            as class_id,
        part_commercialcolor                                    as commercial_color,

        -- ── Raw production metrics (no calculations) ───────────────────
        cast(calculated_plannedprodtime   as numeric)           as planned_prod_time,
        cast(calculated_planneddowntime   as numeric)           as planned_down_time,
        cast(calculated_actualgoodqapassed as numeric)          as actual_good_qa_passed,
        cast(calculated_expectedproduction as numeric)          as expected_production,
        cast(calculated_completedcasesqty  as numeric)          as completed_cases_qty,
        cast(calculated_machinespeed       as numeric)          as machine_speed,
        cast(calculated_runtime            as numeric)          as runtime,
        cast(calculated_unplanneddowntime  as numeric)          as unplanned_down_time,
        cast(labordtl_laborqty             as numeric)          as labor_qty,
        cast(labordtl_scrapqty             as numeric)          as scrap_qty,

        -- ── Other labor fields ─────────────────────────────────────────
        labordtl_labortype                                      as labor_type,
        labordtl_jcdept                                         as department,
        labordtl_opcode                                         as op_code,
        labordtl_timestatus                                     as time_status,
        labordtl_complete                                       as is_complete,
        labordtl_rework                                         as is_rework,
        labordtl_labornote                                      as labor_note,
        calculated_reasonforholdproduct                         as reason_for_hold,

        -- ── Metadata ───────────────────────────────────────────────────
        now()                                                   as _staged_at

    from source

)

select * from cleaned
  );
  