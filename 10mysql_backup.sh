#!/bin/bash
##########################################################################
#
# mysql_backups.sh: A shell script to back up all MySQL databases in
#                   one shot, nightly, and keep a rolling 3 weeks of
#                   backups hot, online in the backup archive.
#
# Written by: David A. Desrosiers
# Contact: desrod@gnu-designs.com
# Last updated: Mon Feb 12 14:08:33 EST 2007
#
# Copyright 1998-2007.  This may be modified and distributed on the same
#                       terms as the GPL itself. This copyright header
#                       must remain intact if you use this script.
#
##########################################################################

DBS=`mysql -u${MYSQL_USER} -p${MYSQL_PASSWORD}  -h${MYSQL_HOST}  -e "show databases"`

for DATABASE in $DBS
do
        if [ $DATABASE != "Database" ]; then
                echo "Dumping $DATABASE now..."
								#BASE=${DATE}.${DATABASE}
								BASE=${DATABASE}
                $ECHO mysqldump -u${MYSQL_USER} \
                -p${MYSQL_PASSWORD} \
                -h{MYSQL_HOST} \
                --lock-tables --add-drop-table --skip-dump-date \
                -e $DATABASE > ${BASE}.sql

                $ECHO bzip2 -f9 ${BASE}.sql
                $ECHO chmod 0400 ${BASE}.sql.bz2
        fi
done

# Delete files older than 21 days
for i in `find . -mtime +21|sort`
do
    $ECHO rm $i
done

exit 0
