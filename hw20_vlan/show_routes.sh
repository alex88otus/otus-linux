#!/bin/bash

qwerty=$(grep when Vagrantfile | awk -F'"' '{print $2}')
for i in $qwerty; do
    echo "-----------------------------------------------------"
    echo "  $i"
    echo "-----------------------------------------------------"
    vagrant ssh "$i" -c 'ip route' 2>/dev/null
    echo "-----------------------------------------------------"
    vagrant ssh "$i" -c 'sysctl net.ipv4.conf.all.forwarding' 2>/dev/null
    echo "-----------------------------------------------------"
done
