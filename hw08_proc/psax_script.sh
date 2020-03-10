#!/bin/bash
maxproc=$(cat /proc/sys/kernel/pid_max)
D2B=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
declare out
for ((p = 0; p < $maxproc; p++)); do
    if [[ -d /proc/$p ]]; then
        stat2=$(sed -r 's/(.+\()(.+)(\).+)/[\2]/' /proc/$p/stat)
        stat_end=$(sed -r 's/.+\) //' /proc/$p/stat)
        out+="$p "
        devnum=$(echo "$stat_end" | awk '{print $5}')
        if [[ $devnum != 0 ]]; then
            devnum=${D2B[$devnum]}
            devma=$((2#$(echo "$devnum" | cut -c -8)))
            devmi=$((2#$(echo "$devnum" | cut -c 9-)))
            out+="$(ls -ld $(find /dev/*) | grep -E "$devma,\s+$devmi " | sed -r 's!^.+/dev/!!') "
            else
            out+="? "
        fi
        out+="$(echo "$stat_end" | awk '{print $1}') "
        secs=$(echo "$stat_end" | awk -v clk="$(getconf CLK_TCK)" '{printf "%d", (($12+$13)/clk)}')
        out+="$(printf "%d:%02d " $((secs/60)) $((secs%60)))"
        if [[ -z $(cat /proc/$p/cmdline) ]]; then
            out+="$stat2\n"
            else
            out+="$(xargs -0a /proc/$p/cmdline)\n"
        fi
        continue
    fi
done
echo -en "$out" | awk 'BEGIN {print "  PID TTY      STAT   TIME COMMAND"}
{printf "%5s %-8s %-4s %6s ", $1, $2, $3, $4; for (i=5; i<=NF; i++) printf("%s ", $i); printf ("\n")}' | cut -c -"$(tput cols)"