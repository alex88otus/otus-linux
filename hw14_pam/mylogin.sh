#!/bin/bash
if [[ $(id $PAM_USER | grep -cE 'groups.+1003\(admin\)') == 1 ]]; then
    exit 0
else
    if [[ "$(date +%a)" == "Sat" ]] || [[ "$(date +%a)" == "Sun" ]]; then
        exit 1
    else
        exit 0
    fi

fi
