#!/bin/bash
export BORG_PASSPHRASE=Qwerty1234

/usr/local/bin/./borg create -s -C lzma,9 borg@192.168.11.11:BACKUP::client-etc_{now} /etc &>> /var/log/borg.log
