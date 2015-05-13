#!/usr/bin/env bash

cd ..

ARCHIVE=`/tmp/databases-$(full_date).tar`
tar -cf $ARCHIVE *
bzip2 $ARCHIVE

cd /tmp

$ECHO ftp -n $FTP_HOST << END_SCRIPT
user $FTP_LOGIN
$FTP_PASSWORD
put $ARCHIVE
quit
END_SCRIPT

rm $ARCHIVE

exit 0