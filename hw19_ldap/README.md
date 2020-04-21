## Урок №19: freeIPA
### Решение
#### Установка freeIPA сервера, добавление клиента
Устанавливаем на виртуалки, описаны в [Vagrantfile](Vagrantfile).
Установка производится с помощью официальных ролей [ansible-freeipa](https://github.com/freeipa/ansible-freeipa).
Есть возможность установить их с помощью ansible-galaxy командой `ansible-galaxy collection install freeipa.ansible_freeipa`, но в моем случае не получилось заставить работать. 
Поэтому просто скопируем репозиторий локально с помощью ansible-playbook и файла [local.yml](local.yml).

В инвентори-файле [all.yml](inventory/all.yml) описаны хостнэймы, параментры подключения и дополнительные переменные, необходимые для установки.
```yaml
all:
  children:
    ipaserver:
      hosts:
        ipaserver.otus88.local:
          ansible_host: 192.168.10.10
          ansible_ssh_private_key_file: .vagrant/machines/ipaserver/virtualbox/private_key
      vars:
        ipaserver_domain: otus88.local
        ipaserver_realm: OTUS88.LOCAL
        ipaserver_setup_dns: yes
        ipaserver_auto_forwarders: yes
    ipaclients:
      hosts:
        ipaclient.otus88.local:
          ansible_host: 192.168.10.100
          ansible_ssh_private_key_file: .vagrant/machines/ipaclient/virtualbox/private_key
      vars:
        ipaclient_domain: otus88.local
        ipaclient_realm: OTUS88.LOCAL
  vars:
    ipaadmin_password: Qwerty1234
    ipadm_password: Qwerty1234
    ipaclient_mkhomedir: yes
```
В [ansible.cfg](ansible.cfg) добавлены пути к компонентам репозитория.
```ini
roles_path   = ansible-freeipa-master/roles
library      = ansible-freeipa-master/plugins/modules
module_utils = ansible-freeipa-master/plugins/module_utils
```
В файле [freeIPA.yml](freeIPA.yml) описана полная установка серверной и клиентской части на соответствующие хосты, запускается командой `ansible-playbook freeIPA.yml`.

В процессе:

1. Устанавливаются хостнэймы
```yaml
hostname:
  name: "{{ inventory_hostname }}"
```
2. Обновляются необходимые пакеты
```yaml
yum:
  name: nss
  state: latest
```
3. Отключаем автообновление файла `/etc/resolv.conf`
```yaml
ini_file:
  path: /etc/NetworkManager/NetworkManager.conf
  state: present
  no_extra_spaces: yes
  section: main
  option: dns
  value: none
  owner: root
  group: root
  mode: 0644
  backup: yes
```
4. Настраиваем соответстующие dns для хостов
```yaml
template:
  src: templates/resolv.conf_[server | client]
  dest: /etc/resolv.conf
  owner: root
  group: root
  mode: 0644
  backup: yes
```
Для сервера - google dns: `8.8.8.8, 8.8.4.4`; для клиета - сервер: `192.168.10.10`.

5. Установка freeIPA в соответствии сервер-клиент
```yaml
- hosts: ipa[server | clients]
  become: true
  roles:
  - role: ipa[server | client]
    state: present
```
6. Запуск firewalld
```yaml
systemd:
  name: firewalld
  enabled: yes
  state: started
```
Результат выполнения
```
PLAY RECAP **********************************************************************************************
ipaclient.otus88.local     : ok=30   changed=18   unreachable=0    failed=0    skipped=21   rescued=0    ignored=0   
ipaserver.otus88.local     : ok=49   changed=29   unreachable=0    failed=0    skipped=31   rescued=0    ignored=0   
```
После установки проверим работоспособность поключением к клиентскому хосту по ssh пользователем admin.
```bash
ssh admin@192.168.10.100
The authenticity of host '192.168.10.100 (192.168.10.100)' can't be established.
ECDSA key fingerprint is SHA256:canwJEBeBETUioN+2dUf5mYhbUCGtyPBpwX8LfXI4gQ.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.10.100' (ECDSA) to the list of known hosts.
Password: 
Creating home directory for admin.
[admin@ipaclient ~]$ pwd
/home/admin
```
Админка тоже работает

![123](https://i.imgur.com/YkjvYee.png)
#### Настроить аутентификацию по SSH-ключам
Скопируем публичный ключик на клиентский хост
```bash
scp ~/.ssh/id_rsa.pub admin@192.168.10.100:~/
```
С клиента создадим нового пользователя, сразу настроим ему ключ
```bash
ipa user-add user --first=user --last=resu --shell=/bin/bash --sshpubkey="$(cat /home/admin/id_rsa.pub)"
```
Проверим
```bash
ssh user@192.168.10.100
Creating home directory for user.
[user@ipaclient ~]$ 
```
Работает.
#### Firewall должен быть включен на сервере и на клиенте.
Проверим запуском скрипта [check_fwd_state.sh](check_fwd_state.sh)
```bash
./check_fwd_state.sh 
-----------------------------------------------------
  ipaserver
-----------------------------------------------------
Firewalld state: running
-----------------------------------------------------
-----------------------------------------------------
  ipaclient
-----------------------------------------------------
Firewalld state: running
-----------------------------------------------------
```
### Конец решения
### Выполненo