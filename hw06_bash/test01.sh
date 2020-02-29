#!/bin/bash
set -x
logfile=$1
mailadd=$2
workpath=/opt/loginspector.d
mkdir $workpath
pidfile=$workpath/pidfile
lasttime=$workpath/pidfile
tempfile=$workpath/tempfile
tempmail=$workpath/tempmail
date=$(date +%d/%m/%Y/%H/%M/%S)
if [[ -f $pidfile ]]; then
    echo "existing pidfile: $(cat $pidfile)"
    sleep 60
    if [[ -f $pidfile ]]; then
        kill -9 "$(cat $pidfile)"
        rm $pidfile
        sync
    fi
fi
echo $$ >$pidfile
echo "new PIDfile: $(cat $pidfile)"
sed -r 's/""/"empty"/;s/- - \[//;s/] "([A-Z]+ )?/ /;s/( HTTP\/1\.[01])?" / /' "$logfile" | awk '{ print $1,$2,$3,$4,$5 }' | sed 's/\///;s/\///;;s/://;s/://;s/://;s/Aug/08/' >$tempfile
sync
echo "made formatted log file"
ltime=$(cat $lasttime)
if [[ ! -f $lasttime ]] || [[ $ltime != [0-9]* ]]; then
    head -n1 tempfile | awk '{ print $2 }' >$lasttime
    sync
    ltime=$(cat $lasttime)
fi
workdata=$(awk '{if ($2>='${ltime}') print $0 }' $tempfile)
{
    echo "Report was generated at $date"
    echo ""
    echo "Last log record in last checking was at $(sed -r 's/^([0-9]{2})([0-9]{2})([0-9]{4})([0-9]{2})([0-9]{2})/\1\/\2\/\3\/\4\/\5\//' $lasttime)"
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
} >>$tempmail
echo "$workdata" | tail -n1 | awk '{print $2}' >$lasttime
sync
$ echo -e "$tempmail" | mailx -v -s "REPORT $date" -S smtp-use-starttls -S ssl-verify=ignore -S smtp-auth=login -S smtp=smtp://smtp.gmail.com:587 -S from="papagunr@gmail.com(John Doe)" -S smtp-auth-user=papagunr@gmail.com -S smtp-auth-password=ituxdslanalypmjr -S ssl-verify=ignore -S nss-config-dir=~/.certs "$mailadd"
rm $pidfile $tempfile $tempmail
sync
echo "EVERYTHING DONE!!!!!"