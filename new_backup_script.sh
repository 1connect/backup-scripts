#!/usr/bin/env bash

#
# server backup script
# 05.2015 Michał Słomkowski
#

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
HOSTNAME=`hostname`
export CONFIG_DIR="${SCRIPT_DIR}/conf.d"

# load all config files
for confFile in `ls ${CONFIG_DIR}/*.sh`
do
    . "${confFile}"
done

if [[ $TEST -ne 0 ]]
then
    export ECHO=echo
fi

function full_date {
    eval date +'%Y-%m-%d.%H.%M.%S'
}

export -f full_date

# put lock
PIDFILE="/tmp/backup_scripts.pid"

if [ -s $PIDFILE ]; then
  PID=$(cat $PIDFILE)
  ps $PID > /dev/null
  if [ $? -eq 0 ]; then
    echo "Backup already running (PID $PID), exiting"
    exit 1
  fi
fi

echo $$ > $PIDFILE

for scriptFile in `ls ${SCRIPT_DIR}/*.sh`
do
    if [[ `basename $scriptFile` =~ ([0-9]+?)([a-z]+)(_backup\.sh) ]]
    then
        scriptName=${BASH_REMATCH[2]}
        scriptEnabledVariableName=`echo $scriptName | tr [a-z] [A-Z]`_ENABLED

        if [[ ${!scriptEnabledVariableName} -eq 0 ]]
        then
            continue
        fi

        export SCRIPT_OUTPUT_DIR="${SIDE_SCRIPTS_DESTINATION}/${scriptName}"

        mkdir -p $SCRIPT_OUTPUT_DIR
        rm -rf $SCRIPT_OUTPUT_DIR/*

        currentDir=`pwd`
        cd $SCRIPT_OUTPUT_DIR && bash $scriptFile ; cd $currentDir
    fi
done

# Options to use for rsync
# (also see http://www.sanitarium.net/golug/rsync_backups.html)
RSYNCOPTS="--archive --hard-links --one-file-system"
RSYNCOPTS+="--delete --delete-excluded --numeric-ids"

[[ $VERBOSE -ne 0 ]] && RSYNCOPTIONS+=" --verbose --progress"

RSYNC_RULES="$CONFIG_DIR/$RSYNC_RULES_FILE"

for directory in $SRC_DIRECTORIES
do
    # do the backup itself (run a few times, since failing here kills the chain)
    for i in `seq 1 $RSYNC_RUN_COUNT`
    do
        # todo opcje i ten katalog końcowy
        $ECHO rsync ${RSYNCOPTS} --filter="merge $RSYNC_RULES" $directory `pwd`/$directory
    done
done

# TODO sychronize backup with onedrive etc

# remove lock
rm $PIDFILE