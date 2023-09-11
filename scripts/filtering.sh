
#!/bin/bash


for dataset in original sigo; do
    echo $dataset passenger

    # filtrage sur le nombre de passagé 
    dsq src/data/$dataset/all/yellow-tripdata_2023-06-23.json "
    SELECT tpep_pickup_datetime, tpep_dropoff_datetime , passenger_count, trip_distance, PULocationID, DOLocationID  
    FROM {} WHERE 
    passenger_count == 3
    "  \
    > src/data/$dataset/passenger/yellow-tripdata_2023-06-23.json

    # filtrage sur l'heure 
    dsq src/data/$dataset/passenger/yellow-tripdata_2023-06-23.json "
    SELECT tpep_pickup_datetime, tpep_dropoff_datetime , passenger_count, trip_distance, PULocationID, DOLocationID  
    FROM {} WHERE 
        tpep_pickup_datetime >= 1687532400000000
    AND 
        tpep_pickup_datetime <  1687536000000000
      "  \
    > src/data/$dataset/date/yellow-tripdata_2023-06-23.json


    # filtrage sur la localisation 
    dsq src/data/$dataset/date/yellow-tripdata_2023-06-23.json "
    SELECT tpep_pickup_datetime, tpep_dropoff_datetime , passenger_count, trip_distance, PULocationID, DOLocationID  
    FROM {} WHERE 
        PULocationID == 211
      "  \
    > src/data/$dataset/localisation/yellow-tripdata_2023-06-23.json
done;