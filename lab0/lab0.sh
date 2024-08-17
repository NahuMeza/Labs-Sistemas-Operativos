#!/bin/bash

# EJERCICIO 1
cat /proc/cpuinfo | grep "model name"
# EJERCICIO 2
cat /proc/cpuinfo | grep "model name" | wc -l
# EJERCICIO 3
wget https://raw.githubusercontent.com/dariomalchiodi/superhero-datascience/master/content/data/heroes.csv && cat -s heroes.csv | awk -F';' '{print $2}' | awk 'NF' | awk '{print tolower($0)}' | tr -d ' ' 
# EJERCICIO 4