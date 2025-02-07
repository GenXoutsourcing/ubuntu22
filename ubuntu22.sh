#!/bin/sh

echo "Vicidial installation Ubuntu20 with WebPhone(WebRTC/SIP.js)"



apt install build-essential linux-headers-`uname -r` -y 

curl -LsSO https://r.mariadb.com/downloads/mariadb_repo_setup

echo "ceaa5bd124c4d10a892c384e201bb6e0910d370ebce235306d2e4b860ed36560 mariadb_repo_setup" \
    | sha256sum -c -

chmod +x mariadb_repo_setup
./mariadb_repo_setup \
   --mariadb-server-version="mariadb-10.6"


add-apt-repository ppa:ondrej/php  -y

apt update -y
apt upgrade -y



apt-get install -y apache2 apache2-bin apache2-data libapache2-mod-php php php-xcache php-dev php-mbstring php-cli php-common php-json php-mysql php-readline sox lame screen libnet-telnet-perl libasterisk-agi-perl mariadb-server mariadb-client libelf-dev autogen libtool shtool libdbd-mysql-perl libmysqlclient-dev libsrtp2-dev uuid-dev libssl-dev git curl wget php8.3-mysqli libnewt-dev libncurses5-dev ipset subversion libsqlite3-dev build-essential libjansson-dev libxml2-dev libc6-i386 unzip sqlite autoconf automake zlib1g zlib1g-dev unixodbc-dev make clang libedit-dev libjansson4 libncurses-dev sqlite3 certbot python3-certbot-apache php8.3-fpm iftop

ldconfig

apt update -y
apt upgrade -y




tee -a /etc/php/8.3/fpm/php.ini <<EOF

error_reporting  =  E_ALL & ~E_NOTICE
memory_limit = 2048M
short_open_tag = On
max_execution_time = 3330
max_input_time = 3360
post_max_size = 448M
upload_max_filesize = 442M
default_socket_timeout = 3360
date.timezone = America/New_York
max_input_vars = 40000
EOF



tee -a /etc/apache2/apache2.conf <<EOF

CustomLog /dev/null common

Alias /RECORDINGS/MP3 "/var/spool/asterisk/monitorDONE/MP3/"

<Directory "/var/spool/asterisk/monitorDONE/MP3/">
    Options Indexes MultiViews
    AllowOverride None
    Require all granted
</Directory>

###Update IP to your server to block direct IP access
#<VirtualHost *:80>
#ServerName xxx.xxx.xxx.xxx
#Redirect 403 /
#ErrorDocument 403 "Sorry, Direct IP access not allowed"
#DocumentRoot /var/www/html
#UserDir disabled
#</VirtualHost>


#<VirtualHost *:80>
#    ServerName other.example.com
#</VirtualHost>

###Copy to ssl.conf and enter server IP
#<IfModule mod_ssl.c>
#    <VirtualHost *:443>
#        ServerName xxx.xxx.xxx.xxx
#        Redirect 403 /
#        DocumentRoot /var/www/html
#    </VirtualHost>
#</IfModule>

Timeout 600

EOF


systemctl enable php8.3-fpm
systemctl start php8.3-fpm
a2enmod proxy_fcgi setenvif
a2enconf php8.3-fpm
systemctl reload apache2




cp /etc/mysql/my.cnf /etc/mysql/my.cnf.original
echo "" > /etc/mysql/my.cnf


cat <<MYSQLCONF>> /etc/mysql/my.cnf
[mysql.server]
user = mysql
#basedir = /var/lib

[client]
port = 3306
socket = /run/mysqld/mysqld.sock

[mysqld]
#bind-address = 127.0.0.1 # Uncomment for local/socket access only, will brick network access
#port = 3306 # Do not uncomment unless you know what you are doing, can brick your database connectivity
#socket = /var/lib/mysql/mysql.sock # Same note as above
socket = /run/mysqld/mysqld.sock

# Stuff to tune for your hardware
max_connections=2000 # If you have a dedicated database, change this to 2000
key_buffer_size = 12G # Increase to be approximately 60% of system RAM when you have more then 8GB in the system

# In general most of the below settings don't need tuning
log-error = /var/log/mysqld/mysqld.log
long_query_time = 3
slow_query_log = 1
slow_query_log_file = /var/log/mysqld/slow-queries.log
log-slow-verbosity=query_plan,explain
#secure_file_priv = /var/lib/mysql-files # Only allow LOAD DATA INFILE from this directory as a security feature
log_bin = /var/lib/mysql/mysql-bin
binlog_format=mixed
binlog_direct_non_transactional_updates=1
relay_log=/var/lib/mysql/mysql-relay-bin
datadir = /var/lib/mysql
server-id = 1 # Master should be 1, and all slaves should have a unique ID number
slave-skip-errors = 1032,1690,1062
slave_parallel_threads=20
slave-parallel-mode=optimistic
slave_parallel_max_queued=2M
skip-external-locking
skip-name-resolve
connect_timeout=60
max_allowed_packet = 16M
table_open_cache = 4096
table_definition_cache=16384
sort_buffer_size = 4M
net_buffer_length = 8K
read_buffer_size = 4M
read_rnd_buffer_size = 16M
myisam_sort_buffer_size = 128M
query-cache-size = 0
expire_logs_days = 3
concurrent_insert = 2
myisam_repair_threads = 4
myisam_recover_option=DEFAULT
tmpdir = /tmp/
thread_cache_size = 100
join_buffer_size = 1M
myisam_use_mmap=1
open_files_limit=24576
max_heap_table_size=512M
tmp_table_size = 32M
key_cache_segments=64
sql_mode=NO_ENGINE_SUBSTITUTION
log_warnings=1 # Silence the noise!!!

#old_passwords = 0
#ft_min_word_len = 3
#query-cache-type = 1
#table_cache = 1024
#max_tmp_tables = 64
#thread_concurrency = 8
#no-auto-rehash
default-storage-engine=MyISAM

# If using replication, uncomment log-bin below
#log-bin = mysql-bin

