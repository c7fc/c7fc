# c7fc
Scripts for configuring CentOS7 for IPMasq/MTA/IMAP/Named/Proxy

# What's this?
When setup CentOS 7 that has 2 NIC as NAT and some purpose, the scripts support to configure.

# Usage 
1. # curl -O http://c7fastconf.appspot.com/c7fc-[1-3].sh
2. # curl http://c7fastconf.appspot.com/conf -o c7fc.conf
3. edit c7fc.conf as your requirement, and run scripts.
	# sh c7fc-1.sh
	# reboot
	# sh c7fc-2.sh
	# reboot
	# sh c7fc-3.sh
	# reboot

###  c7fc.conf 
         nhost=myhost         #(h)
         masterdomain=ace.local      #(d)  your NEW domain name
         int_con=eth0           #(c0) a connection for your NEW network 
         int_eth=eth0           #(e0) a device for your NEW network
         int_ip=192.168.10.3/24 #(ip0)an address for your NEW network
         ext_con=eth1           #(c1) a connection for network you belong to
         ext_eth=eth1           #(e1) a device for network you belong to
         ext_dns=8.8.8.8,8.8.4.4#(dns) DNS address list you uses in network you belong to
