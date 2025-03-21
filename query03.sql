/*
  Using the Philadelphia Water Department Stormwater Billing Parcels dataset,
  pair each parcel with its closest bus stop. The final result should give the parcel address, bus stop name,
  and distance apart in meters, rounded to two decimals. Order by distance (largest on top).
*/

select
    parcels.address as parcel_address,
    trim(both ' ' from stops.stop_name) as stop_name,
    round(st_distance(parcels.geog, stops.geog)::numeric, 2) as distance
from phl.pwd_parcels as parcels
cross join
    lateral (
        -- Find the closest bus stop for each parcel
        select
            stops.stop_name,
            stops.geog
        from septa.bus_stops as stops
        order by stops.geog <-> parcels.geog
        limit 1
    ) as stops
order by distance desc;
