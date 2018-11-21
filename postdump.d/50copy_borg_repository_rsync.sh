#!/usr/bin/env bash

RSYNC_OPTIONS="--recursive --timeout=60 --compress --safe-links --delete --one-file-system"

[[ ${VERBOSE} -ne 0 ]] && RSYNC_OPTIONS+=" --progress --stats --verbose --human-readable "

userAndHost="${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_USER}@${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_HOST}"
outputDirectory="${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_PATH}/${HOSTNAME}"

TEMP_DIR=`mktemp -d`
sshfs -p ${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_PORT} ${userAndHost}: ${TEMP_DIR}
mkdir -p ${TEMP_DIR}/${outputDirectory}
umount ${TEMP_DIR}
rmdir ${TEMP_DIR}

rsync ${RSYNC_OPTIONS} -e "ssh -p ${POSTDUMP_COPY_BORG_REPOSITORY_RSYNC_SSH_PORT}" ${BORG_REPOSITORY_PATH} ${userAndHost}:${outputDirectory}

