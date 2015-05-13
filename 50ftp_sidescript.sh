#!/usr/bin/env bash

cd ..

$ECHO rmdir ftp

ARCHIVE="/tmp/databases-$(full_date).tar"

$ECHO tar -cf $ARCHIVE *
$ECHO bzip2 $ARCHIVE

cd /tmp

$ECHO ftp -n $FTP_HOST << END_SCRIPT
user $FTP_LOGIN $FTP_PASSWORD
put `basename $ARCHIVE.bz2`
quit
END_SCRIPT

$ECHO rm $ARCHIVE.bz2

exit 0

