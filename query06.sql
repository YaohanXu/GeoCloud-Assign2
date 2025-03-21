/*
  What are the top five neighborhoods according to your accessibility metric?
*/

with
-- Retrieve wheelchair accessibility information for parent stations
parent_wheelchair as (
    select
        stops.stop_id,
        stops.wheelchair_boarding as parent_wheelchair_boarding
    from septa.bus_stops as stops
),

-- Inheriting wheelchair accessibility from parent station if applicable
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

-- Compute total stops, total accessible stops, and area (in square kilometers) for each neighborhood
neighborhood_accessibility as (
    select
        n.name as neighborhood_name,
        count(sw.stop_id) as total_stops,
        sum(case when sw.wheelchair_boarding = 1 then 1 else 0 end) as accessible_stops,
        st_area(n.geog) / 1000000 as area_km2
    from phl.neighborhoods as n
    left join stops_wheelchair as sw
        on st_intersects(n.geog, sw.geog)
    group by n.name, n.geog
)

-- Calculate wheelchair-accessible stop density per square kilometer for each neighborhood
select
    na.neighborhood_name,
    na.total_stops,
    na.accessible_stops,
    na.area_km2,
    round((na.accessible_stops / nullif(na.area_km2, 0))::numeric, 2) as wheelchair_stop_density
from neighborhood_accessibility as na
order by wheelchair_stop_density desc -- Select the top five neighborhoods with good wheelchair accessibility
limit 5;
