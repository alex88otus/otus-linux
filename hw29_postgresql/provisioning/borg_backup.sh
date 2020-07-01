#!/bin/bash

LOCKFILE=/tmp/lockfile
if [ -e $LOCKFILE ] && kill -0 "$(cat $LOCKFILE)"; then
    echo "already running"
    exit
fi

# Make sure the lockfile is removed when we exit and then claim it
trap 'rm -f $LOCKFILE; exit' INT TERM EXIT
echo $$ >$LOCKFILE

# Configure backup
export BORG_PASSPHRASE=Qwerty1234
BACKUP_REPO=/home/vagrant/pg_borg_backups
DATE=$(date --iso-8601=seconds)
LOG=/var/log/borg.log

# Init repo
if [ ! -d $BACKUP_REPO ]; then
    echo "------------------------------------------------------------------------------" >>/var/log/borg.log
    echo "------------------------------------------------------------------------------" >>/var/log/borg.log
    echo "$DATE BORGBACKUP INIT" >>/var/log/borg.log
    echo "------------------------------------------------------------------------------" >>/var/log/borg.log
    borg init -e repokey $BACKUP_REPO 2>>/var/log/borg.log
    echo "------------------------------------------------------------------------------" >>/var/log/borg.log
    echo "DONE" >>/var/log/borg.log
fi

# Make backup
sudo -u postgres pg_basebackup -h 192.168.11.10 -D /var/lib/pgsql/12/data -U repluser -v --wal-method=stream -R -P -w
echo "------------------------------------------------------------------------------
------------------------------------------------------------------------------
$DATE BORGBACKUP CREATE" >>$LOG
borg create -s -C lzma,9 "$BACKUP_REPO"::postgres_{now} /var/lib/pgsql/12/data 2>>$LOG
echo "DONE" >>$LOG
sudo -u postgres rm -rf /var/lib/pgsql/12/data
# Prune backup
echo "------------------------------------------------------------------------------
------------------------------------------------------------------------------
$DATE BORGBACKUP PRUNE
------------------------------------------------------------------------------" >>$LOG
borg prune -v --list "$BACKUP_REPO" --keep-within=100d 2>>$LOG
echo "------------------------------------------------------------------------------
DONE" >>$LOG

# Delete lockfile
rm -f $LOCKFILE
