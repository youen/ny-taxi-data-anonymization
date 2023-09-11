

# Download data from NYC taxi
wget https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2023-06.parquet -O - | \
# limit columns and filter data from 23/06/23 and zones arround Soho
dsq -s parquet "
SELECT tpep_pickup_datetime, tpep_dropoff_datetime , passenger_count, trip_distance, PULocationID, DOLocationID  
FROM {} WHERE 
--  PULocationID in (125, 144, 211,231, 114)
-- AND
  tpep_pickup_datetime >= 1687478400000000
 AND 
  tpep_pickup_datetime <  1687564800000000
"  | \
# save as json 
tee src/data/original/all/yellow-tripdata_2023-06-23.json | \
# save as jsonl
jq -c '.[]'  > src/data/original/all/yellow-tripdata_2023-06-23.jsonl

