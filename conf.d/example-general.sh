#!/usr/bin/env bash

# If you want to backup to remote location using sshfs,
# fill the DST_REMOTE_LOCATION in the format indicated below.
# DST_LOCAL_LOCATION is just a mount point.
export DST_REMOTE_USER=root
export DST_REMOTE_HOST=example.org
export DST_REMOTE_PORT=22
export DST_REMOTE_LOCATION='/data/backup'
export DST_LOCAL_LOCATION='/tmp/backup'

# If you want to backup to local directory, fill
# DST_LOCAL_LOCATION with desired path and leave
# DST_REMOTE_LOCATION blank.
#export DST_REMOTE_LOCATION=''
#export DST_LOCAL_LOCATION='/data/backup'

# You should set whether you want to encrypt your backup
# valid values are: none, keyfile
# don't use 'repokey' mode since standard password 'backup' is provided to Borg calls
#export ENCRYPTION_MODE=none
export ENCRYPTION_MODE=keyfile

# they should match with the filesystem mount points
export SRC_DIRECTORIES="/ /boot"

export BORG_EXCLUDE_FILE="excludes.txt"

export BORG_PRUNE_AGES="--keep-within=14d --keep-weekly=8 --keep-monthly=6"


