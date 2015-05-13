#!/bin/bash

DBS=`mysql -e "show databases"`

MYSQL_OPTIONS="--skip-dump-date --routines --flush-privileges"

[[ $VERBOSE -ne 0 ]] && MYSQL_OPTIONS+=" --verbose"

for DATABASE in $DBS
do
    if [[ $DATABASE != "Database" ]]
    then
        [[ $VERBOSE -ne 0 ]] && echo "Dumping $DATABASE now..."
        BASE="database-${DATABASE}-$(full_date).sql"
        $ECHO mysqldump $MYSQL_OPTIONS -e $DATABASE --result-file=${BASE}

        $ECHO bzip2 -f9 ${BASE}
        $ECHO chmod 0400 ${BASE}.bz2
    fi
done

exit 0
