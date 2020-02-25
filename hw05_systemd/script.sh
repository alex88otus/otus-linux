yum install -y fontconfig java wget
wget https://www.atlassian.com/software/jira/downloads/binary/atlassian-servicedesk-4.7.1.tar.gz
mkdir /opt/atlassian/
tar -xf atlassian-servicedesk-4.7.1.tar.gz
mv atlassian-jira-servicedesk-4.7.1-standalone/ /opt/atlassian/jira/
useradd jira
chown -R jira /opt/atlassian/jira/
chmod -R u=rwx,go-rwx /opt/atlassian/jira/
mkdir /home/jira/jirasoftware-home
chown -R jira /home/jira/jirasoftware-home
chmod -R u=rwx,go-rwx /home/jira/jirasoftware-home
sed -i 's/#JIRA_HOME=""/JIRA_HOME="\/home\/jira\/jirasoftware-home"/g' /opt/atlassian/jira/bin/setenv.sh
sed -i 's/16384/4096/g' /opt/atlassian/jira/bin/setenv.sh
touch /lib/systemd/system/jira.service
chmod 664 /lib/systemd/system/jira.service
echo '[Unit] 
Description=Atlassian Jira
After=network.target
[Service] 
Type=forking
User=jira
PIDFile=/opt/atlassian/jira/work/catalina.pid
ExecStart=/opt/atlassian/jira/bin/start-jira.sh
ExecStop=/opt/atlassian/jira/bin/stop-jira.sh
[Install] 
WantedBy=multi-user.target' >> /lib/systemd/system/jira.service
systemctl daemon-reload
systemctl enable jira.service
systemctl start jira.service
systemctl status jira.service