#!/bin/sh

rdom () { local IFS=\> ; read -d \< E C ;}

while rdom; do
    if [[ $E = $2 ]]; then
        echo "$C"
        if [[ $3 != "true" ]]; then
          exit
        fi
    fi
done < $1