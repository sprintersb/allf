#!/bin/bash

for i in $(seq 0 $(( $1 - 1)) )
do
    echo -n " $i"
done
