#!/usr/bin/env bash

#
# server backup script
# 05.2015 Michał Słomkowski
#

export TEST=0
export VERBOSE=0
SIDESCRIPTS_ONLY=0

function show_help {
    echo "Usage: blablabla"
}

while getopts "h?vts" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  export VERBOSE=1
        ;;
    t)  export TEST=1
        export ECHO=echo
        ;;
    s)  SIDESCRIPTS_ONLY=1
        ;;
    esac
done

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
HOSTNAME=`hostname`
export CONFIG_DIR="${SCRIPT_DIR}/conf.d"

# load all config files
for confFile in `ls ${CONFIG_DIR}/*.sh`
do
    . "${confFile}"
done

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

[[ $ECHO != '' ]] && echo "echo $$ > $PIDFILE" || echo $$ > $PIDFILE

for scriptFile in `ls ${SCRIPT_DIR}/*.sh`
do
    if [[ `basename $scriptFile` =~ ([0-9]+?)([a-z]+)(_sidescript\.sh) ]]
    then
        scriptName=${BASH_REMATCH[2]}
        scriptEnabledVariableName=`echo $scriptName | tr [a-z] [A-Z]`_ENABLED

        if [[ ${!scriptEnabledVariableName} -eq 0 ]]
        then
            continue
        fi

        export SCRIPT_OUTPUT_DIR="${SIDE_SCRIPTS_DESTINATION}/${scriptName}"

        $ECHO mkdir -p $SCRIPT_OUTPUT_DIR
        $ECHO rm -rf $SCRIPT_OUTPUT_DIR/*

        [[ $VERBOSE -ne 0 ]] && echo "* running $scriptName"

        currentDir=`pwd`
        cd $SCRIPT_OUTPUT_DIR
	bash $scriptFile
	cd $currentDir
    fi
done

# Options to use for rsync
# (also see http://www.sanitarium.net/golug/rsync_backups.html)
RSYNCOPTS="--archive --hard-links --one-file-system "
RSYNCOPTS+="--delete --delete-excluded --numeric-ids "

if [[ $VERBOSE -ne 0 ]]
then
    RSYNCOPTIONS+=" --verbose --progress"
    echo "* starting rsync"
fi

RSYNC_RULES="$CONFIG_DIR/$RSYNC_RULES_FILE"

if [[ $SIDESCRIPTS_ONLY -eq 0 ]]
then
    for directory in $SRC_DIRECTORIES
    do
        out="$DST_DIRECTORY/$HOSTNAME"
        if [[ `basename $directory` == '/' ]]
        then
            out+="/rootdir"
        else
            out+=/`basename $directory | tr '/' '__' `
        fi

        if [[ DST_REMOTE != '' ]]
        then
            $ECHO ssh $DST_REMOTE "mkdir -p $out"
            fullPath="$DST_REMOTE:$out"
        else
            $ECHO mkdir -p $out
            fullPath=$out
        fi

        # do the backup itself (run a few times, since failing here kills the chain)
        for i in `seq 1 $RSYNC_RUN_COUNT`
        do
            $ECHO rsync ${RSYNCOPTS} --filter="merge $RSYNC_RULES" $directory $fullPath
        done
    done
fi

# TODO sychronize backup with onedrive etc

# remove lock
$ECHO rm $PIDFILE
