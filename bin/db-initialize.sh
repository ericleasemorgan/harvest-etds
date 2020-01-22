#!/usr/bin/env bash

# db-initialize.sh - given a specifically shaped tsv file, create skeleton records in a database

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# March   11, 2019 - first cut
# January 20, 2020 - added contributors, abstract, and subjects; Martin Luther King Day


# configure
DB='./etc/curate-nd.db'
TSV='./caches/tsv/etd-harvest.tsv'
TRANSACTIONS='./caches/sql/initialize-edt.sql'
CONTRIBUTOR='./caches/sql/contributor.sql'
SUBJECT='./caches/sql/subject.sql'
IFS=$'\t'

# initialize
echo "BEGIN TRANSACTION;" > $TRANSACTIONS
echo "BEGIN TRANSACTION;" > $CONTRIBUTOR
echo "BEGIN TRANSACTION;" > $SUBJECT

# Process each record in the tsv file
I=0
while read RECORD; do

	let "I=I+1"
	if [[ $I == 1 ]]; then continue; fi

	# parse
	FIELDS=($RECORD)
	IID=${FIELDS[0]}
	MODEL=${FIELDS[1]}
	CREATOR=${FIELDS[2]}
	TITLE=${FIELDS[3]}
	DATE=${FIELDS[4]}
	COLLEGE=${FIELDS[5]}
	ABSTRACT=${FIELDS[6]}
	CONTRIBURTORS=${FIELDS[7]}
	SUBJECTS=${FIELDS[8]}
	DEGREE=${FIELDS[9]}
	DISCIPLINE=${FIELDS[10]}

	TITLE="${TITLE//\'/''}"
	CREATOR="${CREATOR//\'/''}"
	ABSTRACT=$( echo $ABSTRACT | sed "s/\n/ /g" )
	ABSTRACT=$( echo $ABSTRACT | sed "s/ +/ /g" )
	ABSTRACT=$( echo $ABSTRACT | sed "s/'/''/g" )
		
	# bibliographics; re-initialize, debug, and update
	SQL="INSERT INTO etds ( 'iid', 'model', 'creator', 'title', 'date', 'college', 'abstract', 'degree', 'discipline' ) VALUES ( '$IID', '$MODEL', '$CREATOR', '$TITLE', '$DATE', '$COLLEGE', '$ABSTRACT', '$DEGREE', '$DISCIPLINE' );"
	echo $SQL >&2
	echo      >&2
	echo $SQL >> $TRANSACTIONS
		
	# output contributors; reconfigure
	IFS='|'
	read -r -a CONTRIBUTORS <<< "$CONTRIBURTORS"
	for ITEM in "${CONTRIBUTORS[@]}"; do
		
		# escape
		ITEM="${ITEM//\'/''}"
		
		# contributors; re-initialize, debug, and update
		SQL="INSERT INTO contributors ( 'iid', 'contributor' ) VALUES ( '$IID', '$ITEM' );"
		echo $SQL >&2
		echo      >&2
		echo $SQL >> $CONTRIBUTOR
	
	done 

	# output subjects; reconfigure
	IFS='|'
	read -r -a SUBJECTS <<< "$SUBJECTS"
	for ITEM in "${SUBJECTS[@]}"; do
		
		# escape
		ITEM="${ITEM//\'/''}"
		
		# subjects; re-initialize, debug, and update
		SQL="INSERT INTO subjects ( 'iid', 'subject' ) VALUES ( '$IID', '$ITEM' );"
		echo $SQL >&2
		echo      >&2
		echo $SQL >> $SUBJECT
	
	done 

	# re-configure
	IFS=$'\t'
	
done < $TSV

# close transactions
echo "END TRANSACTION;" >> $TRANSACTIONS
echo "END TRANSACTION;" >> $CONTRIBUTOR
echo "END TRANSACTION;" >> $SUBJECT

# do the work and done
cat $TRANSACTIONS | sqlite3 $DB
cat $CONTRIBUTOR  | sqlite3 $DB
cat $SUBJECT      | sqlite3 $DB
exit