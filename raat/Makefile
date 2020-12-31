include $(TOPDIR)/rules.mk

PKG_NAME:=raat
PKG_VERSION:=20201213
PKG_RELEASE:=1
PKG_REV:=8b2b0b9b2d292d7ab48d5c0c41ee4ea3747ec7e6

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/nickbash11/raat.git
PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)
PKG_SOURCE_VERSION:=$(PKG_REV)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)

include $(INCLUDE_DIR)/package.mk

define Package/raat
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=The daemon for announce static routes through ALFRED
  DEPENDS:=+alfred +batctl-default +batctl +kmod-batman-adv
endef

define Package/raat/description
	The daemon for announce static routes through ALFRED
endef

MAKE_FLAGS += \
	CFLAGS="$(TARGET_CFLAGS)" \
	STRIP="/bin/true"

define Build/Compile 
	$(MAKE) -C $(PKG_BUILD_DIR)/src $(MAKE_FLAGS)
endef

define Package/raat/install
	$(INSTALL_DIR) $(1)/usr/sbin $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/raat $(1)/usr/sbin/raat
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/openwrt-configs/etc/init.d/raat $(1)/etc/init.d/raat
endef

$(eval $(call BuildPackage,raat))

