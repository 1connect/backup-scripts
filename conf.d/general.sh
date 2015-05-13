#!/usr/bin/env bash

export TEST=1

export VERBOSE=1

# todo
export SIDE_SCRIPTS_DESTINATION="/tmp/adds"

export DESTINATION="/tmp/backup"

# they shoud match with the filesystem mount points
export SRC_DIRECTORIES="/ /boot"

# how many times rsync shoud be run for each directory
export RSYNC_RUN_COUNT=3

# file describing rsync exclusions
# todo support path
export RSYNC_RULES_FILE="rsync_rules"

