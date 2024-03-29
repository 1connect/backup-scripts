# Simple backup scripts

This is a collections of scripts, which automate the backup process of Linux server using [Borg](https://borgbackup.readthedocs.io), a deduplicating backup tool.

The starting point is `backup.sh`, which works in following way:
* The scripts starts.
* **premount** scripts are executed.
* If Borg repository is remote, it's mounted.
* **predump** scripts are executed.
* Borg creates backup point for each mountpoint defined in *general.sh*.
* **postdump** scripts are executed.
* If the repository is remote, it's unmounted.
* **postmount** scripts are executed.
* The scripts finish.

## Filesystem backup

Script creates separate backup point for each mount point, which are defined in `SRC_DIRECTORIES` variable in *general.sh* config file. The data it deduplicated and encrypted, usually resulting in archive, which is smaller than the filesystem.

The backup points have standardized names `{date}.{time}-{mount point}`. Examples:
* `2015-10-12.02.03-root_dir` for */*
* `2015-10-24.02.00-usr_local` for */usr/local*

## Databases backup

The plain file dump doesn't guarantee the database consistency. To address this issue, there are *premount* scripts, which dump PostgreSQL, MySQL and MongoDB databases to SQL files. Each database has it's separate file/directory, which is compressed and put into some directory in the filesystem (*/backup*) by default.

## Master Boot Record backup

Scripts dumps first 512 bytes for each drive defined in `PREMOUNT_MBR_PHYSICAL_DEVICES`. This area contains the MBR and partition table.

## Copying Borg repository to secondary location

`copy_borg_repository_rsync` side script can be used to copy the repository to secondary remote location, which increases survivability in case of storage failure.

## Installation

* Install required packages:

```bash
aptitude install sshfs borgbackup rsync lbzip2
```

* Checkout the repository, preferable to *root*'s home directory:

```
git clone https://github.com/1connect/backup-scripts
```

* Go to *backup-scripts/conf.d* directory. There are several *.example* files. To enable the module, copy it's configuration file to it's proper name:

```
cp example-general.sh general.sh
```

You shouldn't change name of the *example-* files, because you'll run into conflicts when you decide to pull the new version from the repository. *general.sh* is main configuration file, you should have it enabled and configured.

* After you're done with configuration, run the *backup.sh* script in verbose mode:

```
~/backup-scripts/backup.sh -v
```

First, it runs *premount* and *predump* modules. Then it initializes the Borg repository. You shouldn't set any password, because you won't be able to provide it during automated backup.

The very first run deduplicates your whole filesystem, it'll take long. The subsequent runs are much faster.

* Run the script the second time without the `-v` option. You shouldn't see any output.

* Add the script to Cron daemon. Edit your crontab with `crontab -e` command and add the following line to have it run every day at 0:25:

```
25 0 * * * /root/backup-scripts/backup.sh
```

## Restore data

List existing backups and choose the one which suits your needs the best.

```
borg list /my/backup/storage/myhostname/repository.borg/
```

Then access the files. The most convenient way is to use Borg *mount* feature:

```
borg mount /my/backup/storage/myhostname/repository.borg::{backup point} /tmp/restore
```

### Restore MongoDB

These commands will erase the content from the database and replace it with version from the backup.
```
cd /backup/mongodb/{date}
tar xf {database}.tar.bz2
mongorestore --db {database} --drop {database}
```

## Encryption keys

If you enabled encryption, Borg stores the encryption keys in `~/.config/borg/keys`. All keys are encrypted with password `backup`. The key to the security is to hold them in secure location. Remember to back up them separately; you won't be able to use your backup if you loose them!




