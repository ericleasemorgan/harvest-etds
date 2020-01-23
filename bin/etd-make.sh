#!/usr/bin/env bash

# etd-make.sh - one script to rule them all

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# March   12, 2019 - first cut; brain dead
# January 22, 2020 - added years, availability, and index; won't work on a single machine though


# do the work
./bin/db-create.sh
./bin/etd-harvest.pl > ./caches/tsv/etd-harvest.tsv
./bin/db-initialize.sh
./bin/etd-iid2gid.sh
<<<<<<< HEAD
./bin/etd-addyear.sh 
=======
>>>>>>> 620f75937fecdaad25321db8d7d561192d4476b0
./bin/etd-download.sh
find pdf -name '*.pdf' | parallel ./bin/file2txt.sh {}
./bin/etd-availability.sh
./bin/index.pl

# done
exit
