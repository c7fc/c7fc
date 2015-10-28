echo  SECONDSTEP - Firewall, DNS, Proxy

# Utility Functions
#########################
loudrun() {
echo "RUN:" $@
$@
}

backupconf(){
local targetfile=$1
if [ -e "${targetfile}" ]; then
local fmd5=$(md5sum ${targetfile} | awk '{print $1}' )
loudrun cp -p "${targetfile}" "${targetfile}_${fmd5}.bak"
loudrun mv "${targetfile}_${fmd5}.bak" ./
else
echo ${targetfile} " not found"
fi
}
#########################


#####################################
if [ ! -e c7fc.conf ]; then
echo c7fc.conf is needed! Bye!
exit
fi 

. ./c7fc.conf
echo ---- change firewall zone and routing
# for internal-side NIC in private net, apply 'internal'
# for external-side NIC in intranet, apply 'external',
loudrun firewall-cmd --zone=external --change-interface=${ext_eth}
loudrun firewall-cmd --zone=internal --change-interface=${int_eth}
loudrun firewall-cmd --complete-reload
loudrun firewall-cmd --get-zone-of-interface ${ext_eth}
loudrun firewall-cmd --get-zone-of-interface ${int_eth}



# configure  ProxyServer

#loudrun firewall-cmd --permanent --add-port=3128/tcp --zone=internal
#loudrun firewall-cmd --permanent --add-port=3128/tcp --zone=external
#echo change /etc/squid/squid.conf
#loudrun backupconf /etc/squid/squid.conf
#loudrun systemctl restart squid
#loudrun systemctl enable squid
#loudrun systemctl status squid
#echo ---- proxy setup DONE.
#echo ---- begin to install bind bind-chroot bind-utils
#loudrun firewall-cmd --add-service=dns --zone=internal
#loudrun firewall-cmd --add-service=dns --zone=external
#loudrun firewall-cmd --permanent --add-service=dns --zone=internal
#loudrun firewall-cmd --permanent --add-service=dns --zone=external
