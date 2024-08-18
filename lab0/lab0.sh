#!/bin/bash

# EJERCICIO 1
cat /proc/cpuinfo | grep "model name"
# EJERCICIO 2
cat /proc/cpuinfo | grep "model name" | wc -l
# EJERCICIO 3
wget https://raw.githubusercontent.com/dariomalchiodi/superhero-datascience/master/content/data/heroes.csv && cat -s heroes.csv | awk -F';' '{print $2}' | awk 'NF' | awk '{print tolower($0)}' | tr -d ' ' 
# EJERCICIO 4
 #Dia de mayor temperatura
sort -k 5nr weather_cordoba.in | head -n 1| awk -F' ' '{print $1, $2, $3}'
 #Dia de menor temperatura
sort -k 6n weather_cordoba.in | head -n 1| awk -F' ' '{print $1, $2, $3}'
#EJERCICIO 5 
sort -k 3n atpplayers.in
#EJERCICIO 6
awk -F' ' '{print $0, $7 - $8}' superliga.in | sort -k 2nr -k 9nr | awk -F' ' '{$9 = ""; print $0}' | cat -n
#EJERCICIO 7
ip address | grep "link/ether"
#EJERCICIO 8
mkdir subcaps && for i in {01..10}; do touch ./subcaps/"fma_S01E${i}_es.srt"; done
cd subcaps
for i in *_es.srt; do mv "$i" "${i/_es.srt/.srt}"; done;
#EJERCICIO 9
 #a
ffmpeg -ss 00:00:02 -to 00:00:07 -i sistops-2024-08-18_12.11.37.mp4 -c copy copy.mp4 #alguna forma de hacerlo sin saber la duracion del video?
ffmpeg -i voice.mp3 -i music.mp3 -filter_complex "[0:a]volume=1.3[a1]; [1:a]volume=0.5[a2]; [a1][a2]amix=inputs=2:duration=shortest:dropout_transition=3[out]" -map "[out]" podcast.mp3
