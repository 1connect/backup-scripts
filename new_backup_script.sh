#!/usr/bin/env bash

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
HOSTNAME=`hostname`

# load all config files
for confFile in `ls ${SCRIPT_DIR}/conf.d/*.sh`
do
    . "${confFile}"
done

# put lock
if [ -s $PIDFILE ]; then
  PID=$(cat $PIDFILE)
  ps $PID > /dev/null
  if [ $? -eq 0 ]; then
    echo "Backup already running(PID $PID), exiting"
    exit 1
  fi
fi

echo $$ > $PIDFILE

# create backup directory
mkdir -p "${LOCAL_DESTINATION}/${HOSTNAME}"

BACKUP_SCRIPTS=`ls ${SCRIPT_DIR}/*backup.sh`
for backupScript in "$BACKUP_SCRIPTS"
do
    echo $backupScript
done

if [ -s $PIDFILE ]; then
  PID=$(cat $PIDFILE)
  ps $PID > /dev/null
  if [ $? -eq 0 ]; then
    echo "Backup already running(PID $PID), exiting"
    exit 1
  fi
fi

# TODO sychronize backup with onedrive etc

# remove lock
rm $PIDFILEE