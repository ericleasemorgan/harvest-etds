#!/usr/bin/env bash

# etd-download.sh - given a generic file identifier, output a PDF file; a front-end to etd-download.pl

# Eric Lease Morgan <emorgan@nd.edu>
# (c) University of Notre Dame; distributed under a GNU Public License

# March 12, 2019 - first cut


# configure
DB='./etc/curate-nd.db'
SQL="SELECT gid FROM etds WHERE gid LIKE 'und%' ORDER BY gid;"
ROOT='https://curate.nd.edu/downloads'
DOWNLOADS='./pdf'
ETDDOWNLOAD='./bin/etd-download.pl'

# process each gid in the database
echo $SQL | sqlite3 $DB | while read GID; do
	
	# debug
	echo $GID >&2
	
	# parse
	GID=$( echo $GID | sed "s/und://" )
	echo $GID >&2
	
	# build url
	URL="$ROOT/$GID"
	echo $URL >&2
	
	# build output
	PDF="$DOWNLOADS/$GID.pdf"
	echo $PDF >&2
	
	# do the work, conditionally
	if [[ ! -f "$PDF" ]]; then $ETDDOWNLOAD $URL $PDF; fi
	echo >&2
	
done

# fini
exit
