#!/usr/bin/env bash

cd conf.d

if [ -f copy_attic_repository_rsync.sh ]; then
  mv copy_attic_repository_rsync.sh copy_borg_repository_rsync.sh
fi

sed -i -- 's/ATTIC/BORG/g' *.sh
