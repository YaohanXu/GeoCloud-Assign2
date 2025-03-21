/*
  You're tasked with giving more contextual information to rail stops to fill the stop_desc field in a GTFS feed.
  Using any of the data sets above, PostGIS functions (e.g., ST_Distance, ST_Azimuth, etc.), and PostgreSQL string functions,
  build a description (alias as stop_desc) for each stop. Feel free to supplement with other datasets
  (must provide link to data used so it's reproducible), and other methods of describing the relationships.
  SQL's CASE statements may be helpful for some operations.
*/

with
-- Match each rail stop to its census block group
rail_block_group as (
    select
        rs.stop_id as rail_stop_id,
        coalesce(bg.namelsad || ' within PA', 'Block Group outside PA') as blockgroup_name
    from septa.rail_stops as rs
    left join census.blockgroups_2020 as bg
        on st_intersects(rs.geog, bg.geog)
),

-- Calculate the distance from each rail stop to the nearest bus stop
rail_nearest_bus_stop as (
    select
        rs.stop_id as rail_stop_id,
        round(st_distance(rs.geog, bs.geog)::numeric, 2) as nearest_bus_distance
    from septa.rail_stops as rs
    cross join lateral (
        select bs.geog
        from septa.bus_stops as bs
        order by rs.geog <-> bs.geog asc
        limit 1
    ) as bs
),

-- Count the number of bus stops within 500m of each rail stop
rail_bus_stop_500 as (
    select
        rs.stop_id as rail_stop_id,
        count(bs.stop_id) as bus_stop_count
    from septa.rail_stops as rs
    left join septa.bus_stops as bs
        on st_dwithin(rs.geog, bs.geog, 500)
    group by rs.stop_id
)

-- Combine all information to generate stop_desc
select
    rs.stop_id,
    rs.stop_name,
    rs.stop_lon,
    rs.stop_lat,
    'The rail stop is located in ' || rbg.blockgroup_name || ', the nearest bus stop is ' || coalesce(rnb.nearest_bus_distance, 0.00) || ' meters away' || ', with ' || coalesce(rbs.bus_stop_count, 0) || ' bus stops within 500m.' as stop_desc
from septa.rail_stops as rs
left join rail_block_group as rbg
    on rs.stop_id = rbg.rail_stop_id
left join rail_nearest_bus_stop as rnb
    on rs.stop_id = rnb.rail_stop_id
left join rail_bus_stop_500 as rbs
    on rs.stop_id = rbs.rail_stop_id;
