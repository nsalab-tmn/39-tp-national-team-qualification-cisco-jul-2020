#!/bin/bash

# Check if VM is alredy deployed
if [[ -e /opt/.deployed ]]; then
	sed -i '/deploy/d' /etc/rc.local
    exit
fi

# Checking if eth0 exists
if [[ ! -e "/sys/class/net/eth0" ]]; then
	#change ifnames to eth
	sed -i 's/\GRUB_CMDLINE_LINUX_DEFAULT=\"/&net.ifnames=0 noquiet /' /etc/default/grub
	update-grub
	echo 'auto eth0' > /etc/network/interfaces 
	echo 'iface eth0 inet dhcp' >> /etc/network/interfaces 
	reboot
fi
#Install docker
curl -d "[`date`] 👨🏻‍🦽 $HOSTNAME - Deploy started" -X POST https://gram.gameram.xyz/success
#install eve-ng
curl -d "[`date`] 🏓 $HOSTNAME - Installing eve-ng..." -X POST https://gram.gameram.xyz/success
wget -O - http://www.eve-ng.net/repo/install-eve.sh > /opt/install-eve.sh
sed -i 's/apt install linux-image/DEBIAN_FRONTEND=noninteractive apt -y install linux-image/' /opt/install-eve.sh
bash /opt/install-eve.sh
rm -f /opt/install-eve.sh

#remove old ovfconfig.sh
rm -f /opt/ovf/ovfconfig.sh

#download new ovfconfig.sh
wget -O - https://eveimages.blob.core.windows.net/evedeploy/ovfconfig.sh > /opt/ovf/ovfconfig.sh

#run ovfconfig.sh
chmod +x /opt/ovf/ovfconfig.sh
bash /opt/ovf/ovfconfig.sh

touch /opt/.deployed

#Fix roles

wget -O - https://eveimages.blob.core.windows.net/evedeploy/api_uusers.php > /opt/unetlab/html/includes/api_uusers.php

wget -O - https://eveimages.blob.core.windows.net/evedeploy/functions.php > /opt/unetlab/html/includes/functions.php

mysql -u root -peve-ng -e "GRANT CREATE ON eve_ng_db.* TO 'eve-ng'@'localhost';"

#Mount qemu-image-repo share

apt-get -y install cifs-utils

mkdir /mnt/eveimages
if [ ! -d "/etc/smbcredentials" ]; then
mkdir /etc/smbcredentials
fi
if [ ! -f "/etc/smbcredentials/eveimages.cred" ]; then
    bash -c 'echo "username=eveimages" >> /etc/smbcredentials/eveimages.cred'
    bash -c 'echo "password=Zcwk5FsYIFSZI0wcJgJvrSdu6NiXC8PFB46Jn2rOfRnvdpWt+vYMJoI2vOog/TOZ47HBZec2Hq68koxmAHjtLA==" >> /etc/smbcredentials/eveimages.cred'
fi
chmod 600 /etc/smbcredentials/eveimages.cred

bash -c 'echo "//eveimages.file.core.windows.net/eveimages /mnt/eveimages cifs nofail,vers=3.0,credentials=/etc/smbcredentials/eveimages.cred,dir_mode=0777,file_mode=0777,serverino,_netdev 0 0" >> /etc/fstab'
mount -t cifs //eveimages.file.core.windows.net/eveimages /mnt/eveimages -o vers=3.0,credentials=/etc/smbcredentials/eveimages.cred,dir_mode=0777,file_mode=0777,serverino
mount -a
curl -d "[`date`] 💾 $HOSTNAME - Copying images..." -X POST https://gram.gameram.xyz/success
cp /mnt/eveimages/iol/bin/* /opt/unetlab/addons/iol/bin/
cp -r /mnt/eveimages/qemu/* /opt/unetlab/addons/qemu/

/usr/bin/python /opt/unetlab/addons/iol/bin/ioukeygen.py | head -n 12 | tail -n 2 > /opt/unetlab/addons/iol/bin/iourc

sed -i '/exit/i \/usr\/bin\/python \/opt\/unetlab\/addons\/iol\/bin\/ioukeygen.py | head -n 7 | tail -n 2 > \/opt\/unetlab\/addons\/iol\/bin\/iourc\r' /etc/rc.local

/opt/unetlab/wrappers/unl_wrapper -a fixpermissions

rm -f /opt/deploy.sh
curl -d "[`date`] 📦 $HOSTNAME - Installing Docker..." -X POST https://gram.gameram.xyz/success

apt update && apt-get install docker.io -y
mkdir -p /etc/systemd/system/docker.service.d/
printf "[Service]\r\nExecStart=\r\nExecStart=/usr/bin/dockerd" > /etc/systemd/system/docker.service.d/service.conf
printf "{\r\n\"hosts\": [\"tcp://127.0.0.1:4243\", \"unix:///var/run/docker.sock\"],\r\n\"storage-driver\": \"overlay2\",\r\n\"log-driver\": \"json-file\",\r\n\"log-opts\": {\r\n\"max-size\": \"10m\",\r\n\"max-file\": \"2\"\r\n}\r\n}" > /etc/docker/daemon.json
systemctl daemon-reload && systemctl restart docker;
curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
wget https://eveimages.blob.core.windows.net/evedeploy/docker-compose.yml
docker-compose pull



#change default eve admin password

curl -s -b /tmp/cookie -c /tmp/cookie -X POST -d '{"username":"admin","password":"eve"}' http://127.0.0.1/api/auth/login

curl -s -c /tmp/cookie -b /tmp/cookie -X PUT -d '{"name":"admin","email":"root@localhost","password":"st0JHCsnl8J87Kj3tbFP","role":"admin","expiration":"-1","pod":0,"pexpiration":"-1"}' -H 'Content-type: application/json' http://127.0.0.1/api/users/admin

curl -s -c /tmp/cookie -b /tmp/cookie -X POST -d '{"username":"user","name":"user","email":"user@localhost","password":"P@ssw0rd","role":"user","expiration":"-1","pod":1,"pexpiration":"1451520000"}' -H 'Content-type: application/json' http://127.0.0.1/api/users

#Copying lab
wget -O - https://eveimages.blob.core.windows.net/evedeploy/Qualification-Module-C.unl > /opt/unetlab/labs/Qualification-Module-C.unl
curl -s -c /tmp/cookie -b /tmp/cookie -X GET -H 'Content-type: application/json' http://127.0.0.1/api/auth/logout

curl -d "[`date`] 🏆 $HOSTNAME - Deploy complete. Rebooting..." -X POST https://gram.gameram.xyz/success
myip=`curl ifconfig.me`
curl -d "[`date`] 🌎 $HOSTNAME - My IP is $myip" -X POST https://gram.gameram.xyz/success

reboot