#!/usr/bin/env bash

# db-initialize.sh - given a specifically shaped tsv file, create skeleton records in a database

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# March 11, 2019 - first cut


# configure
DB='./etc/curate-nd.db'
TSV='./caches/tsv/etd-harvest.tsv'
TRANSACTIONS='./caches/sql/initialize-edt.sql'
IFS=$'\t'

# initialize
echo "BEGIN TRANSACTION;" > $TRANSACTIONS

# Process each record in the tsv file
while read RECORD; do

	# parse
	FIELDS=($RECORD)
	IID=${FIELDS[0]}
	MODEL=${FIELDS[1]}
	CREATOR=${FIELDS[2]}
	TITLE=${FIELDS[3]}
	DATE=${FIELDS[4]}
	DEPARTMENT=${FIELDS[5]}

	TITLE="${TITLE//\'/''}"
	CREATOR="${CREATOR//\'/''}"
		
	# re-initialize, debug, and update
	SQL="INSERT INTO etds ( 'iid', 'model', 'creator', 'title', 'date', 'department' ) VALUES ( '$IID', '$MODEL', '$CREATOR', '$TITLE', '$DATE', '$DEPARTMENT' );"
	echo $SQL >&2
	echo $SQL >> $TRANSACTIONS
	
done < $TSV

# close transaction
echo "END TRANSACTION;" >> $TRANSACTIONS

# do the work and done
cat $TRANSACTIONS | sqlite3 $DB
exit