#!/usr/bin/env bash

# etd-iid2gid.sh - given a list of item identifiers, update the database with generic file identifiers

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# March 13, 2019 - first cut


# configure
DB='./etc/curate-nd.db'
HOST='localhost'
PORT=7890
SERVER='./bin/etd-iid2gid.pl'
SLEEP=5
SQL='SELECT iid FROM etds ORDER BY iid;'
TRANSACTIONS='./caches/sql/etd-iid2gid.sql';

# start the server and capture the process id
$SERVER &
PID=$!
sleep $SLEEP

# initialize sql
echo "BEGIN TRANSACTION;" > $TRANSACTIONS

# process each tsv file in the results directory
echo $SQL | sqlite3 $DB | while read IID; do
	
	# debug
	echo $IID >&2
	
	# search
	GID=$( echo "$IID" | nc $HOST $PORT )
	
	# debug
	echo $GID >&2
	echo >&2
	
	# update, conditionally
	if [[ ! -z $GID ]]; then
		echo "UPDATE etds SET gid = '$GID' WHERE iid IS '$IID';" >> $TRANSACTIONS
	fi

done

# terminate the server
kill $PID

# close transaction
echo "END TRANSACTION;" >> $TRANSACTIONS

# do the work and done
cat $TRANSACTIONS | sqlite3 $DB
exit