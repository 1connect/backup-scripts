#!/usr/bin/env bash

RSYNC_OPTIONS="-rzx --safe-links --delete"

[[ ${VERBOSE} -ne 0 ]] && RSYNC_OPTIONS+=" --progress --stats --verbose -h "

userAndHost="${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_USER}@${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_HOST}"
outputDirectory="${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_PATH}/${HOSTNAME}"

ssh -p ${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_PORT} ${userAndHost} "mkdir -p ${outputDirectory}"

rsync ${RSYNC_OPTIONS} -e "ssh -p ${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_PORT}" ${BORG_REPOSITORY_PATH} ${userAndHost}:${outputDirectory}

