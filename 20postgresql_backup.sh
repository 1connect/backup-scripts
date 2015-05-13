#!/usr/bin/env bash

INVOCATION="$ECHO sudo -u $POSTGRESQL_SUDO_USER"
DATABASES=$(sudo -u $POSTGRESQL_SUDO_USER psql -tqc 'SELECT datname FROM pg_database where datistemplate = false;')

PG_OPTIONS="--clean "

[[ $VERBOSE -ne 0 ]] &&  PG_OPTIONS+=" --verbose"

$ECHO chown postgres .

# dump globals
$INVOCATION pg_dumpall $PG_OPTIONS --globals-only -f $(full_date)-globals.sql

for d in $DATABASES
do
    fileName="$(full_date)-db-%d.sql"
    $INVOCATION pg_dump $PG_OPTIONS --create -f $fileName $d
    $ECHO bzip2 -f9 ${fileName}
    $ECHO chmod 0400 ${fileName}.bz2
done

for i in `find . -mtime +${POSTGRESQL_DELETE_FILES_OLDER_THAN} | sort`
do
    $ECHO rm $i
done

exit 0
