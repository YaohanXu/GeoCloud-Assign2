/*
  Using the bus_shapes, bus_routes, and bus_trips tables from GTFS bus feed,
  find the two routes with the longest trips.
*/

with trip_shape as (
    select
        bs.shape_id,
        st_makeline(array_agg(
            st_setsrid(st_makepoint(bs.shape_pt_lon, bs.shape_pt_lat), 4326)
            order by bs.shape_pt_sequence
        ))::geography as shape_geog
    from septa.bus_shapes as bs
    group by bs.shape_id
),

-- Calculate the length of each trip shape
trip_length as (
    select
        ts.shape_id,
        ts.shape_geog,
        round(st_length(ts.shape_geog)::numeric, 2) as shape_length
    from trip_shape as ts
),

-- Identify the longest trip for each route_id
ranked_trip as (
    select
        bt.route_id,
        bt.trip_headsign,
        tl.shape_geog,
        tl.shape_length,
        row_number() over (
            partition by bt.route_id
            order by tl.shape_length desc
        ) as rn
    from septa.bus_trips as bt
    inner join trip_length as tl
        on bt.shape_id = tl.shape_id
),

final_trip as (
    select *
    from ranked_trip as rt
    where rt.rn = 1
)

select
    br.route_short_name,
    ft.trip_headsign,
    ft.shape_geog,
    ft.shape_length
from final_trip as ft
inner join septa.bus_routes as br
    on ft.route_id = br.route_id
order by ft.shape_length desc
limit 2;
