#!/usr/bin/env bash

#
# server backup script
# 2015, 2016 Michał Słomkowski
#

export TEST=0
export VERBOSE=0
SIDE_SCRIPTS_ONLY=0

function show_help {
    echo "Usage: todo" # todo write usage
}

while getopts "h?vts" opt; do
    case "${opt}" in
    h|\?)
        show_help
        exit 0
        ;;
    v)  export VERBOSE=1
        ;;
    t)  export TEST=1
        export ECHO=echo
        ;;
    s)  SIDE_SCRIPTS_ONLY=1
        ;;
    esac
done

SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export CONFIG_DIR="${SCRIPT_DIR}/conf.d"

# load all config files
for confFile in `find "${CONFIG_DIR}" -name '*.sh' ! -name 'example-*'`
do
    . "${confFile}"
done

function full_date {
    eval date +'%Y-%m-%d.%H.%M'
}

function run_sidescripts {
    [[ ${VERBOSE} -ne 0 ]] && echo "** running side scripts in phase ${1}"

    for scriptFile in `find "${SCRIPT_DIR}" -path '*/'"${1}.d/"'*.sh' | sort -n`
    do
        if [[ `basename ${scriptFile}` =~ ([0-9]+?)([a-z_]+)(\.sh) ]]
        then
            scriptName=${BASH_REMATCH[2]}
            scriptEnabledVariableName=`echo ${1}_${scriptName} | tr '[a-z]' '[A-Z]'`_ENABLED

            if [[ ${!scriptEnabledVariableName} -ne 1 ]]
            then
                continue
            fi

            export SCRIPT_TMP_DIR=`mktemp -d --suffix=_${1}_${scriptName}`

            currentDir=`pwd`
            cd ${SCRIPT_TMP_DIR}

    	    [[ ${VERBOSE} -ne 0 ]] && echo "* running ${scriptName}"
    	    bash ${scriptFile}

    	    cd ${currentDir}
    	    rm -r ${SCRIPT_TMP_DIR}
        fi
    done
}

export -f full_date

# put lock
PID_FILE="/tmp/backup_scripts.pid"

if [ -s ${PID_FILE} ]; then
  PID=$(cat ${PID_FILE})
  ps ${PID} > /dev/null
  if [ ${?} -eq 0 ]; then
    echo "Backup already running (PID ${PID}), aborting."
    exit 1
  fi
fi

[[ ${ECHO} != '' ]] && echo "echo $$ > ${PID_FILE}" || echo $$ > ${PID_FILE}

run_sidescripts premount

BORG_OPTIONS=""
export BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK=yes
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

if [[ ${SIDE_SCRIPTS_ONLY} -eq 0 ]]
then
    if [ -n "${DST_REMOTE_LOCATION}" ]
    then
        ${ECHO} mkdir -p ${DST_LOCAL_LOCATION}
        ${ECHO} sshfs -p ${DST_REMOTE_PORT} ${DST_REMOTE_USER}@${DST_REMOTE_HOST}:${DST_REMOTE_LOCATION} ${DST_LOCAL_LOCATION}
    fi

    run_sidescripts predump

    out="${DST_LOCAL_LOCATION}/${HOSTNAME}"
    ${ECHO} mkdir -p ${out}
    out+='/repository.borg'
    export BORG_REPOSITORY_PATH="${out}"

    if [[ "${VERBOSE}" -ne 0 ]]
    then
        BORG_OPTIONS+=" --stats"
        echo "** starting Borg backup"
    fi

    export BORG_PASSPHRASE='backup'

    if [ ! -d ${BORG_REPOSITORY_PATH} ]
    then
        ${ECHO} borg init --encryption=${ENCRYPTION_MODE} ${BORG_REPOSITORY_PATH}
    fi

    for directory in ${SRC_DIRECTORIES}
    do
        if [[ `basename ${directory}` == '/' ]]
        then
            prefix="root_dir"
        else
            prefix=`basename ${directory} | tr '/' '__' `
        fi

        # construct exclude list
        EXCLUDE_LIST="--exclude ${DST_LOCAL_LOCATION} "
        for entry in `cat ${CONFIG_DIR}/excludes.txt`
        do
            EXCLUDE_LIST+=" --exclude ${entry}"
        done

        for entry in ${SRC_DIRECTORIES}
        do
            if [ ${entry} != ${directory} ]
            then
                if [ "${directory##$entry}" == "${directory}" ]
                then
                    EXCLUDE_LIST+=" --exclude ${entry}"
                fi
            fi
        done

        ${ECHO} ionice -c3 -t borg create ${BORG_OPTIONS} --one-file-system ${BORG_REPOSITORY_PATH}::$(full_date)-${prefix} ${directory} ${EXCLUDE_LIST}
    done

    ${ECHO} ionice -c3 -t borg prune ${BORG_OPTIONS} ${BORG_REPOSITORY_PATH} ${BORG_PRUNE_AGES}

    run_sidescripts postdump

    sleep 3

    if [ -n "${DST_REMOTE_LOCATION}" ]
    then
        ${ECHO} umount ${DST_LOCAL_LOCATION}
        ${ECHO} rmdir ${DST_LOCAL_LOCATION}
    fi

    run_sidescripts postumount
fi

# remove lock
${ECHO} rm ${PID_FILE}
