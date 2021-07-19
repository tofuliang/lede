export ReleaseVersion="$(git rev-parse --short HEAD^)-$(date +%Y.%m.%d)"

sed -i "/helloworld/d" "feeds.conf.default"
echo "src-git helloworld https://github.com/fw876/helloworld.git" >> "feeds.conf.default"
./scripts/feeds update -a -f
./scripts/feeds install -a -f -p helloworld

rm -fr luci-compat-app-smartdns
svn co https://github.com/pymumu/smartdns/trunk/package/luci-compat luci-compat-app-smartdns
cd luci-compat-app-smartdns
mkdir {luasrc,po,root}
mv files/etc root/etc
mv files/luci/i18n po/zh-cn
rm -fr files/luci/i18n
mv files/luci/*  luasrc/
rm -fr ../package/lean/luci-app-smartdns
mkdir ../package/lean/luci-app-smartdns

cat >> Makefile <<EOF
# This is free software, licensed under the Apache License, Version 2.0 .

include \$(TOPDIR)/rules.mk

LUCI_TITLE:=Luci for smartdns server
LUCI_DEPENDS:=+smartdns
LUCI_PKGARCH:=all
PKG_NAME:=luci-app-smartdns
PKG_VERSION:=1
PKG_RELEASE:=1

include \$(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature

EOF
mv {luasrc,po,root,Makefile} ../package/lean/luci-app-smartdns
cd .. && rm -fr luci-compat-app-smartdns
cd package/lean
rm -fr smartdns
svn co https://github.com/pymumu/smartdns/trunk/package/openwrt smartdns
sed -i "s/1.2019.28/2021.35/g" smartdns/Makefile
sed -i 's/982002e836e486fb4e360bc10e84e7e7197caf46/f50e4dd0813da9300580f7188e44ed72a27ae79c/g' smartdns/Makefile
sed -i 's/PKG_MIRROR_HASH:=ae889b521ecf114660ce5597af5c361f5970a7dcb75dadf61b938ba3d2baba54//g' smartdns/Makefile
sed -i 's/$(PKG_BUILD_DIR)\/package\/openwrt/./g' smartdns/Makefile

cat >> smartdns/custom.conf <<EOF

speed-check-mode ping,tcp:80

server 202.96.128.166 -group china
server 202.96.134.133 -group china
server 223.5.5.5 -group china
server 223.6.6.6 -group china
server 114.114.114.114 -group china
server 114.114.115.115 -group china
server 1.2.4.8 -group china
server 210.2.4.8 -group china
server 112.124.47.27 -group china
server 114.215.126.16 -group china
server 180.76.76.76 -group china
server 119.29.29.29 -group china

#请参照下列格式配置防污染DNS服务器
#server-tls 8.8.4.4 -group gfwlist -exclude-default-group
#server-tls 8.8.8.8 -group gfwlist -exclude-default-group
#server-tls 1.1.1.1 -group gfwlist -exclude-default-group
#server-tls 208.67.222.222 -group gfwlist -exclude-default-group
#server-tls 208.67.220.220 -group gfwlist -exclude-default-group
#server 127.0.0.1:7913 -group gfwlist -exclude-default-group

conf-file /tmp/smartdns/blacklist_forward.conf
conf-file /tmp/smartdns/gfwlist.conf
conf-file /tmp/smartdns/whitelist_forward.conf
conf-file /tmp/smartdns/forcelist_forward.conf

EOF

rm -fr luci-theme-argon
rm -fr luci-theme-atmaterial
rm -fr luci-app-serverchan
rm -fr luci-app-koolproxyR
rm -fr OpenAppFilter
rm -fr luci-app-vssr
# rm -fr luci-app-ssr-plus

svn co https://github.com/tty228/luci-app-serverchan/trunk luci-app-serverchan
svn co https://github.com/tofuliang/luci-app-koolproxyR/trunk luci-app-koolproxyR
svn co https://github.com/destan19/OpenAppFilter/trunk OpenAppFilter
svn co https://github.com/jerrykuku/luci-theme-argon/branches/18.06 luci-theme-argon
svn co https://github.com/tofuliang/luci-app-vssr/trunk luci-app-vssr
svn co https://github.com/jerrykuku/lua-maxminddb/trunk lua-maxminddb
svn co https://github.com/tofuliang/openwrt-package/trunk/others/luci-app-control-webrestriction
svn co https://github.com/tofuliang/openwrt-package/trunk/others/luci-app-control-weburl
svn co https://github.com/tofuliang/openwrt-package/trunk/others/luci-app-control-timewol
# svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus luci-app-ssr-plus
# svn co https://github.com/fw876/helloworld/trunk/tcping tcping
# svn co https://github.com/fw876/helloworld/trunk/naiveproxy naiveproxy
(cd luci-app-unblockmusic; \
sed -i 's/"kuwo:kugou"/"kuwo:kugou:qq" -lv -ba -bu -sef/' root/etc/init.d/unblockmusic \
)
cd ../..
./scripts/feeds install -a
./scripts/feeds install -f smartdns

# sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
sed -i "s/'luci_password'/'luci_username'/g" feeds/luci/modules/luci-base/luasrc/view/sysauth.htm
sed -i 's/IMG_PREFIX:=$(VERSION_DIST_SANITIZED)/IMG_PREFIX:=[$(shell date +%Y%m%d)]-$(VERSION_DIST_SANITIZED)/g' include/image.mk
sed -i '/entry({"admin", "services", "mia"}, cbi("mia"), _("Internet Access Schedule Control"),30).dependent = true/i\  entry({"admin", "control"}, firstchild(), "Control", 44).dependent = false' package/lean/luci-app-accesscontrol/luasrc/controller/mia.lua
sed -i 's/"services"/"control"/g' package/lean/luci-app-accesscontrol/luasrc/controller/mia.lua
