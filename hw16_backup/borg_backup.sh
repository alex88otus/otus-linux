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
BACKUP_HOST=192.168.11.11
BACKUP_USER=borg
BACKUP_REPO=BACKUP
DATE=$(date --iso-8601=seconds)
LOG=/var/log/borg.log

# Make backup

echo "------------------------------------------------------------------------------
------------------------------------------------------------------------------
$DATE BORGBACKUP CREATE" >>$LOG
borg create -s -C lzma,9 "$BACKUP_USER"@"$BACKUP_HOST":"$BACKUP_REPO"::etc_{now} /etc 2>>$LOG
echo "DONE" >>$LOG

# Prune backup
echo "------------------------------------------------------------------------------
------------------------------------------------------------------------------
$DATE BORGBACKUP PRUNE
------------------------------------------------------------------------------" >>$LOG
borg prune -v --list "$BACKUP_USER"@"$BACKUP_HOST":"$BACKUP_REPO" --keep-within=30d --keep-monthly=2 2>>$LOG
echo "------------------------------------------------------------------------------
DONE" >>$LOG

# Delete lockfile
rm -f $LOCKFILE
