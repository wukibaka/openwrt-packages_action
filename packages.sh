#!/bin/bash
function merge_package() {
    # 参数1是分支名,参数2是库地址,参数3是所有文件下载到指定路径。
    # 同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开。
    if [[ $# -lt 3 ]]; then
        echo "Syntax error: [$#] [$*]" >&2
        return 1
    fi
    trap 'rm -rf "$tmpdir"' EXIT
    branch="$1" curl="$2" target_dir="$3" && shift 3
    rootdir="$PWD"
    localdir="$target_dir"
    [ -d "$localdir" ] || mkdir -p "$localdir"
    tmpdir="$(mktemp -d)" || exit 1
    git clone -b "$branch" --single-branch --depth 1 --filter=blob:none --sparse "$curl" "$tmpdir"
    cd "$tmpdir"
    git sparse-checkout init --cone
    git sparse-checkout set "$@"
    # 使用循环逐个移动文件夹
    for folder in "$@"; do
        mv -f "$folder" "$rootdir/$localdir"
    done
    cd "$rootdir"
}

# adguardhome
merge_package main https://github.com/kenzok8/wall packages adguardhome
git clone -b main --single-branch --depth 1 --filter=blob:none https://github.com/kenzok78/luci-app-adguardhome packages/luci-app-adguardhome

# argon
git clone -b master --single-branch --depth 1 --filter=blob:none https://github.com/jerrykuku/luci-app-argon-config packages/luci-app-argon-config
git clone -b master --single-branch --depth 1 --filter=blob:none https://github.com/jerrykuku/luci-theme-argon packages/luci-theme-argon

# mosdns
merge_package v5 https://github.com/sbwml/luci-app-mosdns packages luci-app-mosdns mosdns v2dat

# openclash
merge_package dev https://github.com/vernesong/OpenClash packages luci-app-openclash

# smartdns
merge_package master https://github.com/immortalwrt/packages packages net/smartdns
git clone -b master --single-branch --depth 1 --filter=blob:none https://github.com/pymumu/luci-app-smartdns packages/luci-app-smartdns

# ssrplus
merge_package master https://github.com/fw876/helloworld packages luci-app-ssr-plus shadow-tls
merge_package master https://github.com/immortalwrt/packages packages net/dns2socks net/dns2tcp devel/gn net/ipt2socks lang/lua-neturl net/microsocks net/simple-obfs net/tcping net/trojan net/tuic-client net/v2raya
merge_package v5 https://github.com/sbwml/openwrt_helloworld packages chinadns-ng hysteria naiveproxy redsocks2 shadowsocks-rust shadowsocksr-libev v2ray-core v2ray-plugin xray-core xray-plugin

# some modifications
sed -i -e 's?include \.\./\.\./\(lang\|devel\)?include $(TOPDIR)/feeds/packages/\1?' -e 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?' packages/*/Makefile

# adguardhome
rm -f ./packages/adguardhome/files/adguardhome.init
curl -o ./packages/adguardhome/files/adguardhome.init https://raw.githubusercontent.com/immortalwrt/packages/master/net/adguardhome/files/adguardhome.init

# clean up
find . -type d -name ".git" -exec rm -rf {} +
find . -type f -name ".gitattributes" -exec rm -f {} +
find . -type d -name ".github" -exec rm -rf {} +
find . -type f -name ".gitignore" -exec rm -f {} +
find . -type f -name "LICENSE" ! -path './LICENSE' -exec rm -f {} +
find . -type f \( -iname 'README.md' -o -iname 'README_ZH.md' -o -iname 'RELEASE.md' -o -iname 'RELEASE_ZH.md' \) ! -path './packages/luci-theme-argon/htdocs/luci-static/argon/background/README.md' ! -path './README.md' -exec rm -f {} +
find . -type d -name "Screenshots" -exec rm -rf {} +

exit 0
