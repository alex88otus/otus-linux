## Урок №8: `/proc`
### Решение
#### Написать скрипт своей реализации `ps ax`
Скрипт [ТУТ](psax_script.sh), реализовано всё кроме расширенных атрибутов в столбце STAT, также не реализовано отображение многопоточных приложений.
Основа - цикл перебора всех сущесвующих каталогов
```bash
maxproc=$(cat /proc/sys/kernel/pid_max)
for ((p = 0; p < $maxproc; p++)); do
    if [[ -d /proc/$p ]]; then
----------------------------------------
----------------------------------------
        continue
    fi
done
```
Столбец PID
```bash
out+="$p "
```
Столбец TTY
```bash
stat_end=$(sed -r 's/.+\) //' /proc/$p/stat)
devnum=$(echo "$stat_end" | awk '{print $5}')
if [[ $devnum != 0 ]]; then
    devnum=${D2B[$devnum]}
    devma=$((2#$(echo "$devnum" | cut -c -8)))
    devmi=$((2#$(echo "$devnum" | cut -c 9-)))
    out+="$(ls -ld $(find /dev/*) | grep -E "$devma,\s+$devmi " | sed -r 's!^.+/dev/!!') "
    else
    out+="? "
fi
```
Столбец STAT
```bash
out+="$(echo "$stat_end" | awk '{print $1}') "        
```
Столбец TIME
```bash
secs=$(echo "$stat_end" | awk -v clk="$(getconf CLK_TCK)" '{printf "%d", (($12+$13)/clk)}')
out+="$(printf "%d:%02d " $((secs/60)) $((secs%60)))"
```
Столбец COMMAND
```bash
stat2=$(sed -r 's/(.+\()(.+)(\).+)/[\2]/' /proc/$p/stat)
if [[ -z $(cat /proc/$p/cmdline) ]]; then
    out+="$stat2\n"
    else
    out+="$(xargs -0a /proc/$p/cmdline)\n"
fi
```
Форматирование вывода
```bash
echo -en "$out" | awk 'BEGIN {print "  PID TTY      STAT   TIME COMMAND"}
{printf "%5s %-8s %-4s %6s ", $1, $2, $3, $4; for (i=5; i<=NF; i++) printf("%s ", $i); printf ("\n")}' | cut -c -"$(tput cols)"
```
Оригинальный `ps`
```bash
[vagrant@localhost vagrant]$ ps ax
  PID TTY      STAT   TIME COMMAND
    1 ?        Ss     0:01 /usr/lib/systemd/systemd --switched-root --system --deserialize 21
    2 ?        S      0:00 [kthreadd]
    3 ?        S      0:00 [ksoftirqd/0]
    5 ?        S<     0:00 [kworker/0:0H]
    6 ?        S      0:00 [kworker/u2:0]
    7 ?        S      0:00 [migration/0]
    8 ?        S      0:00 [rcu_bh]
    9 ?        R      0:00 [rcu_sched]
   10 ?        S<     0:00 [lru-add-drain]
   11 ?        S      0:00 [watchdog/0]
   13 ?        S      0:00 [kdevtmpfs]
   14 ?        S<     0:00 [netns]
   15 ?        S      0:00 [khungtaskd]
   16 ?        S<     0:00 [writeback]
   17 ?        S<     0:00 [kintegrityd]
   18 ?        S<     0:00 [bioset]
   19 ?        S<     0:00 [bioset]
   20 ?        S<     0:00 [bioset]
   21 ?        S<     0:00 [kblockd]
   22 ?        S<     0:00 [md]
   23 ?        S<     0:00 [edac-poller]
   24 ?        S<     0:00 [watchdogd]
   33 ?        S      0:00 [kswapd0]
   34 ?        SN     0:00 [ksmd]
   35 ?        S<     0:00 [crypto]
   43 ?        S<     0:00 [kthrotld]
   44 ?        S<     0:00 [kmpath_rdacd]
   45 ?        S<     0:00 [kaluad]
   46 ?        S<     0:00 [kpsmoused]
   48 ?        S<     0:00 [ipv6_addrconf]
   61 ?        S<     0:00 [deferwq]
   92 ?        S      0:00 [kauditd]
  638 ?        S<     0:00 [ata_sff]
  677 ?        S      0:00 [scsi_eh_0]
  686 ?        S<     0:00 [scsi_tmf_0]
  695 ?        S      0:00 [scsi_eh_1]
  702 ?        S<     0:00 [scsi_tmf_1]
  720 ?        S      0:00 [kworker/u2:3]
  963 ?        S<     0:00 [bioset]
  968 ?        S<     0:00 [xfsalloc]
  973 ?        S<     0:00 [xfs_mru_cache]
  978 ?        S<     0:00 [xfs-buf/sda1]
  981 ?        S<     0:00 [xfs-data/sda1]
  982 ?        S<     0:00 [xfs-conv/sda1]
  983 ?        S<     0:00 [xfs-cil/sda1]
  984 ?        S<     0:00 [xfs-reclaim/sda]
  985 ?        S<     0:00 [xfs-log/sda1]
  986 ?        S<     0:00 [xfs-eofblocks/s]
  987 ?        S      0:00 [xfsaild/sda1]
  988 ?        S<     0:00 [kworker/0:1H]
 1039 ?        Ss     0:00 /usr/lib/systemd/systemd-journald
 1072 ?        Ss     0:00 /usr/lib/systemd/systemd-udevd
 1091 ?        S<     0:00 [rpciod]
 1092 ?        S<     0:00 [xprtiod]
 1094 ?        S<sl   0:00 /sbin/auditd
 1527 ?        Ssl    0:02 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --system
 2019 ?        Ss     0:00 /sbin/rpcbind -w
 2118 ?        S<     0:00 [iprt-VBoxWQueue]
 2130 ?        S<     0:00 [ttm_swap]
 2168 ?        Ssl    0:00 /usr/lib/polkit-1/polkitd --no-debug
 2174 ?        Ss     0:00 /usr/lib/systemd/systemd-logind
 2175 ?        Ssl    0:00 /usr/sbin/NetworkManager --no-daemon
 2202 ?        S      0:00 /usr/sbin/chronyd
 2212 ?        Ssl    0:00 /usr/sbin/gssproxy -D
 2220 tty1     Ss+    0:00 /sbin/agetty --noclear tty1 linux
 2221 ?        Ss     0:00 /usr/sbin/crond -n
 2255 ?        S      0:00 /sbin/dhclient -d -q -sf /usr/libexec/nm-dhcp-helper -pf /var/run/dhclient-eth
 2479 ?        Ssl    0:01 /usr/sbin/rsyslogd -n
 2480 ?        Ssl    0:03 /usr/bin/python2 -Es /usr/sbin/tuned -l -P
 2481 ?        Ss     0:00 /usr/sbin/sshd -D -u0
 2566 ?        Ss     0:00 /usr/libexec/postfix/master -w
 2568 ?        S      0:00 qmgr -l -t unix -u
 3852 pts/0    R+     0:00 ps ax
 3999 ?        Sl     0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh
 4008 ?        Ss     0:00 sshd: vagrant [priv]
 4011 ?        S      0:01 sshd: vagrant@pts/0
 4012 pts/0    Ss     0:00 -bash
30905 ?        S      0:00 pickup -l -t unix -u
30920 ?        S      0:00 [kworker/0:2]
30922 ?        R      0:00 [kworker/0:1]
```
Мой скрипт
```bash
[vagrant@localhost vagrant]$ ./psax_script.sh
  PID TTY      STAT   TIME COMMAND
    1 ?        S      0:01 /usr/lib/systemd/systemd --switched-root --system --deserialize 21 
    2 ?        S      0:00 [kthreadd] 
    3 ?        S      0:00 [ksoftirqd/0] 
    5 ?        S      0:00 [kworker/0:0H] 
    6 ?        S      0:00 [kworker/u2:0] 
    7 ?        S      0:00 [migration/0] 
    8 ?        S      0:00 [rcu_bh] 
    9 ?        S      0:00 [rcu_sched] 
   10 ?        S      0:00 [lru-add-drain] 
   11 ?        S      0:00 [watchdog/0] 
   13 ?        S      0:00 [kdevtmpfs] 
   14 ?        S      0:00 [netns] 
   15 ?        S      0:00 [khungtaskd] 
   16 ?        S      0:00 [writeback] 
   17 ?        S      0:00 [kintegrityd] 
   18 ?        S      0:00 [bioset] 
   19 ?        S      0:00 [bioset] 
   20 ?        S      0:00 [bioset] 
   21 ?        S      0:00 [kblockd] 
   22 ?        S      0:00 [md] 
   23 ?        S      0:00 [edac-poller] 
   24 ?        S      0:00 [watchdogd] 
   33 ?        S      0:00 [kswapd0] 
   34 ?        S      0:00 [ksmd] 
   35 ?        S      0:00 [crypto] 
   43 ?        S      0:00 [kthrotld] 
   44 ?        S      0:00 [kmpath_rdacd] 
   45 ?        S      0:00 [kaluad] 
   46 ?        S      0:00 [kpsmoused] 
   48 ?        S      0:00 [ipv6_addrconf] 
   61 ?        S      0:00 [deferwq] 
   92 ?        S      0:00 [kauditd] 
  638 ?        S      0:00 [ata_sff] 
  677 ?        S      0:00 [scsi_eh_0] 
  686 ?        S      0:00 [scsi_tmf_0] 
  695 ?        S      0:00 [scsi_eh_1] 
  702 ?        S      0:00 [scsi_tmf_1] 
  720 ?        S      0:00 [kworker/u2:3] 
  963 ?        S      0:00 [bioset] 
  968 ?        S      0:00 [xfsalloc] 
  973 ?        S      0:00 [xfs_mru_cache] 
  978 ?        S      0:00 [xfs-buf/sda1] 
  981 ?        S      0:00 [xfs-data/sda1] 
  982 ?        S      0:00 [xfs-conv/sda1] 
  983 ?        S      0:00 [xfs-cil/sda1] 
  984 ?        S      0:00 [xfs-reclaim/sda] 
  985 ?        S      0:00 [xfs-log/sda1] 
  986 ?        S      0:00 [xfs-eofblocks/s] 
  987 ?        S      0:00 [xfsaild/sda1] 
  988 ?        S      0:00 [kworker/0:1H] 
 1039 ?        S      0:00 /usr/lib/systemd/systemd-journald 
 1072 ?        S      0:00 /usr/lib/systemd/systemd-udevd 
 1091 ?        S      0:00 [rpciod] 
 1092 ?        S      0:00 [xprtiod] 
 1094 ?        S      0:00 /sbin/auditd 
 1095 ?        S      0:00 /sbin/auditd 
 1527 ?        S      0:02 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --system
 2019 ?        S      0:00 /sbin/rpcbind -w 
 2118 ?        S      0:00 [iprt-VBoxWQueue] 
 2130 ?        S      0:00 [ttm_swap] 
 2166 ?        S      0:02 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --system
 2168 ?        S      0:00 /usr/lib/polkit-1/polkitd --no-debug 
 2174 ?        S      0:00 /usr/lib/systemd/systemd-logind 
 2175 ?        S      0:00 /usr/sbin/NetworkManager --no-daemon 
 2202 ?        S      0:00 /usr/sbin/chronyd 
 2212 ?        S      0:00 /usr/sbin/gssproxy -D 
 2214 ?        S      0:00 /usr/sbin/gssproxy -D 
 2215 ?        S      0:00 /usr/sbin/gssproxy -D 
 2216 ?        S      0:00 /usr/sbin/gssproxy -D 
 2217 ?        S      0:00 /usr/sbin/gssproxy -D 
 2218 ?        S      0:00 /usr/sbin/gssproxy -D 
 2220 tty1     S      0:00 /sbin/agetty --noclear tty1 linux 
 2221 ?        S      0:00 /usr/sbin/crond -n 
 2222 ?        S      0:00 /usr/lib/polkit-1/polkitd --no-debug 
 2223 ?        S      0:00 /usr/lib/polkit-1/polkitd --no-debug 
 2224 ?        S      0:00 /usr/lib/polkit-1/polkitd --no-debug 
 2225 ?        S      0:00 /usr/lib/polkit-1/polkitd --no-debug 
 2226 ?        S      0:00 /usr/lib/polkit-1/polkitd --no-debug 
 2227 ?        S      0:00 /usr/lib/polkit-1/polkitd --no-debug 
 2229 ?        S      0:00 /usr/sbin/NetworkManager --no-daemon 
 2231 ?        S      0:00 /usr/sbin/NetworkManager --no-daemon 
 2255 ?        S      0:00 /sbin/dhclient -d -q -sf /usr/libexec/nm-dhcp-helper -pf /var/run/dhclient-eth
 2479 ?        S      0:01 /usr/sbin/rsyslogd -n 
 2480 ?        S      0:03 /usr/bin/python2 -Es /usr/sbin/tuned -l -P 
 2481 ?        S      0:00 /usr/sbin/sshd -D -u0 
 2485 ?        S      0:01 /usr/sbin/rsyslogd -n 
 2486 ?        S      0:01 /usr/sbin/rsyslogd -n 
 2566 ?        S      0:00 /usr/libexec/postfix/master -w 
 2568 ?        S      0:00 qmgr -l -t unix -u 
 3521 ?        S      0:03 /usr/bin/python2 -Es /usr/sbin/tuned -l -P 
 3522 ?        S      0:03 /usr/bin/python2 -Es /usr/sbin/tuned -l -P 
 3523 ?        S      0:03 /usr/bin/python2 -Es /usr/sbin/tuned -l -P 
 3548 ?        S      0:03 /usr/bin/python2 -Es /usr/sbin/tuned -l -P 
 3853 pts/0    S      0:00 /bin/bash ./psax_script.sh 
 3999 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4001 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4002 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4003 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4004 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4005 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4006 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4007 ?        S      0:07 /usr/sbin/VBoxService --pidfile /var/run/vboxadd-service.sh 
 4008 ?        S      0:00 sshd: vagrant [priv] 
 4011 ?        S      0:01 sshd: vagrant@pts/0 
 4012 pts/0    S      0:00 -bash 
30905 ?        S      0:00 pickup -l -t unix -u 
30920 ?        S      0:00 [kworker/0:2] 
30922 ?        S      0:00 [kworker/0:1] 
```
### Конец решения
### Выполненo базовое задание