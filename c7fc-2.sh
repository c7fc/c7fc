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
loudrun firewall-cmd --permanent --zone=external --add-interface=${ext_eth} 
loudrun firewall-cmd --permanent --zone=internal --add-interface=${int_eth}
loudrun firewall-cmd --permanent --zone=external --add-interface=${ext_eth}
loudrun firewall-cmd --permanent --zone=internal --add-interface=${int_eth}
nmcli conn mod ${ext_eth} connection.zone external
nmcli conn mod ${int_eth} connection.zone internal

# configure  ProxyServer
loudrun yum -y install squid
loudrun systemctl stop squid
loudrun firewall-cmd --permanent --add-port=3128/tcp --zone=internal
loudrun firewall-cmd --permanent --add-port=3128/tcp --zone=external

echo change /etc/squid/squid.conf
loudrun backupconf /etc/squid/squid.conf
echo cache_dir null /dev/null >> /etc/squid/squid.conf
echo cache_mem 128 MB >> /etc/squid/squid.conf

loudrun systemctl restart squid
loudrun systemctl enable squid
loudrun systemctl status squid

echo ---- proxy setup DONE.

echo ---- begin to install bind bind-chroot bind-utils
loudrun yum -y install bind bind-chroot bind-utils bind-utils

ip0_noprefix=$(gawk -v x=${int_ip} 'BEGIN{split(x,ar,"/");print ar[1]}')

forwarddns=$(gawk -v x=${ext_dns} 'BEGIN{split(x,ar,",");print ar[1]}')
if [ -z ${forwarddns} ]; then
forwarddns=8.8.8.8
fi

loudrun firewall-cmd --add-service=dns --zone=internal
loudrun firewall-cmd --add-service=dns --zone=external

loudrun firewall-cmd --permanent --add-service=dns --zone=internal
loudrun firewall-cmd --permanent --add-service=dns --zone=external

loudrun systemctl stop named.service
loudrun systemctl disable named.service
loudrun systemctl stop named-chroot.service



echo ---- add zonefile to /var/named/.

loudrun backupconf /var/named/${masterdomain}.zone

cat << __MYZONEFILE__ > /var/named/${masterdomain}.zone
\$TTL 86400
@ IN SOA localhost. root.${masterdomain}. (
					$(date +%Y%m%d%H); Serial
					28800 ; Refresh
					14400 ; Retry
					3600000 ; Expire
					86400 ) ; Minimum
${masterdomain}.	IN NS	${nhost}.${masterdomain}.
${masterdomain}.	IN MX	10	${nhost}.${masterdomain}.
${nhost}		IN	A	${ip0_noprefix}
__MYZONEFILE__

echo change owner /var/named/${masterdomain}.zone
loudrun chown root:named /var/named/${masterdomain}.zone

echo change /etc/named.conf
loudrun backupconf /etc/named.conf

cat << __MYNAMEDCONF__ > /etc/named.conf
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
options {
listen-on port 53 { any; };
#listen-on-v6 port 53 { ::1; };
directory "/var/named";
dump-file "/var/named/data/cache_dump.db";
statistics-file "/var/named/data/named_stats.txt";
memstatistics-file "/var/named/data/named_mem_stats.txt";
allow-query { any; };

/*
- If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
- If you are building a RECURSIVE (caching) DNS server, you need to enable
recursion.
- If your recursive DNS server has a public IP address, you MUST enable access
control to limit queries to your legitimate users. Failing to do so will
cause your server to become part of large scale DNS amplification
attacks. Implementing BCP38 within your network would greatly
reduce such attack surface
*/
recursion yes;
dnssec-enable yes;
dnssec-validation yes;
dnssec-lookaside auto;
/* Path to ISC DLV key */
bindkeys-file "/etc/named.iscdlv.key";
managed-keys-directory "/var/named/dynamic";
pid-file "/run/named/named.pid";
session-keyfile "/run/named/session.key";
forwarders{ ${forwarddns}; };
};
logging {
channel default_debug {
file "data/named.run";
severity dynamic;
};
};
zone "." IN {
type hint;
file "named.ca";
};

zone "${masterdomain}" IN { 
type master; 
file "${masterdomain}.zone";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

__MYNAMEDCONF__

echo change owner /etc/named.conf
loudrun chown root:named /etc/named.conf

loudrun systemctl start named-chroot.service
loudrun systemctl enable named-chroot.service

echo ---- Bind setup DONE.

echo ---- change DNS1,2  to  127.0.0.1 and ${forwarddns}.
loudrun nmcli con mod ${ext_con} ipv4.dns "127.0.0.1,${forwarddns}"

echo please "'shutdown -r now' or down/up ${ext_con}"
