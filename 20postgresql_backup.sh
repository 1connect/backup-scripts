#!/usr/bin/env bash
ECHO=

INVOCATION="$ECHO sudo -u $POSTGRESQL_SUDO_USER"
DATABASES=$(sudo -u $POSTGRESQL_SUDO_USER psql -tqc 'SELECT datname FROM pg_database where datistemplate = false;')

PG_OPTIONS="--clean "

if [[ $VERBOSE -ne 0 ]]
then
    PG_OPTIONS+=" --verbose"
fi

$ECHO chown postgres .

# dump globals
$INVOCATION pg_dumpall $PG_OPTIONS --globals-only -f globals-$(full_date).sql

for d in $DATABASES
do
    $INVOCATION pg_dump $PG_OPTIONS --create -f database-$d-$(full_date).sql $d
done

exit 0
