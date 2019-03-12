#!/usr/bin/env bash

# configure
DB='./etc/curate-nd.db'
ETDIID2GID='./bin/etd-iid2gid.pl'
SQL='SELECT iid from etds;'
URL='https://curate.nd.edu/downloads'
TSV='./caches/tsv/etd-gid.tsv'

# initialize
rm $TSV

# proces each item id in the database
echo $SQL | sqlite3 $DB | while read IID; do

	echo $IID >&2
	GID=$( $ETDIID2GID $IID )
	echo -e "$GID\t$URL/$GID" >> $TSV
		
done

# fini
exit