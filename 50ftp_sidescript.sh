#!/usr/bin/env bash

cd ..

$ECHO rmdir ftp


ARCHIVE="/tmp/db-${HOSTNAME}-`date +%Y-%m-%d`_`date +%s`.tar"

$ECHO tar -cf $ARCHIVE *
$ECHO bzip2 $ARCHIVE

cd /tmp

$ECHO ftp -n $FTP_HOST << EOF
user $FTP_LOGIN $FTP_PASSWORD
put `basename $ARCHIVE.bz2`
quit
EOF

$ECHO rm $ARCHIVE.bz2

PAST_DATE=`date --date="$FTP_DELETE_FILES_OLDER_THAN days ago" +%s`

listing=`$ECHO ftp -n $FTP_HOST << EOF2
user $FTP_LOGIN $FTP_PASSWORD
binary
ls
quit
EOF2
`
lista=( $listing )

# loop over our files
for ((FNO=0; FNO<${#lista[@]}; FNO+=9))
do
    fileName="${lista[`expr $FNO+8`]}"
    if [[ $fileName =~ (db\-)(${HOSTNAME}\-)(.+)_([0-9]+)(\.tar\.bz2) && ${BASH_REMATCH[4]} -lt $PAST_DATE ]]
    then
      [[ $VERBOSE -ne 0 ]] && echo "Removing $fileName"
#      $ECHO ftp -n $FTP_HOST << EOF3
#      user $FTP_LOGIN $FTP_PASSWORD
#      binary
#      delete $fileName
#      quit
#      EOF3
    fi
done

exit 0
