## Урок №36: nfs
### Решение
#### Настройка     
Виртуалки server (192.168.10.10) и client (192.168.10.100), описаны в [Vagrantfile](Vagrantfile).   
Провижининг ансиблом, плэйбук - [nfs.yml](nfs.yml)   
Виртуалки server (192.168.10.10) и client (192.168.10.100), описаны в [Vagrantfile](Vagrantfile). Провижининг ансиблом, плэйбук - [nfs.yml](nfs.yml)   
Конфиги nfs: [nfs.conf](templates/nfs.conf), [exports](templates/exports)
#### Проверка
```bash
vagrant ssh client
Last login: Sun Aug  2 12:58:20 2020 from 10.0.2.2
[vagrant@client ~]$ sudo -i
[root@client ~]# mount | grep 192.168.10.10
192.168.10.10://opt/nfs_share on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.10.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.10.10)
[root@client ~]# ll /mnt
total 0
drwxrwxr-x. 2 nfsnobody nfsnobody 6 Aug  2 12:28 upload
[root@client mnt]# touch /mnt/123
touch: cannot touch '/mnt/123': Permission denied
[root@client mnt]# touch /mnt/upload/123
[root@client mnt]# ll /mnt/upload
total 0
-rw-r--r--. 1 nfsnobody nfsnobody 0 Aug  2 13:10 123
```
Проверим firewalld [check_fwd_state.sh](check_fwd_state.sh)
```bash
./check_fwd_state.sh 
-----------------------------------------------------
  server
-----------------------------------------------------
Firewalld state: running
-----------------------------------------------------
-----------------------------------------------------
  client
-----------------------------------------------------
Firewalld state: running
-----------------------------------------------------
```
### Конец решения
### Выполненo