/*
  What are the bottom five neighborhoods according to your accessibility metric?
*/

with
-- Retrieve wheelchair accessibility information for parent stations
parent_wheelchair as (
    select
        stops.stop_id,
        stops.wheelchair_boarding as parent_wheelchair_boarding
    from septa.bus_stops as stops
),

-- Inherit wheelchair accessibility from parent station if applicable
stops_wheelchair as (
    select
        stops.stop_id,
        stops.stop_name,
        stops.geog,
        coalesce(
            case
                when stops.parent_station is not null and (stops.wheelchair_boarding is null or stops.wheelchair_boarding = 0)
                    then pw.parent_wheelchair_boarding
                else stops.wheelchair_boarding
            end, 0
        ) as wheelchair_boarding
    from septa.bus_stops as stops
    left join parent_wheelchair as pw
        on stops.parent_station = pw.stop_id
),

-- Compute total accessible stops, total inaccessible stops, and area (in square kilometers) for each neighborhood
neighborhood_accessibility as (
    select
        n.name as neighborhood_name,
        sum(case when sw.wheelchair_boarding = 1 then 1 else 0 end) as num_bus_stops_accessible,
        sum(case when sw.wheelchair_boarding = 2 then 1 else 0 end) as num_bus_stops_inaccessible,
        st_area(n.geog) / 1000000 as area_km2
    from phl.neighborhoods as n
    left join stops_wheelchair as sw
        on st_contains(n.geog::geometry, sw.geog::geometry)
    group by n.name, n.geog
)

-- Calculate wheelchair-accessible stop density per square kilometer for each neighborhood
select
    na.neighborhood_name,
    na.num_bus_stops_accessible,
    na.num_bus_stops_inaccessible,
    round((na.num_bus_stops_accessible / nullif(na.area_km2, 0))::numeric, 2) as accessibility_metric
from neighborhood_accessibility as na
order by accessibility_metric asc -- Select the bottom five neighborhoods with bad wheelchair accessibility
limit 5;
