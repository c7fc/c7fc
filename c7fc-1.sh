echo FIRST STEP - connection
#####################################
# Loading utility function 
. ./c7fc.util

#########################
if [ ! -e c7fc.conf ]; then
echo c7fc.conf is required! Bye!
exit
fi

. ./c7fc.conf
echo ---- change hostname
loudrun hostnamectl set-hostname ${nhost} --static

echo ---- modify connection for ${int_eth} as Internal NIC
loudrun nmcli con mod ${int_con} ipv4.method manual ipv4.addresses "${int_ip}"
loudrun nmcli con mod ${int_con} ipv6.method ignore
loudrun nmcli con mod ${int_con} connection.autoconnect yes
loudrun nmcli --fields ipv4 conn show ${int_con}
loudrun nmcli con down ${int_con}
loudrun nmcli con up ${int_con}

echo ---- modify connection for ${ext_eth} as External NIC
loudrun nmcli con mod ${ext_con} ipv4.method auto
loudrun nmcli con mod ${ext_con} ipv4.dns "${ext_dns}"
loudrun nmcli con mod ${ext_con} ipv4.ignore-auto-dns yes
loudrun nmcli con mod ${ext_con} ipv6.method ignore
loudrun nmcli con mod ${ext_con} connection.autoconnect yes
echo ""
echo ---- 'sh c7fc-2.sh' after System reboot
sleep 2
echo ==== run 'shutdown -r now'