### By default only replicate the 'asterisk' database for ViciDial, comment out to replicate everything
### Make sure you do a full database dump if not just replicating asterisk database
#replicate_do_db=asterisk

### Comment out the tables below here if you really need them replicated to the slave, these are PERFORMANCE HOGS!
### Most of these tables are MEMORY tables which aren't persistent or used solely as tables for tracking the progress
### of things temporarily before doing real things like log inserts or lead updates
#replicate-ignore-table=asterisk.vicidial_live_agents
#replicate-ignore-table=asterisk.live_sip_channels
#replicate-ignore-table=asterisk.live_channels
#replicate-ignore-table=asterisk.vicidial_auto_calls
#replicate-ignore-table=asterisk.server_updater
#replicate-ignore-table=asterisk.web_client_sessions
#replicate-ignore-table=asterisk.vicidial_hopper
#replicate-ignore-table=asterisk.vicidial_campaign_server_status
#replicate-ignore-table=asterisk.parked_channels
#replicate-ignore-table=asterisk.vicidial_manager
#replicate-ignore-table=asterisk.cid_channels_recent
#replicate-wild-ignore-table=asterisk.cid_channels_recent_%


### Yes, we need this for system tables, so no need to tune anything here for ViciDial settings, these are just for the mysql tables and internal stuff
innodb_buffer_pool_size = 128M
innodb_file_format = Barracuda # Deprecated in future releases as this is the only supported format, eventually
innodb_file_per_table = ON
innodb_flush_method=O_DIRECT
innodb_flush_log_at_trx_commit=2
innodb_log_buffer_size=8M

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash

[isamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer = 256M
sort_buffer_size = 256M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

[mysqld_safe]
#log-error = /var/log/mysqld/mysqld.log
#pid-file = /var/run/mysqld/mysqld.pid
MYSQLCONF




mkdir /var/log/mysqld
touch /var/log/mysqld/slow-queries.log
chown -R mysql:mysql /var/log/mysqld
systemctl restart mariadb



#################
#CPM install
#cd /usr/src/vicidial-install-scripts
#curl -fsSL https://raw.githubusercontent.com/skaji/cpm/main/cpm | perl - install -g App::cpm
#/usr/local/bin/cpm install -g
#############


read -p 'Press Enter to continue Install perl modules: '


#Install CPAMN
cd /usr/bin/
apt install cpanminus -y
curl -LOk http://xrl.us/cpanm
chmod +x cpanm
cpanm readline --force



cpanm -f File::HomeDir
cpanm -f File::Which
cpanm CPAN::Meta::Requirements
cpanm -f CPAN
cpanm YAML
cpanm MD5
cpanm Digest::MD5
cpanm Digest::SHA1
cpanm Bundle::CPAN
cpanm DBI
cpanm -f DBD::MariaDB
cpanm Net::Telnet
cpanm Time::HiRes
cpanm Net::Server
cpanm Switch
cpanm Mail::Sendmail
cpanm Unicode::Map
cpanm Jcode
cpanm Spreadsheet::WriteExcel
cpanm OLE::Storage_Lite
cpanm Proc::ProcessTable
cpanm IO::Scalar
cpanm Spreadsheet::ParseExcel
cpanm Curses
cpanm Getopt::Long
cpanm Net::Domain
cpanm Term::ReadKey
cpanm Term::ANSIColor
cpanm Spreadsheet::XLSX
cpanm Spreadsheet::Read
cpanm LWP::UserAgent
cpanm HTML::Entities
cpanm HTML::Strip
cpanm HTML::FormatText
cpanm HTML::TreeBuilder
cpanm Time::Local
cpanm MIME::Decoder
cpanm Mail::POP3Client
cpanm Mail::IMAPClient
cpanm Mail::Message
cpanm IO::Socket::SSL
cpanm MIME::Base64
cpanm MIME::QuotedPrint
cpanm Crypt::Eksblowfish::Bcrypt
cpanm Crypt::RC4
cpanm Text::CSV
cpanm Text::CSV_XS


apt update -y
apt upgrade -y
apt autoremove -y


read -p 'Press Enter to continue And Install Dahdi: '
#Install dahdi

cd /usr/src/

wget https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-3.4.0+3.4.0.tar.gz
tar -xzvf dahdi-linux-complete-3.4.0+3.4.0.tar.gz
cd dahdi-linux-complete-3.4.0+3.4.0

make clean
make
make install
make install-config

cd tools
make clean
make
make install
make install-config

cp /etc/dahdi/system.conf.sample /etc/dahdi/system.conf


modprobe dahdi
modprobe dahdi_dummy
/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv

systemctl enable dahdi
service dahdi start
service dahdi status



read -p 'Press Enter to continue And Install Asterisk: '


#Install Asterisk Perl
cd /usr/src
wget http://download.vicidial.com/required-apps/asterisk-perl-0.08.tar.gz
tar xzf asterisk-perl-0.08.tar.gz
cd asterisk-perl-0.08
perl Makefile.PL
make all
make install 



cd /usr/src
wget https://download.vicidial.com/required-apps/asterisk-18.21.0-vici.tar.gz		
tar -xvf asterisk-18.21.0-vici.tar.gz
cd asterisk-18.21.0-vici/

: ${JOBS:=$(( $(nproc) + $(nproc) / 2 ))}
./configure --libdir=/usr/lib --with-gsm=internal --enable-opus --enable-srtp --with-ssl --enable-asteriskssl --with-pjproject-bundled --with-jansson-bundled

make menuselect/menuselect menuselect-tree menuselect.makeopts
#enable app_meetme
menuselect/menuselect --enable app_meetme menuselect.makeopts
#enable res_http_websocket
menuselect/menuselect --enable res_http_websocket menuselect.makeopts
#enable res_srtp
menuselect/menuselect --enable res_srtp menuselect.makeopts
make -j ${JOBS} all
make install
make samples
sed -i 's|noload = chan_sip.so|;noload = chan_sip.so|g' /etc/asterisk/modules.conf

################sed -i '$ a\ noload => res_timing_timerfd.so\ noload => res_timing_kqueue.so\ noload => res_timing_pthread.so' modules.conf

read -p 'Press Enter to continue: '
echo 'Continuing...'




#Install astguiclient
echo "Installing astguiclient"
mkdir /usr/src/astguiclient
cd /usr/src/astguiclient
svn checkout -r 3878 svn://svn.eflo.net/agc_2-X/trunk
cd /usr/src/astguiclient/trunk




#Add mysql users and Databases
echo "%%%%%%%%%%%%%%%Please Enter Mysql Password Or Just Press Enter if you Dont have Password%%%%%%%%%%%%%%%%%%%%%%%%%%"
mysql -u root -p << MYSQLCREOF
CREATE DATABASE asterisk DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER 'cron'@'localhost' IDENTIFIED BY '1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@'%' IDENTIFIED BY '1234';
CREATE USER 'custom'@'localhost' IDENTIFIED BY 'custom1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO custom@'%' IDENTIFIED BY 'custom1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO cron@localhost IDENTIFIED BY '1234';
GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES on asterisk.* TO custom@localhost IDENTIFIED BY 'custom1234';
GRANT RELOAD ON *.* TO cron@'%';
GRANT RELOAD ON *.* TO cron@localhost;
GRANT RELOAD ON *.* TO custom@'%';
GRANT RELOAD ON *.* TO custom@localhost;
flush privileges;
use asterisk;
\. /usr/src/astguiclient/trunk/extras/MySQL_AST_CREATE_tables.sql
\. /usr/src/astguiclient/trunk/extras/first_server_install.sql
update servers set asterisk_version='18.21.0-vici';
quit
MYSQLCREOF



read -p 'Press Enter to continue: '
echo 'Continuing...'




cat <<ASTGUI>> /etc/astguiclient.conf
# astguiclient.conf - configuration elements for the astguiclient package
# this is the astguiclient configuration file
# all comments will be lost if you run install.pl again

# Paths used by astGUIclient
PATHhome => /usr/share/astguiclient
PATHlogs => /var/log/astguiclient
PATHagi => /var/lib/asterisk/agi-bin
PATHweb => /var/www/html
PATHsounds => /var/lib/asterisk/sounds
PATHmonitor => /var/spool/asterisk/monitor
PATHDONEmonitor => /var/spool/asterisk/monitorDONE

# The IP address of this machine
VARserver_ip => SERVERIP

# Database connection information
VARDB_server => localhost
VARDB_database => asterisk
VARDB_user => cron
VARDB_pass => 1234
VARDB_custom_user => custom
VARDB_custom_pass => custom1234
VARDB_port => 3306

# Alpha-Numeric list of the astGUIclient processes to be kept running
# (value should be listing of characters with no spaces: 123456)
#  X - NO KEEPALIVE PROCESSES (use only if you want none to be keepalive)
#  1 - AST_update
#  2 - AST_send_listen
#  3 - AST_VDauto_dial
#  4 - AST_VDremote_agents
#  5 - AST_VDadapt (If multi-server system, this must only be on one server)
#  6 - FastAGI_log
#  7 - AST_VDauto_dial_FILL (only for multi-server, this must only be on one server)
#  8 - ip_relay (used for blind agent monitoring)
#  9 - Timeclock auto logout
#  E - Email processor, (If multi-server system, this must only be on one server)
#  S - SIP Logger (Patched Asterisk 13 required)
VARactive_keepalives => 123456789ES

# Asterisk version VICIDIAL is installed for
VARasterisk_version => 18.X

# FTP recording archive connection information
VARFTP_host => 10.0.0.4
VARFTP_user => cron
VARFTP_pass => test
VARFTP_port => 21
VARFTP_dir => RECORDINGS
VARHTTP_path => http://10.0.0.4

# REPORT server connection information
VARREPORT_host => 10.0.0.4
VARREPORT_user => cron
VARREPORT_pass => test
VARREPORT_port => 21
VARREPORT_dir => REPORTS

# Settings for FastAGI logging server
VARfastagi_log_min_servers => 3
VARfastagi_log_max_servers => 16
VARfastagi_log_min_spare_servers => 2
VARfastagi_log_max_spare_servers => 8
VARfastagi_log_max_requests => 1000
VARfastagi_log_checkfordead => 30
VARfastagi_log_checkforwait => 60

# Expected DB Schema version for this install
ExpectedDBSchema => 1720

# 3rd-party add-ons for this install
KhompEnabled => 1

ASTGUI





echo "Replace IP address in Default"
echo "%%%%%%%%%Please Enter This Server IP ADD%%%%%%%%%%%%"
read serveripadd
sed -i s/SERVERIP/"$serveripadd"/g /etc/astguiclient.conf

echo "Install VICIDIAL"
perl install.pl --no-prompt --copy_sample_conf_files=Y

#Secure Manager 
sed -i s/0.0.0.0/127.0.0.1/g /etc/asterisk/manager.conf


#Add confbridge conferences to asterisk DB
mysql -u root -e "use asterisk; INSERT INTO vicidial_confbridges VALUES (9600000,'10.10.10.15','','0',NULL),(9600001,'10.10.10.15','','0',NULL),(9600002,'10.10.10.15','','0',NULL),(9600003,'10.10.10.15','','0',NULL),(9600004,'10.10.10.15','','0',NULL),(9600005,'10.10.10.15','','0',NULL),(9600006,'10.10.10.15','','0',NULL),(9600007,'10.10.10.15','','0',NULL),(9600008,'10.10.10.15','','0',NULL),(9600009,'10.10.10.15','','0',NULL),(9600010,'10.10.10.15','','0',NULL),(9600011,'10.10.10.15','','0',NULL),(9600012,'10.10.10.15','','0',NULL),(9600013,'10.10.10.15','','0',NULL),(9600014,'10.10.10.15','','0',NULL),(9600015,'10.10.10.15','','0',NULL),(9600016,'10.10.10.15','','0',NULL),(9600017,'10.10.10.15','','0',NULL),(9600018,'10.10.10.15','','0',NULL),(9600019,'10.10.10.15','','0',NULL),(9600020,'10.10.10.15','','0',NULL),(9600021,'10.10.10.15','','0',NULL),(9600022,'10.10.10.15','','0',NULL),(9600023,'10.10.10.15','','0',NULL),(9600024,'10.10.10.15','','0',NULL),(9600025,'10.10.10.15','','0',NULL),(9600026,'10.10.10.15','','0',NULL),(9600027,'10.10.10.15','','0',NULL),(9600028,'10.10.10.15','','0',NULL),(9600029,'10.10.10.15','','0',NULL),(9600030,'10.10.10.15','','0',NULL),(9600031,'10.10.10.15','','0',NULL),(9600032,'10.10.10.15','','0',NULL),(9600033,'10.10.10.15','','0',NULL),(9600034,'10.10.10.15','','0',NULL),(9600035,'10.10.10.15','','0',NULL),(9600036,'10.10.10.15','','0',NULL),(9600037,'10.10.10.15','','0',NULL),(9600038,'10.10.10.15','','0',NULL),(9600039,'10.10.10.15','','0',NULL),(9600040,'10.10.10.15','','0',NULL),(9600041,'10.10.10.15','','0',NULL),(9600042,'10.10.10.15','','0',NULL),(9600043,'10.10.10.15','','0',NULL),(9600044,'10.10.10.15','','0',NULL),(9600045,'10.10.10.15','','0',NULL),(9600046,'10.10.10.15','','0',NULL),(9600047,'10.10.10.15','','0',NULL),(9600048,'10.10.10.15','','0',NULL),(9600049,'10.10.10.15','','0',NULL),(9600050,'10.10.10.15','','0',NULL),(9600051,'10.10.10.15','','0',NULL),(9600052,'10.10.10.15','','0',NULL),(9600054,'10.10.10.15','','0',NULL),(9600055,'10.10.10.15','','0',NULL),(9600056,'10.10.10.15','','0',NULL),(9600057,'10.10.10.15','','0',NULL),(9600058,'10.10.10.15','','0',NULL),(9600059,'10.10.10.15','','0',NULL),(9600060,'10.10.10.15','','0',NULL),(9600061,'10.10.10.15','','0',NULL),
(9600062,'10.10.10.15','','0',NULL),(9600063,'10.10.10.15','','0',NULL),(9600064,'10.10.10.15','','0',NULL),(9600065,'10.10.10.15','','0',NULL),(9600066,'10.10.10.15','','0',NULL),(9600067,'10.10.10.15','','0',NULL),(9600068,'10.10.10.15','','0',NULL),(9600069,'10.10.10.15','','0',NULL),(9600070,'10.10.10.15','','0',NULL),(9600071,'10.10.10.15','','0',NULL),(9600072,'10.10.10.15','','0',NULL),(9600073,'10.10.10.15','','0',NULL),(9600074,'10.10.10.15','','0',NULL),(9600075,'10.10.10.15','','0',NULL),(9600076,'10.10.10.15','','0',NULL),(9600077,'10.10.10.15','','0',NULL),(9600078,'10.10.10.15','','0',NULL),(9600079,'10.10.10.15','','0',NULL),(9600080,'10.10.10.15','','0',NULL),(9600081,'10.10.10.15','','0',NULL),(9600082,'10.10.10.15','','0',NULL),(9600083,'10.10.10.15','','0',NULL),(9600084,'10.10.10.15','','0',NULL),(9600085,'10.10.10.15','','0',NULL),(9600086,'10.10.10.15','','0',NULL),(9600087,'10.10.10.15','','0',NULL),(9600088,'10.10.10.15','','0',NULL),(9600089,'10.10.10.15','','0',NULL),(9600090,'10.10.10.15','','0',NULL),(9600091,'10.10.10.15','','0',NULL),(9600092,'10.10.10.15','','0',NULL),(9600093,'10.10.10.15','','0',NULL),(9600094,'10.10.10.15','','0',NULL),(9600095,'10.10.10.15','','0',NULL),(9600096,'10.10.10.15','','0',NULL),(9600097,'10.10.10.15','','0',NULL),(9600098,'10.10.10.15','','0',NULL),(9600099,'10.10.10.15','','0',NULL),(9600100,'10.10.10.15','','0',NULL),(9600101,'10.10.10.15','','0',NULL),(9600102,'10.10.10.15','','0',NULL),(9600103,'10.10.10.15','','0',NULL),(9600104,'10.10.10.15','','0',NULL),(9600105,'10.10.10.15','','0',NULL),(9600106,'10.10.10.15','','0',NULL),(9600107,'10.10.10.15','','0',NULL),(9600108,'10.10.10.15','','0',NULL),(9600109,'10.10.10.15','','0',NULL),(9600110,'10.10.10.15','','0',NULL),(9600111,'10.10.10.15','','0',NULL),(9600112,'10.10.10.15','','0',NULL),(9600113,'10.10.10.15','','0',NULL),(9600114,'10.10.10.15','','0',NULL),(9600115,'10.10.10.15','','0',NULL),(9600116,'10.10.10.15','','0',NULL),(9600117,'10.10.10.15','','0',NULL),(9600118,'10.10.10.15','','0',NULL),(9600119,'10.10.10.15','','0',NULL),(9600120,'10.10.10.15','','0',NULL),(9600121,'10.10.10.15','','0',NULL),(9600122,'10.10.10.15','','0',NULL),(9600123,'10.10.10.15','','0',NULL),(9600124,'10.10.10.15','','0',NULL),(9600125,'10.10.10.15','','0',NULL),(9600126,'10.10.10.15','','0',NULL),(9600127,'10.10.10.15','','0',NULL),(9600128,'10.10.10.15','','0',NULL),(9600129,'10.10.10.15','','0',NULL),(9600130,'10.10.10.15','','0',NULL),(9600131,'10.10.10.15','','0',NULL),(9600132,'10.10.10.15','','0',NULL),(9600133,'10.10.10.15','','0',NULL),(9600134,'10.10.10.15','','0',NULL),(9600135,'10.10.10.15','','0',NULL),(9600136,'10.10.10.15','','0',NULL),(9600137,'10.10.10.15','','0',NULL),(9600138,'10.10.10.15','','0',NULL),(9600139,'10.10.10.15','','0',NULL),(9600140,'10.10.10.15','','0',NULL),(9600141,'10.10.10.15','','0',NULL),(9600142,'10.10.10.15','','0',NULL),(9600143,'10.10.10.15','','0',NULL),(9600144,'10.10.10.15','','0',NULL),(9600145,'10.10.10.15','','0',NULL),(9600146,'10.10.10.15','','0',NULL),(9600147,'10.10.10.15','','0',NULL),(9600148,'10.10.10.15','','0',NULL),(9600149,'10.10.10.15','','0',NULL),(9600150,'10.10.10.15','','0',NULL),(9600151,'10.10.10.15','','0',NULL),(9600152,'10.10.10.15','','0',NULL),(9600153,'10.10.10.15','','0',NULL),(9600154,'10.10.10.15','','0',NULL),(9600155,'10.10.10.15','','0',NULL),(9600156,'10.10.10.15','','0',NULL),(9600157,'10.10.10.15','','0',NULL),(9600158,'10.10.10.15','','0',NULL),(9600159,'10.10.10.15','','0',NULL),(9600160,'10.10.10.15','','0',NULL),(9600161,'10.10.10.15','','0',NULL),(9600162,'10.10.10.15','','0',NULL),(9600163,'10.10.10.15','','0',NULL),(9600164,'10.10.10.15','','0',NULL),(9600165,'10.10.10.15','','0',NULL),(9600166,'10.10.10.15','','0',NULL),(9600167,'10.10.10.15','','0',NULL),(9600168,'10.10.10.15','','0',NULL),(9600169,'10.10.10.15','','0',NULL),(9600170,'10.10.10.15','','0',NULL),(9600171,'10.10.10.15','','0',NULL),(9600172,'10.10.10.15','','0',NULL),(9600173,'10.10.10.15','','0',NULL),(9600174,'10.10.10.15','','0',NULL),(9600175,'10.10.10.15','','0',NULL),(9600176,'10.10.10.15','','0',NULL),(9600177,'10.10.10.15','','0',NULL),(9600178,'10.10.10.15','','0',NULL),(9600179,'10.10.10.15','','0',NULL),(9600180,'10.10.10.15','','0',NULL),(9600181,'10.10.10.15','','0',NULL),(9600182,'10.10.10.15','','0',NULL),(9600183,'10.10.10.15','','0',NULL),(9600184,'10.10.10.15','','0',NULL),(9600185,'10.10.10.15','','0',NULL),(9600186,'10.10.10.15','','0',NULL),(9600187,'10.10.10.15','','0',NULL),(9600188,'10.10.10.15','','0',NULL),(9600189,'10.10.10.15','','0',NULL),(9600190,'10.10.10.15','','0',NULL),(9600191,'10.10.10.15','','0',NULL),(9600192,'10.10.10.15','','0',NULL),(9600193,'10.10.10.15','','0',NULL),(9600194,'10.10.10.15','','0',NULL),(9600195,'10.10.10.15','','0',NULL),(9600196,'10.10.10.15','','0',NULL),(9600197,'10.10.10.15','','0',NULL),(9600198,'10.10.10.15','','0',NULL),(9600199,'10.10.10.15','','0',NULL),(9600200,'10.10.10.15','','0',NULL),(9600201,'10.10.10.15','','0',NULL),(9600202,'10.10.10.15','','0',NULL),(9600203,'10.10.10.15','','0',NULL),(9600204,'10.10.10.15','','0',NULL),(9600205,'10.10.10.15','','0',NULL),(9600206,'10.10.10.15','','0',NULL),(9600207,'10.10.10.15','','0',NULL),(9600208,'10.10.10.15','','0',NULL),(9600209,'10.10.10.15','','0',NULL),(9600210,'10.10.10.15','','0',NULL),(9600211,'10.10.10.15','','0',NULL),(9600212,'10.10.10.15','','0',NULL),(9600213,'10.10.10.15','','0',NULL),(9600214,'10.10.10.15','','0',NULL),(9600215,'10.10.10.15','','0',NULL),(9600216,'10.10.10.15','','0',NULL),(9600217,'10.10.10.15','','0',NULL),(9600218,'10.10.10.15','','0',NULL),(9600219,'10.10.10.15','','0',NULL),(9600220,'10.10.10.15','','0',NULL),(9600221,'10.10.10.15','','0',NULL),(9600222,'10.10.10.15','','0',NULL),(9600223,'10.10.10.15','','0',NULL),(9600224,'10.10.10.15','','0',NULL),(9600225,'10.10.10.15','','0',NULL),(9600226,'10.10.10.15','','0',NULL),(9600227,'10.10.10.15','','0',NULL),(9600228,'10.10.10.15','','0',NULL),(9600229,'10.10.10.15','','0',NULL),(9600230,'10.10.10.15','','0',NULL),(9600231,'10.10.10.15','','0',NULL),(9600232,'10.10.10.15','','0',NULL),(9600233,'10.10.10.15','','0',NULL),(9600234,'10.10.10.15','','0',NULL),(9600235,'10.10.10.15','','0',NULL),(9600236,'10.10.10.15','','0',NULL),(9600237,'10.10.10.15','','0',NULL),(9600238,'10.10.10.15','','0',NULL),(9600239,'10.10.10.15','','0',NULL),(9600240,'10.10.10.15','','0',NULL),(9600241,'10.10.10.15','','0',NULL),(9600242,'10.10.10.15','','0',NULL),(9600243,'10.10.10.15','','0',NULL),(9600244,'10.10.10.15','','0',NULL),(9600245,'10.10.10.15','','0',NULL),(9600246,'10.10.10.15','','0',NULL),(9600247,'10.10.10.15','','0',NULL),(9600248,'10.10.10.15','','0',NULL),(9600249,'10.10.10.15','','0',NULL),(9600250,'10.10.10.15','','0',NULL),(9600251,'10.10.10.15','','0',NULL),(9600252,'10.10.10.15','','0',NULL),(9600253,'10.10.10.15','','0',NULL),(9600254,'10.10.10.15','','0',NULL),(9600255,'10.10.10.15','','0',NULL),(9600256,'10.10.10.15','','0',NULL),(9600257,'10.10.10.15','','0',NULL),(9600258,'10.10.10.15','','0',NULL),(9600259,'10.10.10.15','','0',NULL),(9600260,'10.10.10.15','','0',NULL),(9600261,'10.10.10.15','','0',NULL),(9600262,'10.10.10.15','','0',NULL),(9600263,'10.10.10.15','','0',NULL),(9600264,'10.10.10.15','','0',NULL),(9600265,'10.10.10.15','','0',NULL),(9600266,'10.10.10.15','','0',NULL),(9600267,'10.10.10.15','','0',NULL),(9600268,'10.10.10.15','','0',NULL),(9600269,'10.10.10.15','','0',NULL),(9600270,'10.10.10.15','','0',NULL),(9600271,'10.10.10.15','','0',NULL),(9600272,'10.10.10.15','','0',NULL),(9600273,'10.10.10.15','','0',NULL),(9600274,'10.10.10.15','','0',NULL),(9600275,'10.10.10.15','','0',NULL),(9600276,'10.10.10.15','','0',NULL),(9600277,'10.10.10.15','','0',NULL),(9600278,'10.10.10.15','','0',NULL),(9600279,'10.10.10.15','','0',NULL),(9600280,'10.10.10.15','','0',NULL),(9600281,'10.10.10.15','','0',NULL),(9600282,'10.10.10.15','','0',NULL),(9600283,'10.10.10.15','','0',NULL),(9600284,'10.10.10.15','','0',NULL),(9600285,'10.10.10.15','','0',NULL),(9600286,'10.10.10.15','','0',NULL),(9600287,'10.10.10.15','','0',NULL),(9600288,'10.10.10.15','','0',NULL),(9600289,'10.10.10.15','','0',NULL),(9600290,'10.10.10.15','','0',NULL),(9600291,'10.10.10.15','','0',NULL),(9600292,'10.10.10.15','','0',NULL),(9600293,'10.10.10.15','','0',NULL),(9600294,'10.10.10.15','','0',NULL),(9600295,'10.10.10.15','','0',NULL),(9600296,'10.10.10.15','','0',NULL),(9600297,'10.10.10.15','','0',NULL),(9600298,'10.10.10.15','','0',NULL),(9600299,'10.10.10.15','','0',NULL);"


echo "Populate AREA CODES"
/usr/share/astguiclient/ADMIN_area_code_populate.pl
echo "Replace OLD IP. You need to Enter your Current IP here"
/usr/share/astguiclient/ADMIN_update_server_ip.pl --old-server_ip=10.10.10.15


perl install.pl --no-prompt




#Install Crontab
cat <<CRONTAB>> /var/spool/cron/crontabs/root

###Audio Sync hourly
* 1 * * * /usr/share/astguiclient/ADMIN_audio_store_sync.pl --upload --quiet

### Daily Backups ###
0 2 * * * /usr/share/astguiclient/ADMIN_backup.pl

###certbot renew
#51 23 1 * * /usr/bin/systemctl stop firewalld
#52 23 1 * * /usr/bin/certbot renew
#53 23 1 * * /usr/bin/systemctl start firewalld
#54 23 1 * * /usr/bin/systemctl restart httpd

### recording mixing/compressing/ftping scripts
#0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * * /usr/share/astguiclient/AST_CRON_audio_1_move_mix.pl
0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * * /usr/share/astguiclient/AST_CRON_audio_1_move_mix.pl --MIX
0,3,6,9,12,15,18,21,24,27,30,33,36,39,42,45,48,51,54,57 * * * * /usr/share/astguiclient/AST_CRON_audio_1_move_VDonly.pl
1,4,7,10,13,16,19,22,25,28,31,34,37,40,43,46,49,52,55,58 * * * * /usr/share/astguiclient/AST_CRON_audio_2_compress.pl --MP3 --HTTPS
#2,5,8,11,14,17,20,23,26,29,32,35,38,41,44,47,50,53,56,59 * * * * /usr/share/astguiclient/AST_CRON_audio_3_ftp.pl --MP3

### keepalive script for astguiclient processes
* * * * * /usr/share/astguiclient/ADMIN_keepalive_ALL.pl --cu3way

### kill Hangup script for Asterisk updaters
* * * * * /usr/share/astguiclient/AST_manager_kill_hung_congested.pl

### updater for voicemail
* * * * * /usr/share/astguiclient/AST_vm_update.pl

### updater for conference validator
* * * * * /usr/share/astguiclient/AST_conf_update.pl

### flush queue DB table every hour for entries older than 1 hour
11 * * * * /usr/share/astguiclient/AST_flush_DBqueue.pl -q

### fix the vicidial_agent_log once every hour and the full day run at night
33 * * * * /usr/share/astguiclient/AST_cleanup_agent_log.pl
50 0 * * * /usr/share/astguiclient/AST_cleanup_agent_log.pl --last-24hours

## uncomment below if using QueueMetrics
#*/5 * * * * /usr/share/astguiclient/AST_cleanup_agent_log.pl --only-qm-live-call-check

## uncomment below if using Vtiger
#1 1 * * * /usr/share/astguiclient/Vtiger_optimize_all_tables.pl --quiet

### updater for VICIDIAL hopper
* * * * * /usr/share/astguiclient/AST_VDhopper.pl -q

### adjust the GMT offset for the leads in the vicidial_list table
1 1,7 * * * /usr/share/astguiclient/ADMIN_adjust_GMTnow_on_leads.pl --debug

### reset several temporary-info tables in the database
2 1 * * * /usr/share/astguiclient/AST_reset_mysql_vars.pl

### optimize the database tables within the asterisk database
3 1 * * * /usr/share/astguiclient/AST_DB_optimize.pl

## adjust time on the server with ntp
#30 * * * * /usr/sbin/ntpdate -u pool.ntp.org 2>/dev/null 1>&amp;2

### VICIDIAL agent time log weekly and daily summary report generation
2 0 * * 0 /usr/share/astguiclient/AST_agent_week.pl
22 0 * * * /usr/share/astguiclient/AST_agent_day.pl

### VICIDIAL campaign export scripts (OPTIONAL)
#32 0 * * * /usr/share/astguiclient/AST_VDsales_export.pl
#42 0 * * * /usr/share/astguiclient/AST_sourceID_summary_export.pl

### remove old recordings
#24 0 * * * /usr/bin/find /var/spool/asterisk/monitorDONE -maxdepth 2 -type f -mtime +7 -print | xargs rm -f
#26 1 * * * /usr/bin/find /var/spool/asterisk/monitorDONE/MP3 -maxdepth 2 -type f -mtime +65 -print | xargs rm -f
#25 1 * * * /usr/bin/find /var/spool/asterisk/monitorDONE/FTP -maxdepth 2 -type f -mtime +1 -print | xargs rm -f
24 1 * * * /usr/bin/find /var/spool/asterisk/monitorDONE/ORIG -maxdepth 2 -type f -mtime +1 -print | xargs rm -f


### roll logs monthly on high-volume dialing systems
30 1 1 * * /usr/share/astguiclient/ADMIN_archive_log_tables.pl --DAYS=45

### remove old vicidial logs and asterisk logs more than 2 days old
28 0 * * * /usr/bin/find /var/log/astguiclient -maxdepth 1 -type f -mtime +2 -print | xargs rm -f
29 0 * * * /usr/bin/find /var/log/asterisk -maxdepth 3 -type f -mtime +2 -print | xargs rm -f
30 0 * * * /usr/bin/find / -maxdepth 1 -name "screenlog.0*" -mtime +4 -print | xargs rm -f

### cleanup of the scheduled callback records
25 0 * * * /usr/share/astguiclient/AST_DB_dead_cb_purge.pl --purge-non-cb -q

### GMT adjust script - uncomment to enable
#45 0 * * * /usr/share/astguiclient/ADMIN_adjust_GMTnow_on_leads.pl --list-settings

### Dialer Inventory Report
1 7 * * * /usr/share/astguiclient/AST_dialer_inventory_snapshot.pl -q --override-24hours

### inbound email parser
* * * * * /usr/share/astguiclient/AST_inbound_email_parser.pl

### Daily Reboot
#30 6 * * * /sbin/reboot

######TILTIX GARBAGE FILES DELETE
#00 22 * * * root cd /tmp/ && find . -name '*TILTXtmp*' -type f -delete

### Dynportal
#@reboot /usr/bin/VB-firewall --whitelist=ViciWhite --dynamic --quiet
#* * * * * /usr/bin/VB-firewall --whitelist=ViciWhite --dynamic --quiet
#* * * * * sleep 10; /usr/bin/VB-firewall --white --dynamic --quiet
#* * * * * sleep 20; /usr/bin/VB-firewall --white --dynamic --quiet
#* * * * * sleep 30; /usr/bin/VB-firewall --white --dynamic --quiet
#* * * * * sleep 40; /usr/bin/VB-firewall --white --dynamic --quiet
#* * * * * sleep 50; /usr/bin/VB-firewall --white --dynamic --quiet


CRONTAB

sudo chmod 600 /var/spool/cron/crontabs/root


#Install rc.local
sudo sed -i 's|exit 0|### exit 0|g' /etc/rc.local

tee -a /etc/rc.local <<EOF


# OPTIONAL enable ip_relay(for same-machine trunking and blind monitoring)

/usr/share/astguiclient/ip_relay/relay_control start 2>/dev/null 1>&2



### start up the MySQL server

systemctl start mariadb.service


### start up the apache web server

#systemctl start httpd.service


### roll the Asterisk logs upon reboot

/usr/share/astguiclient/ADMIN_restart_roll_logs.pl


### clear the server-related records from the database

/usr/share/astguiclient/AST_reset_mysql_vars.pl


### load dahdi drivers

modprobe dahdi

/usr/sbin/dahdi_cfg -vvvvvvvvvvvvv


### sleep for 20 seconds before launching Asterisk

sleep 20


### start up asterisk

/usr/share/astguiclient/start_asterisk_boot.pl

exit 0

EOF


chmod -v +x /etc/rc.local
systemctl is-enabled rc-local.service
systemctl status rc-local.service
systemctl enable rc-local.service


##Install Sounds
cd /usr/src
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-wav-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-core-sounds-en-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-wav-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-extra-sounds-en-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-gsm-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-ulaw-current.tar.gz
wget http://downloads.asterisk.org/pub/telephony/sounds/asterisk-moh-opsound-wav-current.tar.gz

#Place the audio files in their proper places:
cd /var/lib/asterisk/sounds
tar -zxf /usr/src/asterisk-core-sounds-en-gsm-current.tar.gz
tar -zxf /usr/src/asterisk-core-sounds-en-ulaw-current.tar.gz
tar -zxf /usr/src/asterisk-core-sounds-en-wav-current.tar.gz
tar -zxf /usr/src/asterisk-extra-sounds-en-gsm-current.tar.gz
tar -zxf /usr/src/asterisk-extra-sounds-en-ulaw-current.tar.gz
tar -zxf /usr/src/asterisk-extra-sounds-en-wav-current.tar.gz

mkdir /var/lib/asterisk/mohmp3
mkdir /var/lib/asterisk/quiet-mp3
ln -s /var/lib/asterisk/mohmp3 /var/lib/asterisk/default

cd /var/lib/asterisk/mohmp3
tar -zxf /usr/src/asterisk-moh-opsound-gsm-current.tar.gz
tar -zxf /usr/src/asterisk-moh-opsound-ulaw-current.tar.gz
tar -zxf /usr/src/asterisk-moh-opsound-wav-current.tar.gz
rm -f CHANGES*
rm -f LICENSE*
rm -f CREDITS*

cd /var/lib/asterisk/moh
rm -f CHANGES*
rm -f LICENSE*
rm -f CREDITS*

cd /var/lib/asterisk/sounds
rm -f CHANGES*
rm -f LICENSE*
rm -f CREDITS*


cd /var/lib/asterisk/quiet-mp3
sox ../mohmp3/macroform-cold_day.wav macroform-cold_day.wav vol 0.25
sox ../mohmp3/macroform-cold_day.gsm macroform-cold_day.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/macroform-cold_day.ulaw -t ul macroform-cold_day.ulaw vol 0.25
sox ../mohmp3/macroform-robot_dity.wav macroform-robot_dity.wav vol 0.25
sox ../mohmp3/macroform-robot_dity.gsm macroform-robot_dity.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/macroform-robot_dity.ulaw -t ul macroform-robot_dity.ulaw vol 0.25
sox ../mohmp3/macroform-the_simplicity.wav macroform-the_simplicity.wav vol 0.25
sox ../mohmp3/macroform-the_simplicity.gsm macroform-the_simplicity.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/macroform-the_simplicity.ulaw -t ul macroform-the_simplicity.ulaw vol 0.25
sox ../mohmp3/reno_project-system.wav reno_project-system.wav vol 0.25
sox ../mohmp3/reno_project-system.gsm reno_project-system.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/reno_project-system.ulaw -t ul reno_project-system.ulaw vol 0.25
sox ../mohmp3/manolo_camp-morning_coffee.wav manolo_camp-morning_coffee.wav vol 0.25
sox ../mohmp3/manolo_camp-morning_coffee.gsm manolo_camp-morning_coffee.gsm vol 0.25
sox -t ul -r 8000 -c 1 ../mohmp3/manolo_camp-morning_coffee.ulaw -t ul manolo_camp-morning_coffee.ulaw vol 0.25




echo "Enter the DOMAIN NAME HERE. ***********IF YOU DONT HAVE ONE PLEASE DONT CONTINUE: "
read DOMAINNAME

#wget -O /etc/httpd/conf.d/$DOMAINNAME.conf https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/DOMAINNAME.conf
wget -O /etc/apache2/sites-enabled/$DOMAINNAME.conf https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/DOMAINNAME.conf

sed -i s/DOMAINNAME/"$DOMAINNAME"/g /etc/apache2/sites-enabled/$DOMAINNAME.conf

echo "Please Enter EMAIL and Agree the Terms and Conditions "
certbot --apache -d $DOMAINNAME --agree-tos -m steve.turner@genxoutsourcing.com -n

echo "Change http.conf in Asterisk"
wget -O /etc/asterisk/http.conf https://raw.githubusercontent.com/jaganthoutam/vicidial-install-scripts/main/asterisk-http.conf
sed -i s/DOMAINNAME/"$DOMAINNAME"/g /etc/asterisk/http.conf

echo "Reloading Asterisk"
rasterisk -x reload

echo "Add DOMAINAME servers web_socket_url"
echo "%%%%%%%%%%%%%%%This Wont work if you SET root Password%%%%%%%%%%%%%%%"
mysql -e "use asterisk; update servers set web_socket_url='wss://$DOMAINNAME:8089/ws';"

echo "Add DOMAINAME system_settings webphone_url"
echo "%%%%%%%%%%%%%%%This Wont work if you SET root Password%%%%%%%%%%%%%%%"
mysql -e "use asterisk; update system_settings set webphone_url='https://phone.viciphone.com/viciphone.php';"


echo "Create WEBRTC Template"
mysql -e "use asterisk; INSERT INTO vicidial_conf_templates (template_id,template_name,template_contents,user_group) values('WEBRTC' ,'WEBRTC Default Phones','','---ALL---');"
mysql -e "use asterisk; update vicidial_conf_templates set template_contents='
type=friend 
host=dynamic
encryption=yes
avpf=yes
icesupport=yes
directmedia=no
transport=wss
force_avp=yes
dtlsenable=yes
dtlsverify=no
dtlscertfile=/etc/letsencrypt/live/$DOMAINNAME/cert.pem
dtlsprivatekey=/etc/letsencrypt/live/$DOMAINNAME/privkey.pem
dtlssetup=actpass
rtcp_mux=yes' where template_id='WEBRTC';"

echo "update the Phone tables to set is_webphone to Y default"
mysql -e "use asterisk; ALTER TABLE phones MODIFY COLUMN is_webphone ENUM('Y','N','Y_API_LAUNCH') default 'Y';"
mysql -e "use asterisk; update phones set template_id='WEBRTC';"


cat <<WELCOME>> /var/www/html/index.html
<META HTTP-EQUIV=REFRESH CONTENT="1; URL=/vicidial/welcome.php">
Please Hold while I redirect you!
WELCOME

chmod 777 /var/spool/asterisk/monitorDONE

tee -a /etc/systemd/system.conf <<EOF
DefaultLimitNOFILE=65536
EOF

cp /usr/src/astguiclient/trunk/extras/KHOMP/KHOMP_updater.pl /usr/share/astguiclient/KHOMP_updater.pl
chmod 0777 /usr/share/astguiclient/KHOMP_updater.pl



apt install firewalld -y
systemctl enable firewalld
systemctl start firewalld


firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='74.208.129.213' accept"
firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='45.3.191.82' accept"
firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='167.99.6.117' accept"
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-port=8089/tcp
firewall-cmd --permanent --add-port=8089/udp
firewall-cmd --permanent --remove-service=ssh
firewall-cmd --permanent --remove-service=cockpit
firewall-cmd --permanent --remove-service=dhcpv6-client
firewall-cmd --permanent --add-port=10000-20000/udp
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="3.216.197.4" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="34.196.59.250" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="34.200.206.65" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="13.56.51.225" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="54.151.113.200" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="54.193.203.21" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="3.216.197.4" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="34.196.59.250" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="34.200.206.65" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="13.56.51.225" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="54.151.113.200" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="54.193.203.21" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.231.161" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.231.161" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.241.161" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.241.161" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.231.192/28" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.231.192/28" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.241.192/28" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.241.192/28" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.231.225" port protocol="udp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="209.200.231.225" port protocol="tcp" port="5060" accept'
firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.0.0/24' accept"
firewall-cmd --reload



reboot
