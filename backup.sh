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
export HOSTNAME=`hostname`
export CONFIG_DIR="${SCRIPT_DIR}/conf.d"

# load all config files
for confFile in `ls ${CONFIG_DIR}/*.sh`
do
    . "${confFile}"
done

function full_date {
    eval date +'%Y-%m-%d.%H.%M'
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

        [[ $VERBOSE -ne 0 ]] && echo "* running $scriptName"

        currentDir=`pwd`
        cd $SCRIPT_OUTPUT_DIR
	    bash $scriptFile
	    cd $currentDir
    fi
done

ATTIC_OPTIONS=""

if [[ $SIDESCRIPTS_ONLY -eq 0 ]]
then
    if [[ $VERBOSE -ne 0 ]]
    then
        ATTIC_OPTIONS+=" --stats"
        echo "* starting attic backup"
    fi

    $ECHO sshfs $DST_REMOTE_LOCATION $DST_LOCAL_MOUNT_POINT

    for directory in $SRC_DIRECTORIES
    do
        out="$DST_LOCAL_MOUNT_POINT/$HOSTNAME"

        $ECHO mkdir -p $out

        if [[ `basename $directory` == '/' ]]
        then
            out+="/root_dir.attic"
        else
            out+=/`basename $directory | tr '/' '__' `.attic
        fi

        # construct exclude list
        EXCLUDE_LIST=''
        for entry in `cat ${CONFIG_DIR}/excludes.txt`
        do
            EXCLUDE_LIST+=" --exclude $entry"
        done

        for entry in $SRC_DIRECTORIES
        do
            if [ $entry != $directory ]
            then
                if [ "${directory##$entry}" == "${directory}" ]
                then
                    EXCLUDE_LIST+=" --exclude $entry"
                fi
            fi
        done

        if [ ! -d $out ]
        then
            $ECHO attic init --encryption=keyfile $out
        fi

        $ECHO attic create $ATTIC_OPTIONS ${out}::$(full_date) $directory $EXCLUDE_LIST

        $ECHO attic prune $ATTIC_OPTIONS ${out} $ATTIC_PRUNE_AGES
    done

    $ECHO umount $DST_LOCAL_MOUNT_POINT
fi

# remove lock
$ECHO rm $PIDFILE
