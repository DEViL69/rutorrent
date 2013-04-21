#!/bin/bash
#
# ~~~ WELCOME ~~~
# SCRiPT BY DEViL69
#
#
#
STARTRT=https://github.com/DEViL69/rutorrent/blob/master/rtstart.sh
INSTALL_DIR=/install
RTCONFIG="/root/.rtorrent.rc" 
DL_DIR=/rt/rtorrent
PORTRANGE=9000-9100 
RUVERS=http://rutorrent.googlecode.com/files/rutorrent-3.4.tar.gz
RUADDVERS=http://rutorrent.googlecode.com/files/plugins-3.4.tar.gz
RUDIR=/var/www
RTRC=https://github.com/DEViL69/rutorrent/blob/master/rtorrent.rc

function checkifroot(){
if [[ $EUID -ne 0 ]];then
    echo "rTorrent Installer: User has to be root"
    echo "Please run this script as root!"
    exit 1
fi
}

# function to set download directoy
function setdldir(){
read -p "Download directory? (Default is $DL_DIR):" -e DL1
if [ -n "$DL1" ]
then
  DL_DIR="$DL1"
else
  DL_DIR="$DL_DIR"
fi
echo "Download directory is now set to $DL_DIR"
}
# end download function

# function to set session directory
#function setsessiondir(){
#read -p "Session directory? (Default is $SESSION_DIR):" -e SE1
#if [ -n "$SE1" ]
#then 
#  SESSION_DIR="$SE1"
#else
#  SESSION_DIR="$SESSION_DIR"
#fi
#echo "Session directory is now set to $SESSION_DIR"
#}
#end session function


function update(){
echo "UPDATING THE SYSTEM"
sudo apt-get update 
sudo apt-get upgrade -y
}

function depend(){
echo "INSTALLING DEPENDENCIES"
sudo apt-get install subversion build-essential automake libtool libcppunit-dev libcurl3-dev libsigc++-2.0-dev unzip unrar curl libncurses-dev -y
sudo apt-get install apache2 php5 php5-cli php5-curl -y
sudo apt-get install libapache2-mod-scgi -y
ln -s /etc/apache2/mods-available/scgi.load /etc/apache2/mods-enabled/scgi.load
}

function xmlrpc(){
echo "INSTALLING XMLRPC"
sleep 2
cd $INSTALL_DIR
sudo svn checkout http://xmlrpc-c.svn.sourceforge.net/svnroot/xmlrpc-c/stable xmlrpc-c
cd xmlrpc-c
sudo ./configure --disable-cplusplus
sudo make -s
sudo make -s install
}

function libtorrent(){
echo "INSTALLING LIBTORRENT"
sleep 2
cd $INSTALL_DIR
sudo wget -q http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.2.tar.gz
sudo tar xvf libtorrent-0.13.2.tar.gz
cd libtorrent-0.13.2
sudo ./autogen.sh
sudo ./configure
sudo make -s
sudo make -s install
}

function rtorrent(){
echo "INSTALLING RTORRENT"
sleep 2
cd $INSTALL_DIR
sudo wget -q http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.2.tar.gz
sudo tar xvf rtorrent-0.9.2.tar.gz
cd rtorrent-0.9.2
sudo ./autogen.sh
sudo ./configure --with-xmlrpc-c
sudo make -s
sudo make -s install
sudo ldconfig
}

#needed for source files
function mkdirs(){
echo "MAKING DIRECTORIES"
sudo mkdir -p $INSTALL_DIR
sudo mkdir -p $DL_DIR/downloads
sudo mkdir -p $DL_DIR/sessions
sudo mkdir -p $DL_DIR/watch
sudo chmod -R 777 $DL_DIR
sudo chown -R www-data:www-data $DL_DIR
}

# .rtorrent.rc file creation
#send dl and session variables to file
function checkrtconfig(){
# check if $RTCONFIG exists if not it will create 
if [ -f $RTCONFIG ]
then
    echo "The file exists"
    echo "I will replace it for you!"
    rm -rf $RTCONFIG
    configpaste
else
    configpaste
fi
}

function configpaste(){
wget -q $RTRC
mv default.rtorrent.rc $RTCONFIG
cat >> $RTCONFIG <<-END_PASTE
directory = $DL_DIR/downloads
session = $DL_DIR/sessions
port_range = $PORTRANGE
scgi_port = 127.0.0.1:5000
END_PASTE
# end paste
}


function installrutorrent(){
echo "INSTALLING RUTORRENT"
sleep 2
cd $INSTALL_DIR
sudo wget -q $RUVERS
sudo tar xvf rutorrent-3.4.tar.gz
sudo mv rutorrent $RUDIR
sudo wget -q $RUADDVERS
sudo tar xvf plugins-3.4.tar.gz
sudo mv plugins $RUDIR/rutorrent
sudo rm -rf $RUDIR/rutorrent/plugins/mediainfo
sudo rm -rf $RUDIR/rutorrent/plugins/screenshots
sudo chown -R www-data:www-data $RUDIR/rutorrent
}

function setauthfile(){
echo "CONFIGURING AUTH FILE"
sleep 2
cd $RUDIR/rutorrent
cat >> /etc/apache2/httpd.conf <<-END_PASTE
<VirtualHost *:80>
DocumentRoot /var/www
<Location /rutorrent>
Order Deny,Allow
AuthUserFile $RUDIR/rutorrent/.htpasswd
AuthName "ruTorrent login"
AuthType Basic
require valid-user
</Location>
SCGIMount /RPC2 127.0.0.1:5000
</VirtualHost>
END_PASTE
}

function setrtuser(){
echo "ENTER A USERNAME"
read USERNAME
echo "ENTER PASSWORD FOR $USERNAME"
sudo htpasswd -c $RUDIR/rutorrent/.htpasswd $USERNAME
sudo chown www-data:www-data $RUDIR/rutorrent/.htpasswd
}

function installscreen(){
if ! which screen  > /dev/null; then
   echo -e "Screen not found! Install? (y/n) \c"
   read
   if "$REPLY" = "y"; then
   echo "INSTALLING SCREEN"
   sudo apt-get install screen -y
   fi
fi
sleep 2
}

function restartapache(){
echo "RESTARTING APACHE"
sudo /etc/init.d/apache2 restart
sleep 2
}

function startscript(){
echo "GENERATING STARTUP SCRIPT"
cd /etc/init.d/
wget -q $STARTRT
mv rtstart.sh startrt
chmod +x /etc/init.d/startrt
update-rc.d startrt defaults
}

function startrtorrent(){
echo "STARTING RTORRENT"
sleep 5
service startrt start
}

function echort(){
echo "SCRiPT BY DEViL69"
echo ""
}

function showip(){
echo "Your IP Address is:"
ifconfig | grep -m 1 inet\ addr: | cut -d: -f2 | awk '{print $1}' 
echo "YOU MAY NOW ACCESS YOUR RUTORRENT INTERFACE AT yourip/rutorrent"
echo ""
echo "TO START AND STOP YOUR RTORRENT USE:"
echo "service startrt start|stop|restart"
}
#####################################################
# Now here we go

checkifroot
echo "Welcome to  DEViL69 rTorrent install script!"
echort
sleep 2

setdldir
mkdirs
checkrtconfig
configpaste
update
depend
xmlrpc
libtorrent
rtorrent
installrutorrent
installscreen
setauthfile
setrtuser
startscript

restartapache
startrtorrent

showip
echort
