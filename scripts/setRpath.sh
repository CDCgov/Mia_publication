#!/bin/bash

root=$(readlink -f $(dirname $0) | sed 's/\//\\\//g' | rev | cut -d '/' -f 2- | rev)
root=${root::-1}

sed -i "s/ROOT/${root}/" MIA.R
