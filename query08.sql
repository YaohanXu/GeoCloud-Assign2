/*
  With a query, find out how many census block groups Penn's main campus fully contains.
  Discuss which dataset you chose for defining Penn's campus.
*/

with
-- Select the University City neighborhood
university_city as (
    select n.geog as neighborhood_geog
    from phl.neighborhoods as n
    where n.name = 'UNIVERSITY_CITY'
),

-- Select parcels that intersect with University City and match ownership conditions
seleted_parcels as (
    select pp.geog as parcel_geog
    from phl.pwd_parcels as pp
    inner join university_city as uc
        on st_intersects(uc.neighborhood_geog, pp.geog)
    where
        (pp.owner1 ilike '%univ%' and pp.owner1 ilike '%penn%')
        or
        (pp.owner2 ilike '%univ%' and pp.owner2 ilike '%penn%')
),

-- Calculate the convex hull of the selected parcels to define Penn's campus boundary
penn_boundary as (
    select st_convexhull(st_union(sp.parcel_geog::geometry)) as convexhull_geog
    from seleted_parcels as sp
),

-- Calculate the percentage of overlap between census block groups and the defined Penn's campus boundary
blockgroups_overlap as (
    select
        bg.geoid,
        round((st_area(st_intersection(bg.geog, pb.convexhull_geog)) / st_area(bg.geog) * 100)::numeric, 2) as percent_overlap
    from census.blockgroups_2020 as bg
    cross join penn_boundary as pb
    where st_intersects(bg.geog, pb.convexhull_geog)
)

-- Count census block groups that are at least 90% contained within Penn's campus boundary as an approximation
select count(bo.geoid) as count_block_groups
from blockgroups_overlap as bo
where bo.percent_overlap >= 90;
