/*
  Which eight bus stops have the smallest population above 500 people inside of Philadelphia
  within 800 meters of the stop (Philadelphia county block groups have a geoid prefix of 42101
  -- that's 42 for the state of PA, and 101 for Philadelphia county)?
*/

with
-- Find census block groups within 800m of each bus stop (only in Philadelphia)
septa_bus_stop_blockgroups as (
    select
        stops.stop_id,
        '1500000US' || bg.geoid as geoid
    from septa.bus_stops as stops
    inner join census.blockgroups_2020 as bg
        on st_dwithin(stops.geog, bg.geog, 800)
    where bg.geoid like '42101%'
),

-- Calculate total population within 800m of each bus stop (only stops with >500 people)
septa_bus_stop_surrounding_population as (
    select
        stops.stop_id,
        sum(pop.total) as estimated_pop_800m
    from septa_bus_stop_blockgroups as stops
    inner join census.population_2020 as pop using (geoid)
    group by stops.stop_id
    having sum(pop.total) > 500
)

-- Retrieve stop names, locations, and sort by population (asc)
select
    pop.estimated_pop_800m,
    stops.geog,
    trim(both ' ' from stops.stop_name) as stop_name
from septa_bus_stop_surrounding_population as pop
inner join septa.bus_stops as stops using (stop_id)
order by pop.estimated_pop_800m asc
limit 8;
