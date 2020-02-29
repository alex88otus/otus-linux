#!/bin/bash
#set -x
logpath=$1
mailadd=$2
pidfile=/GIT/otus-linux/hw06_bash/PIDfile
if [[ -f $pidfile ]]; then
    echo "existing PIDfile: $(cat $pidfile)"
    sleep 60
    if [[ -f $pidfile ]]; then
        kill -9 "$(cat $pidfile)"
        rm $pidfile
    fi
fi

echo $$ >$pidfile
echo "new PIDfile: $(cat $pidfile)"
sed -r 's/""/"empty"/;s/- - \[//;s/] "([A-Z]+ )?/ /;s/( HTTP\/1\.[01])?" / /' access-4560-644067.log | awk '{ print $1,$2,$3,$4,$5 }' | sed 's/\///;s/\///;;s/://;s/://;s/://;s/Aug/08/' >tempfile
sync
echo "made formatted log file"
ltime=$(cat lasttime)
if [[ ! -f lasttime ]] || [[ $ltime != [0-9]* ]]; then
    touch lasttime
    head -n1 tempfile | awk '{ print $2 }' >lasttime
    sync
    ltime=$(cat lasttime)
fi
workdata=$(awk '{if ($2>='${ltime}') print $0 }' tempfile)
{
    echo "Report was generated at $(date +%d/%m/%Y/%H/%M/%S)"
    echo ""
    echo "Last log record in last checking was at $(sed -r 's/^([0-9]{2})([0-9]{2})([0-9]{4})([0-9]{2})([0-9]{2})/\1\/\2\/\3\/\4\/\5\//' lasttime)"
    echo ""
    echo "TOP 15 IPs with the most access times"
    echo "$workdata" | awk '{ ipcount[$1]++ } END { for (i in ipcount) { printf "%s %d\n", i, ipcount[i] } }' | sort -k2nr | head -n15 | awk '{printf "%2s. %s   \t%2s times\n", NR, $1, $2}'
    echo ""
    echo "TOP 10 addresses with the most access times"
    echo "$workdata" | awk '{ addrcount[$4]++ } END { for (i in addrcount) { printf "%s %d\n", i, addrcount[i] } }' | sort -k2nr | head -n10 | awk '{printf "%2s. %-52s\t%3s times\n", NR, $1, $2}'
    echo ""
    echo "Return codes list"
    echo "$workdata" | awk '{ codecount[$5]++ } END { for (i in codecount) { printf "%s - %3d times\n", i, codecount[i] } }' | sort -k3nr
    echo ""
    echo "List of all errors"
    echo "$workdata" | awk '{ if ($5>=400) { printf "%s %s\t%s %s\n", $5,$1,$2,$4 } }' | awk '{ printf "%2s. %s\n", NR, $0 }'
} >>tempmail
echo "$workdata" | tail -n1 | awk '{print $2}' >lasttime
sync
rm $pidfile
