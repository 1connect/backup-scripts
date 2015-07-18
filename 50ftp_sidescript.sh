#!/usr/bin/env bash

cd ..

$ECHO rmdir ftp


ARCHIVE="/tmp/db-${HOSTNAME}-`date +%Y-%m-%d`_`date +%s`.tar"

# find files modified during last 2 hours
NEW_FILES=`find . -type f -mmin -120 | cut -sd / -f 2-`

$ECHO tar -cf $ARCHIVE $NEW_FILES
$ECHO bzip2 $ARCHIVE

cd /tmp

$ECHO ftp -n $FTP_HOST << EOF
user $FTP_LOGIN $FTP_PASSWORD
put `basename $ARCHIVE.bz2`
quit
EOF

$ECHO rm $ARCHIVE.bz2

PAST_DATE=`date --date="$FTP_DELETE_FILES_OLDER_THAN days ago" +%s`

listing=`ftp -n $FTP_HOST << EOF2
user $FTP_LOGIN $FTP_PASSWORD
binary
ls
quit
EOF2
`
lista=( $listing )

function delete_ftp_file {
$ECHO ftp -n $FTP_HOST << EOF3
      user $FTP_LOGIN $FTP_PASSWORD
      binary
      delete $1
      quit
EOF3
}

for ((FNO=0; FNO<${#lista[@]}; FNO+=9))
do
    fileName="${lista[`expr $FNO+8`]}"
    if [[ $fileName =~ (db\-)(${HOSTNAME}\-)(.+)_([0-9]+)(\.tar\.bz2) && ${BASH_REMATCH[4]} -lt $PAST_DATE ]]
    then
      [[ $VERBOSE -ne 0 ]] && echo "* removing $fileName"
      $(delete_ftp_file $fileName)
    fi
done

exit 0
