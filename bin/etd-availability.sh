#!/usr/bin/env bash

SQL='select ltrim(gid,"und:") from etds order by gid;'
DB='./etc/curate-nd.db'
FILESYSTEM='/afs/crc.nd.edu/user/e/emorgan/local/html/etds/txt'
TRANSACTIONS='./caches/sql/availability.sql'

echo "BEGIN TRANSACTION;" > $TRANSACTIONS

echo $SQL | sqlite3 $DB | while read GID; do

	FILE="$FILESYSTEM/$GID.txt"
	if [[ -f $FILE ]]; then
		echo "UPDATE etds SET availability = 'downloadable' WHERE gid = 'und:$GID';" >> $TRANSACTIONS
	else
		echo "UPDATE etds SET availability = 'embargoed'    WHERE gid = 'und:$GID';" >> $TRANSACTIONS
	fi

done

echo "END TRANSACTION;" >> $TRANSACTIONS
cat $TRANSACTIONS | sqlite3 $DB

exit