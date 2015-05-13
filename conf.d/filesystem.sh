#!/usr/bin/env bash

export FILESYSTEM_ENABLED=0

# they shoud match with the filesystem mount points
export FILESYSTEM_SRC_DIRECTORIES="/ /boot"

# how many times rsync shoud be run for each directory
export FILESYSTEM_RUN_COUNT=3

# file describing rsync exclusions
# todo support path
export FILESYSTEM_RSYNC_RULES_FILE="rsync_rules"
