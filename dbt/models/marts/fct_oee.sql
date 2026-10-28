-- models/marts/fct_oee.sql
-- OEE fact table — this is the table Preset queries directly.
-- Computes all four OEE components on top of the cleaned staging layer.
--
-- OEE Formula:
--   Availability  = (planned_prod_time - planned_down_time) / planned_prod_time
--   Performance   = actual_good_qa_passed / expected_production
--   Quality Index = actual_good_qa_passed / completed_cases_qty
--   OEE (%)       = Availability × Performance × Quality Index × 100
--
-- All denominators are zero-guarded — returns 0 instead of NULL or Infinity.
-- Rounding:
--   Availability  → 2 dp
--   Performance   → 2 dp
--   Quality Index → 3 dp
--   OEE (%)       → 1 dp
--   Machine Speed → 2 dp

with staging as (

    select * from {{ ref('stg_production') }}

),

oee as (

    select
        -- ── Identifiers ────────────────────────────────────────────────
        job_num,
        resource_grp_id,
        employee_num,
        created_by,
        row_ident,

        -- ── Time intelligence ──────────────────────────────────────────
        clock_in_date,
        year,
        month_num,
        month_name,
        day,
        dsp_clock_in_time,
        dsp_clock_out_time,
        shift,

        -- ── Dimensions ─────────────────────────────────────────────────
        line,
        division,
        brand,
        brand_pack,
        config,
        part_num,
        part_description,
        class_id,

        -- ── Raw metrics ────────────────────────────────────────────────
        planned_prod_time,
        planned_down_time,
        actual_good_qa_passed,
        expected_production,
        completed_cases_qty,
        labor_qty,
        scrap_qty,
        unplanned_down_time,
        round(cast(machine_speed as numeric), 2)            as machine_speed,

        -- ── OEE: Availability ──────────────────────────────────────────
        round(
            cast(
                case
                    when coalesce(planned_prod_time, 0) = 0 then 0
                    else (planned_prod_time - planned_down_time)
                         / planned_prod_time
                end as numeric
            ), 2
        )                                                   as availability,

        -- ── OEE: Performance ───────────────────────────────────────────
        round(
            cast(
                case
                    when coalesce(expected_production, 0) = 0 then 0
                    else actual_good_qa_passed
                         / expected_production
                end as numeric
            ), 2
        )                                                   as performance,

        -- ── OEE: Quality Index ─────────────────────────────────────────
        round(
            cast(
                case
                    when coalesce(completed_cases_qty, 0) = 0 then 0
                    else actual_good_qa_passed
                         / completed_cases_qty
                end as numeric
            ), 3
        )                                                   as quality_index,

        -- ── Metadata ───────────────────────────────────────────────────
        _staged_at,
        now()                                               as _gold_at

    from staging

),

final as (

    select
        *,

        -- ── OEE (%) ────────────────────────────────────────────────────
        round(
            cast(
                availability * performance * quality_index * 100
                as numeric
            ), 1
        )                                                   as oee_pct

    from oee

)

select * from final