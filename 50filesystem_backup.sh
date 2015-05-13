#!/usr/bin/env bash

# Options to use for rsync
# (also see http://www.sanitarium.net/golug/rsync_backups.html)
RSYNCOPTS="--verbose --archive --hard-links --progress"
RSYNCOPTS+=" --delete --delete-excluded --numeric-ids --compress"
RSYNCOPTS+=" --chmod=u+rwx"

RULES="$CONFIG_DIR/$FILESYSTEM_RULES_FILE"

# do the backup itself (run a few times, since failing here kills the chain)
for i in `seq 1 $FILESYSTEM_RUN_COUNT`
do
  # todo opcje
  exec $(mcf rsync) ${RSYNCOPTS} --filter="merge $RULES" / ./
done
