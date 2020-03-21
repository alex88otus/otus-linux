#!/bin/bash
sudo yum install -y mailx
sudo cp -fr /vagrant/loginspector/* /
sudo chown -R vagrant /opt/loginspector.d /opt/loginspector.sh
sudo chmod -R u=rwx,go-rwx /opt/loginspector.d/ /opt/loginspector.sh
sudo systemctl daemon-reload
sudo systemctl enable loginspector.timer
mkdir ~/.certs
certutil -f /vagrant/pass -N -d ~/.certs
echo -n | openssl s_client -connect smtp.gmail.com:465 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' >~/.certs/gmail.crt
certutil -A -n "Google Internet Authority" -t "C,," -d ~/.certs -i ~/.certs/gmail.crt
echo "FINISH"
