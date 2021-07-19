export bulil_profile=$1
rm -f ./.config*
[ -f ${bulil_profile}.config ] && cp ${bulil_profile}.config ./.config
sed -i 's/^[ \t]*//g' ./.config
echo -e 'CONFIG_DEVEL=y\nCONFIG_CCACHE=y' >> ./.config
make defconfig
make download -j8

(cd feeds/luci;git reset --hard;patch -p1 < ../../luci.patch)
patch -p1 < autocore.patch

sed -i "s/<%=pcdata(ver.distversion)%>/<%=pcdata(ver.distversion)%> [$ReleaseVersion]/g" package/lean/autocore/files/arm/index.htm
sed -i "s/<%=pcdata(ver.distversion)%>/<%=pcdata(ver.distversion)%> [$ReleaseVersion]/g" package/lean/autocore/files/x86/index.htm
(cd feeds/luci;sed -i "s/<%=pcdata(ver.distversion)%>/<%=pcdata(ver.distversion)%> [$ReleaseVersion]/g" modules/luci-mod-admin-full/luasrc/view/admin_status/index.htm)

[ -f ${bulil_profile}_files.txz ] && tar xJf ${bulil_profile}_files.txz
