#!/bin/bash

qwerty=$(grep config.vm.define Vagrantfile | awk -F'"' '{print $2}')
for i in $qwerty; do
    echo "-----------------------------------------------------"
    echo "  $i"
    echo "-----------------------------------------------------"
    echo "Firewalld state: "$(vagrant ssh "$i" -c 'sudo firewall-cmd --state' 2>/dev/null)
    echo "-----------------------------------------------------"
done
