#!/bin/bash


for path in src/vega/*.vg.solo.json; do
    filename="${path%.vg.solo.json}"
    filename="${filename#src/vega/}"
    title="${filename//_/\ }"
    dest="src/plot/${filename,,}.png"
    config=$(mktemp --suffix=.json )
    echo $title
    cat $path > $config
    echo "{ \"title\": \"$title\" }" >> $config
    cat $config | jq -s add | node_modules/vega-lite/bin/vl2png  -l debug -b src/data/ >  $dest
done


for dataset in original sigo; do
    for step in all passenger date localisation; do
        for path in src/vega/*.vg.json; do
            filename="${path%.vg.json}"
            filename="${filename#src/vega/}"
            title="${filename//_/\ }"
            dest="src/plot/${filename,,}-${dataset}-${step}.png"
            dest=$(echo ${dest//\'/_} | iconv -f utf8 -t ascii//TRANSLIT//IGNORE)
            config=$(mktemp --suffix=.json )
            echo $title
            cat $path > $config
            echo "{ \"title\": \"$title\" }" >> $config
            cat $config | jq -s add | node_modules/vega-lite/bin/vl2png  -l debug -b src/data/$dataset/$step/ >  $dest
        done
    done

done

