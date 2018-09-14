#!/usr/bin/env bash

${ECHO} mkdir -p ${PREMOUNT_POSTGRESQL_OUTPUT_DIR}
cd ${PREMOUNT_POSTGRESQL_OUTPUT_DIR}

INVOCATION="${ECHO} sudo -u ${POSTGRESQL_SUDO_USER}"
DATABASES=$(sudo -u ${POSTGRESQL_SUDO_USER} psql -tqc 'SELECT datname FROM pg_database where datistemplate = false;')

PG_OPTIONS="--clean "

[[ ${VERBOSE} -ne 0 ]] &&  PG_OPTIONS+=" --verbose"

DATE="$(full_date)"
${ECHO} mkdir -p ${DATE}
${ECHO} chown -R postgres .

if which lbzip2 > /dev/null; then
    COMPRESS_COMMAND="nice -n 18 lbzip2"
else
    COMPRESS_COMMAND="nice -n 18 bzip2"
fi

# dump globals
${INVOCATION} pg_dumpall ${PG_OPTIONS} --globals-only -f ${DATE}/${DATE}-globals.sql

for d in ${DATABASES}
do
    [[ ${VERBOSE} -ne 0 ]] && echo "* dumping $d database"
    fileName="${DATE}/${DATE}-db-$d.sql"
    ${INVOCATION} pg_dump ${PG_OPTIONS} ${PREMOUNT_POSTGRESQL_PGDUMP_OPTIONS} -f ${fileName} ${d}
    ${ECHO} ${COMPRESS_COMMAND} -f9 ${fileName}
    ${ECHO} chmod 0400 ${fileName}.bz2
done

for i in `find . -type d -mtime +${PREMOUNT_POSTGRESQL_DELETE_FILES_OLDER_THAN} | sort`
do
    ${ECHO} rm -r $i
    [[ ${VERBOSE} -ne 0 ]] && echo "* removed $i"
done

exit 0
