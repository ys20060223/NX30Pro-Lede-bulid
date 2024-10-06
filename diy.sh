#!/bin/bash
# 定义一个名为svn_export的函数，用于从SVN仓库中导出特定分支的代码
svn_export() {
    # 参数1是分支名, 参数2是子目录, 参数3是目标目录, 参数4是仓库地址
    local TMP_DIR="$(mktemp -d)" || exit 1  # 创建临时目录，失败则退出
    local ORI_DIR="$PWD"  # 保存当前工作目录
    [ -d "$3" ] || mkdir -p "$3"  # 如果目标目录不存在，则创建
    local TGT_DIR="$(cd "$3"; pwd)"  # 获取目标目录的绝对路径
    # 克隆指定分支的代码到临时目录，然后进入子目录，删除.git目录，复制文件到目标目录
    git clone --depth 1 -b "$1" "$4" "$TMP_DIR" >/dev/null 2>&1 && \
    cd "$TMP_DIR/$2" && rm -rf .git >/dev/null 2>&1 && \
    cp -af . "$TGT_DIR/" && cd "$ORI_DIR"  # 复制完成后返回原始目录
    rm -rf "$TMP_DIR"  # 删除临时目录
}

# 删除冲突软件和依赖
# 下面两行被注释掉了，如果需要可以取消注释
#rm -rf feeds/packages/lang/golang 
rm -rf feeds/luci/applications/luci-app-pushbot feeds/luci/applications/luci-app-serverchan
# 下面两行被注释掉了，如果需要可以取消注释
#git clone https://github.com/sbwml/packages_lang_golang  feeds/packages/lang/golang

# 下载插件
git clone https://github.com/zzsj0928/luci-app-pushbot  package/luci-app-pushbot  # 克隆luci-app-pushbot插件
git clone --depth 1 https://github.com/fw876/helloworld  package/helloworld  # 克隆helloworld插件
git clone https://github.com/sbwml/luci-app-alist  package/luci-app-alist  # 克隆luci-app-alist插件
git clone https://github.com/xiaorouji/openwrt-passwall-packages  package/openwrt-passwall-packages  # 克隆openwrt-passwall-packages插件
# 下面一行被注释掉了，如果需要可以取消注释
#git clone --depth 1 https://github.com/chenmozhijin/luci-app-adguardhome  package/luci-app-adguardhome

# 使用svn_export函数导出luci-app-passwall插件
svn_export "main" "luci-app-passwall" "package/luci-app-passwall" "https://github.com/xiaorouji/openwrt-passwall"

# 编译po2lmo（如果有po2lmo可跳过）
# 下面四行被注释掉了，如果需要可以取消注释
#pushd package/luci-app-openclash/tools/po2lmo
#make && sudo make install
#popd

# 微信推送
sed -i "s|qidian|bilibili|g" feeds/luci/applications/luci-app-serverchan/root/usr/share/serverchan/serverchan  # 替换微信推送中的关键词

# 替换argon主题
rm -rf feeds/luci/themes/luci-theme-argon  # 删除旧的argon主题
git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git  ./feeds/luci/themes/luci-theme-argon  # 克隆新的argon主题

# 删除v2ray-geodata相关的Makefile
find ./ | grep Makefile | grep v2ray-geodata | xargs rm -f

# 个性化设置
cd package
sed -i "s/OpenWrt /Wing build $(TZ=UTC-8 date "+%Y.%m.%d") @ OpenWrt /g" lean/default-settings/files/zzz-default-settings  # 修改默认设置
sed -i "/firewall\.user/d" lean/default-settings/files/zzz-default-settings  # 删除firewall.user设置

# 更新passwall规则
curl -sfL -o ./luci-app-passwall/root/usr/share/passwall/rules/gfwlist https://raw.githubusercontent.com/Loyalsoldier/v2ray-rules-dat/release/gfw.txt  # 下载并更新gfwlist规则

# AdguardHome
# 下面几行被注释掉了，如果需要可以取消注释
#cd ./package/luci-app-adguardhome/root/usr
#mkdir -p ./bin/AdGuardHome && cd ./bin/AdGuardHome
# 下面几行被注释掉了，如果需要可以取消注释
#ADG_VER=$(curl -sfL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases  2>/dev/null | grep 'tag_name' | egrep -o "v[0-9].+[0-9.]" | awk 'NR==1')
#curl -sfL -o /tmp/AdGuardHome_linux.tar.gz https://github.com/AdguardTeam/AdGuardHome/releases/download/${ADG_VER}/AdGuardHome_linux_arm64.tar.gz 
#tar -zxf /tmp/*.tar.gz -C /tmp/ && chmod +x /tmp/AdGuardHome/AdGuardHome
# 下面几行被注释掉了，如果需要可以取消注释
#upx_latest_ver="$(curl -sfL https://api.github.com/repos/upx/upx/releases/latest  2>/dev/null | egrep 'tag_name' | egrep '[0-9.]+' -o 2>/dev/null)"
#curl -sfL -o /tmp/upx-${upx_latest_ver}-amd64_linux.tar.xz "https://github.com/upx/upx/releases/download/v${upx_latest_ver}/upx-${upx_latest_ver}-amd64_linux.tar.xz" 
#xz -d -c /tmp/upx-${upx_latest_ver}-amd64_linux.tar.xz | tar -x -C "/tmp"
#/tmp/upx-${upx_latest_ver}-amd64_linux/upx --ultra-brute /tmp/AdGuardHome/AdGuardHome > /dev/null 2>&1
#mv /tmp/AdGuardHome/AdGuardHome ./ && rm -rf /tmp/AdGuardHome

# 修改wrtbwmon插件的设置
cd $GITHUB_WORKSPACE/openwrt && cd feeds/luci/applications/luci-app-wrtbwmon
sed -i 's/ selected=\"selected\"//g' ./luasrc/view/wrtbwmon/wrtbwmon.htm  # 移除selected属性
sed -i 's/\"1\"/\"1\" selected=\"selected\"/g' ./luasrc/view/wrtbwmon/wrtbwmon.htm  # 添加selected属性
sed -i 's/interval: 5/interval: 1/g' ./htdocs/luci-static/wrtbwmon/wrtbwmon.js  # 修改刷新间隔
