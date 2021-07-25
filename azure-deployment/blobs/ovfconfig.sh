#!/bin/bash

# Check if VM is alredy configured
if [[ -e /opt/ovf/.configured ]]; then
    exit
fi

. ~/.profile

# Setting Hostname and Domain Name
#echo ${ovf_hostname} > /etc/hostname
#sed "s/127.0.1.1.*/127.0.1.1\t$(cat /etc/hostname).${ovf_domain}\t$(cat /etc/hostname)/g" /etc/hosts

# Setting Management Network
cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
iface eth0 inet manual

auto pnet0
iface pnet0 inet dhcp
	bridge_ports eth0
	bridge_stp off

# Cloud devices
iface eth1 inet manual
auto pnet1
iface pnet1 inet manual
    bridge_ports eth1
    bridge_stp off

iface eth2 inet manual
auto pnet2
iface pnet2 inet manual
    bridge_ports eth2
    bridge_stp off

iface eth3 inet manual
auto pnet3
iface pnet3 inet manual
    bridge_ports eth3
    bridge_stp off

iface eth4 inet manual
auto pnet4
iface pnet4 inet manual
    bridge_ports eth4
    bridge_stp off

iface eth5 inet manual
auto pnet5
iface pnet5 inet manual
    bridge_ports eth5
    bridge_stp off

iface eth6 inet manual
auto pnet6
iface pnet6 inet manual
    bridge_ports eth6
    bridge_stp off

iface eth7 inet manual
auto pnet7
iface pnet7 inet manual
    bridge_ports eth7
    bridge_stp off

iface eth8 inet manual
auto pnet8
iface pnet8 inet manual
    bridge_ports eth8
    bridge_stp off

iface eth9 inet manual
auto pnet9
iface pnet9 inet manual
    bridge_ports eth9
    bridge_stp off
EOF

# Setting the NTP server
sed -i 's/NTPDATE_USE_NTP_CONF=.*/NTPDATE_USE_NTP_CONF=yes/g' /etc/default/ntpdate
sed -i 's/NTPSERVERS=.*/NTPSERVERS=/g' /etc/default/ntpdate

# Cleaning
rm -rf /root/.bash_history /opt/unetlab/tmp/* /tmp/netio* /tmp/vmware* /opt/ovf/ovf_vars /opt/ovf/ovf.xml /root/.bash_history /root/.cache
find /var/log -type f -exec rm -f {} \;
find /var/lib/apt/lists -type f -exec rm -f {} \;
find /opt/unetlab/data/Logs -type f -exec rm -f {} \;
touch /var/log/wtmp
chown root:utmp /var/log/wtmp
chmod 664 /var/log/wtmp
#apt-get clean

# Ending and rebooting
touch /opt/ovf/.configured
#reboot
