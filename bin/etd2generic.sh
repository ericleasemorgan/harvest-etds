#!/usr/bin/env bash

ETD='./etc/etd.tsv'
ETD2GENERIC='./bin/etd2generic.pl'

while read RECORD; do

	FIELDS=($RECORD)
	CID="${FIELDS[0]}"
	
	echo $CID >&2
	$ETD2GENERIC $CID
	
done < $ETD