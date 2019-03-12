#!/usr/bin/env bash


./bin/db-create.sh
./bin/etd-harvest.pl > ./caches/tsv/etd-harvest.tsv
./bin/db-initialize.sh
./bin/etd-iid2gid.sh
./bin/etd-download.sh