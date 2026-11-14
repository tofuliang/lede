#!bin/sh

docker rmi `docker images -q`
sudo rm -rf \
/usr/share/dotnet \
/etc/mysql \
/etc/php
sudo -E apt-get -y purge \
azure-cli \
ghc* \
zulu* \
hhvm \
llvm* \
firefox \
google* \
dotnet* \
powershell \
openjdk* \
mysql* \
php*
sudo -E apt-get update
sudo -E apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync uuid-runtime vim perl tar man sudo adduser netstat-nat net-tools w3m htop screen
sudo -E apt-get -y autoremove --purge
sudo -E apt-get clean
