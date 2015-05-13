#!/bin/bash

DBS=`mysql -e "show databases"`

MYSQL_OPTIONS="--skip-dump-date --routines --flush-privileges"

[[ $VERBOSE -ne 0 ]] && MYSQL_OPTIONS+=" --verbose"

for DATABASE in "$DBS mysql"
do
    if [ $DATABASE != "Database" ]
    then
        [[ $VERBOSE -ne 0 ]] && echo "Dumping $DATABASE now..."
		BASE="database-${DATABASE}-$(full_date).sql"
        $ECHO mysqldump $MYSQL_OPTIONS -e $DATABASE --result-file=${BASE}.sql

        $ECHO bzip2 -f9 ${BASE}.sql
        $ECHO chmod 0400 ${BASE}.sql.bz2
    fi
done

exit 0
