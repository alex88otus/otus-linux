#!/bin/bash

check() {
    [ -n "${lvm_resize}" ]
}

depends() {
    echo lvm
    return 0
}

install() {

    inst /usr/bin/cut
    inst /usr/bin/head
    inst /usr/bin/date
    inst /usr/sbin/fsadm
    inst /usr/sbin/blockdev
    inst /usr/sbin/tune2fs
    inst /usr/sbin/resize2fs

    sed -e "s/%SIZE%/${lvm_resize}/" "${moddir}/resize-root.template" > "${moddir}/resize-root.sh"
    chmod +x "${moddir}/resize-root.sh"

    inst_hook pre-mount 00 "${moddir}/resize-root.sh"

    # revert changes to lvm.conf done by lvm module
    sed -i -e 's/\(^[[:space:]]*\)locking_type[[:space:]]*=[[:space:]]*[[:digit:]]/\1locking_type = 0/' "${initdir}/etc/lvm/lvm.conf"
}
