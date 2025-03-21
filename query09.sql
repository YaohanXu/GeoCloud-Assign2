/*
  With a query involving PWD parcels and census block groups, find the geo_id of the block group
  that contains Meyerson Hall. ST_MakePoint() and functions like that are not allowed.
*/

with
-- Find the parcel of Meyerson Hall
meyerson_parcel as (
    select parcels.geog as parcel_geog
    from phl.pwd_parcels as parcels
    where parcels.address ilike '%220-30 S 34TH ST%'
)

-- Find the census block group that contains the Meyerson Hall parcel
select bg.geoid as geo_id
from census.blockgroups_2020 as bg
inner join meyerson_parcel as mp
    on st_contains(bg.geog::geometry, mp.parcel_geog::geometry);
