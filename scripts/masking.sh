cat src/data/original/all/yellow-tripdata_2023-06-23.jsonl | \
# Utilisation de PIMO pour modifier les indexs des zones en fonction du parcours du voyageurs de commerce
pimo -v 2  --load-cache zone=src/data/zone_index_cache.jsonl -c conf/masking-pre.yml  | \
# utilisation de SIGO pour anonymiser on lui demande de rajouter un champ box dans le flus json pour connaitre le groupe d'apartenance du trajet 
sigo -c conf/sigo.yaml  -i box | \
# utilisation de PIMO pour reconvertir en id de zone originale
pimo -c conf/masking-post.yml  --load-cache zone=src/data/zone_index_cache.jsonl | \

tee src/data/sigo/all/yellow-tripdata_2023-06-23.jsonl | \
jq -s  -c '.' > src/data/sigo/all/yellow-tripdata_2023-06-23.json