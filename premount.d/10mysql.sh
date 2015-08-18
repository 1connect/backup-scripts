#!/usr/bin/env bash

DBS=`mysql -e "show databases"`

MYSQL_OPTIONS="--skip-dump-date --routines --flush-privileges --add-drop-database "
MYSQL_OPTIONS+=" --ignore-table=mysql.event --single-transaction --extended-insert"

[[ $VERBOSE -ne 0 ]] && MYSQL_OPTIONS+=" --verbose"

cd $PREMOUNT_MYSQL_OUTPUT_DIR

DATE="$(full_date)"
$ECHO mkdir -p $DATE

for DATABASE in $DBS
do
    if [[ $DATABASE != "Database" ]]
    then
        [[ $VERBOSE -ne 0 ]] && echo "* dumping $DATABASE database"
        BASE="${DATE}/${DATE}-db-${DATABASE}.sql"
        $ECHO mysqldump $MYSQL_OPTIONS --databases $DATABASE --result-file=${BASE}

        $ECHO bzip2 -f9 ${BASE}
        $ECHO chmod 0400 ${BASE}.bz2
    fi
done

for i in `find . -type d -mtime +${MYSQL_DELETE_FILES_OLDER_THAN} | sort`
do
    $ECHO rm -r $i
    [[ $VERBOSE -ne 0 ]] && echo "* removed $i"
done

exit 0
