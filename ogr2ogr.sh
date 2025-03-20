ogr2ogr \
    -f "PostgreSQL" \
    PG:"host=localhost port=5432 dbname=assign02 user=yaohanxu" \
    -nln phl.pwd_parcels \
    -nlt MULTIPOLYGON \
    -t_srs EPSG:4326 \
    -lco GEOMETRY_NAME=geog \
    -lco GEOM_TYPE=GEOGRAPHY \
    -overwrite \
    "__data__/PWD_PARCELS/PWD_PARCELS.shp"

ogr2ogr \
    -f "PostgreSQL" \
    PG:"host=localhost port=5432 dbname=assign02 user=yaohanxu" \
    -nln phl.neighborhoods \
    -nlt MULTIPOLYGON \
    -lco GEOMETRY_NAME=geog \
    -lco GEOM_TYPE=GEOGRAPHY \
    -overwrite \
    "__data__/philadelphia-neighborhoods.geojson"

ogr2ogr \
    -f "PostgreSQL" \
    PG:"host=localhost port=5432 dbname=assign02 user=yaohanxu" \
    -nln census.blockgroups_2020 \
    -nlt MULTIPOLYGON \
    -t_srs EPSG:4326 \
    -lco GEOMETRY_NAME=geog \
    -lco GEOM_TYPE=GEOGRAPHY \
    -overwrite \
    "__data__/tl_2020_42_bg/tl_2020_42_bg.shp"

csvcut -c GEO_ID,NAME,"P1_001N" __data__/DECENNIALPL2020.P1-Data.csv > __data__/filtered_data.csv
sed '2d' __data__/filtered_data.csv > __data__/filtered_data_cleaned.csv