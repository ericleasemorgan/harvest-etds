#!/usr/bin/env bash

# subset.sh - given a few configurations, create a subset of files

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# October 17, 2022 - first cut


# configure
TSV='./metadata.tsv'
PDF='./pdf'
DESTINATION='./colleges/science'

IFS=$'\t'
mkdir -p $DESTINATION

cat $TSV | while read AUTHOR TITLE DATE DISCIPLINE DEGREE SOURCE; do

	SOURCE="$PDF/$SOURCE"
	cp $SOURCE $DESTINATION
	
done
