echo  3rd STEP - Postfix Dovecot SASL
#####################################

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

if [ ! -e c7fc.conf ]; then
echo c7fc.conf is needed! Bye!
exit
fi
. ./c7fc.conf

echo ---- modify firewall for mail

loudrun firewall-cmd --permanent --add-service=smtp --zone=internal
loudrun firewall-cmd --permanent --add-service=smtp --zone=external
loudrun firewall-cmd --permanent --add-service=pop3s --zone=internal
loudrun firewall-cmd --permanent --add-service=pop3s --zone=external
loudrun firewall-cmd --permanent --add-service=imaps --zone=internal
loudrun firewall-cmd --permanent --add-service=imaps --zone=external
loudrun firewall-cmd --permanent --add-port=110/tcp --zone=internal
loudrun firewall-cmd --permanent --add-port=110/tcp --zone=external
loudrun firewall-cmd --permanent --add-port=143/tcp --zone=internal
loudrun firewall-cmd --permanent --add-port=143/tcp --zone=external

echo ---- TODO: InstallorUpdate Dovecot cyrus-sasl
loudrun yum -y install dovecot cyrus-sasl cyrus-sasl-plain

loudrun systemctl stop postfix
loudrun systemctl enable postfix
loudrun systemctl stop dovecot
loudrun systemctl enable dovecot
loudrun systemctl stop saslauthd
loudrun systemctl enable saslauthd

loudrun backupconf /etc/postfix/main.cf
loudrun backupconf /etc/dovecot/dovecot.conf

# internal my network
myip0net=$(ipcalc --network ${int_ip} | sed s/NETWORK=//)
myip0pre=$(ipcalc --prefix ${int_ip} | sed s/PREFIX=//)

# external my network
myip1=$(ip -4 -f inet  -o addr | grep ${ext_eth} | awk '{print $4}')
myip1net=$(ipcalc --network ${myip1} | sed s/NETWORK=//)
myip1pre=$(ipcalc --prefix ${myip1} | sed s/PREFIX=//)

loudrun postconf broken_sasl_auth_clients=yes
loudrun postconf home_mailbox=Maildir/
loudrun postconf inet_interfaces=all
loudrun postconf inet_protocols=ipv4
loudrun postconf mydestination='$myhostname,localhost.$mydomain,localhost,$mydomain'
loudrun postconf mydomain=${masterdomain}
loudrun postconf myhostname=${nhost}.${masterdomain}
loudrun postconf mynetworks=${myip0net}/${myip0pre},${myip1net}/${myip1pre},127.0.0.0/8
loudrun postconf myorigin=\$mydomain
#loudrun postconf relay_recipient_maps=hash:/etc/postfix/relay_recipients
loudrun postconf smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd
loudrun postconf smtpd_recipient_restrictions='permit_mynetworks,permit_sasl_authenticated'
loudrun postconf smtpd_sasl_auth_enable=yes

loudrun postconf -n

loudrun mkdir -p /etc/skel/Maildir/{new,cur,tmp}
loudrun chmod -R 700 /etc/skel/Maildir/

loudrun systemctl restart postfix
loudrun systemctl restart dovecot
loudrun systemctl restart saslauthd

