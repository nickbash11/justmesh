include $(TOPDIR)/rules.mk

PKG_NAME:=justmesh
PKG_VERSION:=1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/justmesh

include $(INCLUDE_DIR)/package.mk

define Package/justmesh
  SECTION:=justmesh
  CATEGORY:=JustMesh
  DEPENDS:=+raat
  TITLE:=Scripts for quick deploy the mesh network
endef

define Package/justmesh/description
  Scripts for quick deploy the mesh network
endef

define Build/Compile
endef

define Package/justmesh/install
  $(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,justmesh))

