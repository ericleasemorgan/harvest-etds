#!/usr/bin/env bash

# configure
SQL='UPDATE etds SET year = substr( date, 1, 4 );'
DB='./etc/curate-nd.db'

# do the work and done
echo $SQL | sqlite3 $DB
exit
