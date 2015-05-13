#!/usr/bin/env bash

DATABASES=$(psql -tqc 'SELECT datname FROM pg_database where datistemplate = false;')
INVOCATION=$(mcf sudo -u $POSTGRESQL_SUDO_USER)

PG_OPTIONS="--clean "

if [[ $VERBOSE -ne 0 ]]
then
    PG_OPTIONS+=" --verbose"
fi

# dump globals
exec $INVOCATION "pg_dumpall $PG_OPTIONS --globals-only > globals-$(full_date).sql"

for d in $DATABASES
do
    exec $INVOCATION "pg_dump $PG_OPTIONS --create $d > database-$d-$(full_date).sql"
done

exit 0
