#!/usr/bin/env bash

[[ $VERBOSE -eq 0 ]] && MONGODB_OPTIONS+=" --quiet "

[[ $VERBOSE -eq 1 ]] && TAR_OPTIONS+=" -v "

$ECHO mkdir -p ${PREMOUNT_MONGODB_OUTPUT_DIR}
cd ${PREMOUNT_MONGODB_OUTPUT_DIR}

DATE="$(full_date)"
$ECHO mkdir -p $DATE

BASEDIR="${DATE}"

[[ $VERBOSE -ne 0 ]] && echo "* dumping MongoDB database 'local'"
$ECHO mongodump --quiet --db local -o ${BASEDIR}

[[ $VERBOSE -ne 0 ]] && echo "* dumping remaining MongoDB databases"
$ECHO mongodump --quiet -o ${BASEDIR}

cd ${BASEDIR}

for dbDir in `ls`
do
    ARCHIVE="${dbDir}.tar.bz2"
    $ECHO tar -cjSf $TAR_OPTIONS ${ARCHIVE} ${dbDir}
    $ECHO rm -r ${dbDir}
    $ECHO chmod 0400 ${ARCHIVE}
done

cd ..

for i in `find . -type d -mtime +${PREMOUNT_MONGODB_DELETE_FILES_OLDER_THAN} | sort`
do
    $ECHO rm -r $i
    [[ $VERBOSE -ne 0 ]] && echo "* removed $i"
done

exit 0
