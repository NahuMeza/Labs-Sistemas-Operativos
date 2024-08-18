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