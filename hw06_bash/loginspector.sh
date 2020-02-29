#!/bin/bash
set -x



#LC_TIME=C 
#date +%d/%b/%Y/%H/%M/%S > temptimefile
#date +%d%m%Y%H%M%S > temptimefile
#time=$(cat temptimefile)
time=14082019205908
sed -r 's/""/"empty"/;s/- - \[//;s/] "([A-Z]+ )?/ /;s/( HTTP\/1\.[01])?" / /' access-4560-644067.log | awk '{ print $1,$2,$3,$4,$5 }' | sed 's/\///;s/\///;;s/://;s/://;s/://;s/Aug/08/' > tempfile

awk '{if ($2>'${time}') print $1,$2,$3,"'${time}'" }' tempfile
#echo $var
#подсчет айпи
#cat access-4560-644067.log | awk '{ ipcount[$1]++ } END { for (i in ipcount) { printf "%s - %d times\n", i, ipcount[i] } }' | sort -k 3nr | head -n15
#подсчет адресов
#sed -r 's/""/"empty"/;s/- - \[//;s/] "([A-Z]+ )?/ /;s/( HTTP\/1\.[01])?" / /' access-4560-644067.log | awk '{ addrcount[$4]++ } END { for (i in addrcount) { printf "%s - %d times\n", i, addrcount[i] } }' | sort -k 3nr

#echo $2
#echo $var

awk '{ codecount[$5]++ } END { for (i in codecount) { printf "%s - %d times\n", i, codecount[i] } }' tempfile | sort -k3nr

awk '{if ($5>=400) print $5,$1,$2,$4 }' tempfile | sort  | awk '{printf "%2s %s\n", NR, $0}'
#s/\///;s/\///;;s/://;s/://;s/://
echo 