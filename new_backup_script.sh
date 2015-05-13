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

# mutable command function
function mcf {
    [[ $TEST -gt 0 ]] && echo echo ${@:1} || echo ${@:1}
}
export -f mcf

OUTPUT_DIR="${LOCAL_DESTINATION}/${HOSTNAME}"

# put lock
PIDFILE="$OUTPUT_DIR/pidfile.pid"

if [ -s $PIDFILE ]; then
  PID=$(cat $PIDFILE)
  ps $PID > /dev/null
  if [ $? -eq 0 ]; then
    echo "Backup already running (PID $PID), exiting"
    exit 1
  fi
fi

echo $$ > $PIDFILE

# create backup directory
mkdir -p "$OUTPUT_DIR"

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

        export SCRIPT_OUTPUT_DIR="$OUTPUT_DIR/$scriptName"

        mkdir -p $SCRIPT_OUTPUT_DIR
        rm -rf $SCRIPT_OUTPUT_DIR/*

        currentDir=`pwd`
        cd $SCRIPT_OUTPUT_DIR && bash $scriptFile ; cd $currentDir
    fi
done

# TODO sychronize backup with onedrive etc

# remove lock
rm $PIDFILE