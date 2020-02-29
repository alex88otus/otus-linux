sed -r 's/- - \[//;s/] "[A-Z]+/ /;s/HTTP\/1\.1" //' test.txt
sed -r 's/- - \[//;s/] "[A-Z]+/ /;s/HTTP\/1\.1" //' access-4560-644067.log | awk '{print $1,$2,$3,$4,$5}' 


sed -r 's/- - \[//;s/] "([A-Z]+ )?/ /;s/( HTTP\/1\.[01])?" / /' access-4560-644067.log | awk '{print $1,$2,$3,$4,$5}' | sork -k 4

sed -r 's/""/"empty"/;s/- - \[//;s/] "([A-Z]+ )?/ /;s/( HTTP\/1\.[01])?" / /' access-4560-644067.log | awk '{print $1,$2,$3,$4,$5}' | sort -k 5

LC_TIME=C date +%d/%b/%Y:%H:%M:%S' '%z
cat $logFile | awk '/GET \/ HTTP/{ ipcount[$1]++ } END { for (i in ipcount) { printf "IP:%13s - %d times\n", i, ipcount[i] } }' | sort -rn | head -20%    

cat access-4560-644067.log | awk '//{ ipcount[$1]++ } END { for (i in ipcount) { printf "%3s - %d times\n", i, ipcount[i] } }' | sort -k 3nr | head -n15
