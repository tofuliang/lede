# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2013 OpenWrt.org

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

define Image/Prepare
	rm -f $(KDIR)/fs_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/fs_mark
	$(call prepare_generic_squashfs,$(KDIR)/fs_mark)

	# For UBI we want only one extra block
	rm -f $(KDIR)/ubi_mark
	echo -ne '\xde\xad\xc0\xde' > $(KDIR)/ubi_mark
endef

define Build/lzma-d16
	$(STAGING_DIR_HOST)/bin/lzma e $@ -d16 $(1) $@.new
	mv $@.new $@
endef

# Similar to Build/tplink-safeloader but uses TRX instead of clean kernel
define Build/bcm53xx-tplink-safeloader
	$(STAGING_DIR_HOST)/bin/trx \
		-o $@.trx \
		-m 33554432 \
		-f $(IMAGE_KERNEL) -a 1024
	$(STAGING_DIR_HOST)/bin/tplink-safeloader \
		-B $(TPLINK_BOARD) \
		-k $@.trx \
		-r $@ \
		-j \
		-o $@.new
	mv $@.new $@
	rm $@.trx
endef

define Build/buffalo-wzr-header
	$(eval product=$(word 1,$(1)))
	$(eval region=$(word 2,$(1)))
	( \
		echo $(product)_$(BUFFALO_TAG_VERSION)_$(BUFFALO_TAG_MINOR)_$(region)_$(BUFFALO_TAG_PLATFORM); \
		echo filelen=$$(stat -c%s $@); \
		cat $@ \
	) > $@.new
	mv $@.new $@
endef

# TRX with only one (kernel) partition
define Build/trx
	$(STAGING_DIR_HOST)/bin/trx \
		-o $@.new \
		-m 33554432 \
		-f $@
	mv $@.new $@
endef

define Build/trx-serial
	$(STAGING_DIR_HOST)/bin/otrx create $@.new \
		-f $(IMAGE_KERNEL) -a 1024 \
		-f $@ -a 0x10000 -A $(KDIR)/fs_mark
	mv $@.new $@
endef

define Build/trx-nand
	# kernel: always use 4 MiB (-28 B or TRX header) to allow upgrades even
	#	  if it grows up between releases
	# root: UBI with one extra block containing UBI mark to trigger erasing
	#	rest of partition
	$(STAGING_DIR_HOST)/bin/otrx create $@.new \
		-f $(IMAGE_KERNEL) -a 0x20000 -b 0x400000 \
		-f $@ \
		-A $(KDIR)/ubi_mark -a 0x20000
	mv $@.new $@
endef

define Build/asus-trx
	$(STAGING_DIR_HOST)/bin/asustrx \
		-p $(ASUS_PRODUCTID) -i $@ -o $@.new
	mv $@.new $@
endef

define Build/luxul-lxl
	$(STAGING_DIR_HOST)/bin/lxlfw create $@.new \
		-i $@ \
		-b $(LUXUL_BOARD)
	mv $@.new $@
endef

# Outputs a lzma compressed U-Boot that start at 0x00008000
# just like the D-Link boot loaders expect
define Build/dlink-uboot-bin
	$(STAGING_DIR_HOST)/bin/lzma e $(STAGING_DIR_IMAGE)/$(DEVICE_NAME)-u-boot.bin -d16 $@
endef

define Build/seama-nand
	# Seama entity
	$(STAGING_DIR_HOST)/bin/oseama \
		entity $@.entity \
		-m "dev=/dev/mtdblock/7" \
		-m "type=firmware" \
		-f $(IMAGE_KERNEL) \
		-b 0x400000 \
		-f $@ \
		-f $(KDIR)/ubi_mark
	# Seama container
	$(STAGING_DIR_HOST)/bin/seama \
		-s $@ \
		-m "signature=$(SIGNATURE)" \
		-i $@.entity
endef

define Build/dwl8610ap-image
	mkdir -p $@.tmptar
	# The DWL8610AP pretends to be a Broadcom reference design
	echo "bcm953012er" > $@.tmptar/board
	echo "LVL7" > $@.tmptar/model
	# Something high beyond what D-Link has put out
	echo "5.0.0.0" > $@.tmptar/version
	# Create rootfs.bin, this is just a NAND image including everything
	cp $@ $@.tmptar/rootfs.bin
	# Hash the rootfs.bin
	cat $@.tmptar/rootfs.bin | md5sum > $@.tmptar/rootfs.md5
	cd $@.tmptar && tar -c -f $@.new *
	rm -rf $@.tmptar
	mv $@.new $@
endef

DTS_DIR := $(DTS_DIR)/broadcom

DEVICE_VARS += ASUS_PRODUCTID
DEVICE_VARS += BUFFALO_TAG_PLATFORM BUFFALO_TAG_VERSION BUFFALO_TAG_MINOR
DEVICE_VARS += SIGNATURE
DEVICE_VARS += NETGEAR_BOARD_ID NETGEAR_REGION TPLINK_BOARD
DEVICE_VARS += LUXUL_BOARD

IEEE8021X := wpad-openssl
B43 := $(IEEE8021X) kmod-b43
BRCMFMAC_43602A1 := $(IEEE8021X) kmod-brcmfmac brcmfmac-firmware-43602a1-pcie
BRCMFMAC_4366B1 := $(IEEE8021X) kmod-brcmfmac brcmfmac-firmware-4366b1-pcie
BRCMFMAC_4366C0 := $(IEEE8021X) kmod-brcmfmac brcmfmac-firmware-4366c0-pcie
USB2_PACKAGES := kmod-usb-ohci kmod-usb2 kmod-phy-bcm-ns-usb2
USB2_PACKAGES += kmod-usb-ledtrig-usbport
USB3_PACKAGES := $(USB2_PACKAGES) kmod-usb3 kmod-phy-bcm-ns-usb3

define Device/Default
  PROFILES = Generic $$(DEVICE_NAME)
  # .dtb files are prefixed by SoC type, e.g. bcm4708- which is not included in device/image names
  # extract the full dtb name based on the device info
  DEVICE_DTS := $(patsubst %.dtb,%,$(notdir $(wildcard $(if $(IB),$(KDIR),$(DTS_DIR))/*-$(subst _,-,$(1)).dtb)))
  KERNEL := kernel-bin | append-dtb | lzma-d16
  KERNEL_DEPENDS = $$(wildcard $(DTS_DIR)/$$(DEVICE_DTS).dts)
  KERNEL_INITRAMFS_SUFFIX := .trx
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma-d16 | trx
  FILESYSTEMS := squashfs
  KERNEL_NAME := zImage
  DEVICE_IMG_NAME = $$(DEVICE_IMG_PREFIX)-$$(1).$$(2)
  IMAGES := trx
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE/trx := append-ubi | trx-nand
endef

define Device/asus
  DEVICE_VENDOR := ASUS
  IMAGES := trx
  IMAGE/trx := append-ubi | trx-nand | asus-trx
endef

define Device/asus_rt-ac3100
  $(call Device/asus)
  DEVICE_MODEL := RT-AC3100
  DEVICE_PACKAGES := $(BRCMFMAC_4366B1) $(BRCMFMAC_4366C0) $(USB3_PACKAGES)
  ASUS_PRODUCTID := RT-AC3100
endef
TARGET_DEVICES += asus_rt-ac3100

define Device/asus_rt-ac56u
  $(call Device/asus)
  DEVICE_MODEL := RT-AC56U
  DEVICE_PACKAGES := $(B43) $(USB3_PACKAGES)
  ASUS_PRODUCTID := RT-AC56U
endef
TARGET_DEVICES += asus_rt-ac56u

define Device/asus_rt-ac68u
  $(call Device/asus)
  DEVICE_MODEL := RT-AC68U
  DEVICE_PACKAGES := $(USB3_PACKAGES)
  ASUS_PRODUCTID := RT-AC68U
endef
TARGET_DEVICES += asus_rt-ac68u

define Device/asus_rt-ac87u
  $(call Device/asus)
  DEVICE_MODEL := RT-AC87U
  DEVICE_PACKAGES := $(USB3_PACKAGES)
  ASUS_PRODUCTID := RT-AC87U
endef
TARGET_DEVICES += asus_rt-ac87u

define Device/asus_rt-ac88u
  $(call Device/asus)
  DEVICE_MODEL := RT-AC88U
  DEVICE_PACKAGES := $(BRCMFMAC_4366B1) $(BRCMFMAC_4366C0) $(USB3_PACKAGES)
  ASUS_PRODUCTID := RT-AC88U
endef
TARGET_DEVICES += asus_rt-ac88u

define Device/asus_rt-n18u
  $(call Device/asus)
  DEVICE_MODEL := RT-N18U
  DEVICE_PACKAGES := $(USB3_PACKAGES)
  ASUS_PRODUCTID := RT-N18U
endef
TARGET_DEVICES += asus_rt-n18u

# Buffalo devices have TFTP recovery mode which can work nicely with initramfs
# kernels.
# We should have two initramfs images for Buffalo: plain initramfs kernel and
# TRX with initramfs kernel. It's not possible right now so let's just build
# plain initramfs kernel as it may be more useful.
define Device/buffalo/Default
  DEVICE_VENDOR := Buffalo
  KERNEL_INITRAMFS_SUFFIX = $$(KERNEL_SUFFIX)
  KERNEL_INITRAMFS = $$(KERNEL)
endef

define Device/buffalo_wxr-1900dhp
  $(call Device/buffalo/Default)
  DEVICE_MODEL := WXR-1900DHP
  DEVICE_PACKAGES := $(USB3_PACKAGES)
endef
TARGET_DEVICES += buffalo_wxr-1900dhp

define Device/buffalo_wzr-600dhp2
  $(call Device/buffalo/Default)
  DEVICE_MODEL := WZR-600DHP2
  DEVICE_PACKAGES := $(B43) $(USB2_PACKAGES)
endef
TARGET_DEVICES += buffalo_wzr-600dhp2

define Device/buffalo_wzr-900dhp
  $(call Device/buffalo/Default)
  DEVICE_MODEL := WZR-900DHP
  DEVICE_PACKAGES := $(B43) $(USB3_PACKAGES)
  BUFFALO_TAG_PLATFORM := bcm
  BUFFALO_TAG_VERSION := 9.99
  BUFFALO_TAG_MINOR := 9.99
  IMAGES += factory-DHP-EU.bin factory-DHP2-JP.bin
  IMAGE/factory-DHP-EU.bin := \
	append-ubi | trx-nand | buffalo-wzr-header WZR-900DHP EU | \
	buffalo-enc WZR-900DHP $$(BUFFALO_TAG_VERSION) | \
	buffalo-tag-dhp WZR-900DHP EU mlang20 | buffalo-enc-tag | \
	buffalo-dhp-image
  IMAGE/factory-DHP2-JP.bin := \
	append-ubi | trx-nand | buffalo-wzr-header WZR-900DHP2 JP | \
	buffalo-enc WZR-900DHP2 $$(BUFFALO_TAG_VERSION) | \
	buffalo-tag-dhp WZR-900DHP2 JP jp | buffalo-enc-tag | \
	buffalo-dhp-image
endef
TARGET_DEVICES += buffalo_wzr-900dhp

define Device/buffalo_wzr-1750dhp
  $(call Device/buffalo/Default)
  DEVICE_MODEL := WZR-1750DHP
  DEVICE_PACKAGES := $(B43) $(USB3_PACKAGES)
endef
TARGET_DEVICES += buffalo_wzr-1750dhp

define Device/dlink
  DEVICE_VENDOR := D-Link
  IMAGES := bin
  IMAGE/bin := append-ubi | seama-nand
endef

define Device/dlink_dir-885l
  DEVICE_MODEL := DIR-885L
  DEVICE_PACKAGES := $(BRCMFMAC_4366B1) $(USB3_PACKAGES)
  $(Device/dlink)
  SIGNATURE := wrgac42_dlink.2015_dir885l
endef
TARGET_DEVICES += dlink_dir-885l

define Device/dlink_dir-890l
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DIR-890L
  DEVICE_PACKAGES := $(BRCMFMAC_43602A1) $(USB2_PACKAGES) $(USB3_PACKAGES)
  # Layout: U-boot (128kb max) followed by kernel and appended DTB.
  # This is done because the boot loader will only read the first 2 MB
  # from the flash and decompress the LZMA it finds there after the
  # SEAMA header. Since the compressed kernel will not fit in 2 MB,
  # we put U-Boot there and let U-Boot read and execute the kernel.
  KERNEL := dlink-uboot-bin | pad-to 128k | append-kernel | append-dtb
  $(Device/dlink)
  SIGNATURE := wrgac36_dlink.2013gui_dir890
endef
TARGET_DEVICES += dlink_dir-890l

define Device/dlink_dwl-8610ap
  DEVICE_VENDOR := D-Link
  DEVICE_MODEL := DWL-8610AP
  DEVICE_PACKAGES := $(B43)
  IMAGES := factory.tar
  IMAGE/factory.tar := append-ubi | trx-nand | dwl8610ap-image
endef
TARGET_DEVICES += dlink_dwl-8610ap

define Device/linksys_ea6300-v1
  DEVICE_VENDOR := Linksys
  DEVICE_MODEL := EA6300
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := $(B43) $(USB3_PACKAGES)
endef
TARGET_DEVICES += linksys_ea6300-v1

define Device/linksys_ea6500-v2
  DEVICE_VENDOR := Linksys
  DEVICE_MODEL := EA6500
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := $(B43) $(USB3_PACKAGES)
endef
TARGET_DEVICES += linksys_ea6500-v2

define Device/linksys_ea9200
  DEVICE_VENDOR := Linksys
  DEVICE_MODEL := EA9200
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := $(BRCMFMAC_43602A1) $(USB3_PACKAGES)
endef
TARGET_DEVICES += linksys_ea9200

define Device/linksys_ea9500
  DEVICE_VENDOR := Linksys
  DEVICE_MODEL := EA9500
  DEVICE_PACKAGES := $(BRCMFMAC_4366C0) $(USB3_PACKAGES)
  DEVICE_DTS := bcm47094-linksys-panamera
endef
TARGET_DEVICES += linksys_ea9500

define Device/luxul
  DEVICE_VENDOR := Luxul
  IMAGES := lxl
  IMAGE/lxl := append-ubi | trx-nand | luxul-lxl
endef

define Device/luxul_abr-4500
  $(Device/luxul)
  DEVICE_MODEL := ABR-4500
  DEVICE_PACKAGES := $(USB3_PACKAGES)
  LUXUL_BOARD := ABR-4500
endef
TARGET_DEVICES += luxul_abr-4500

define Device/luxul_xap-1610
  $(Device/luxul)
  DEVICE_MODEL := XAP-1610
  DEVICE_PACKAGES := $(BRCMFMAC_4366C0)
  IMAGE/lxl := append-rootfs | trx-serial | luxul-lxl
  LUXUL_BOARD := XAP-1610
endef
TARGET_DEVICES += luxul_xap-1610

define Device/luxul_xbr-4500
  $(Device/luxul)
  DEVICE_MODEL := XBR-4500
  DEVICE_PACKAGES := $(USB3_PACKAGES)
  LUXUL_BOARD := XBR-4500
endef
TARGET_DEVICES += luxul_xbr-4500

define Device/luxul_xwr-3150
  $(Device/luxul)
  DEVICE_MODEL := XWR-3150
  DEVICE_PACKAGES := $(BRCMFMAC_4366C0) $(USB3_PACKAGES)
  DEVICE_DTS := bcm47094-luxul-xwr-3150-v1
  LUXUL_BOARD := XWR-3150
endef
TARGET_DEVICES += luxul_xwr-3150

define Device/meraki_mr26
  DEVICE_VENDOR := Meraki
  DEVICE_MODEL := MR26
  DEVICE_PACKAGES := $(B43) kmod-hwmon-ina2xx kmod-leds-uleds nu801
  DEVICE_DTS := bcm53015-meraki-mr26
# resize the initramfs to fit the size of the existing part.safe.
  KERNEL_LOADADDR := 0x00008000
  KERNEL_INITRAMFS_SUFFIX := .bin
  KERNEL_INITRAMFS := kernel-bin | append-dtb | gzip | uImage gzip | pad-to 9310208
# LZMA is not supported by the uboot
  KERNEL := kernel-bin | append-dtb | gzip | uImage gzip
  IMAGES += sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += meraki_mr26

define Device/meraki_mr32
  DEVICE_VENDOR := Meraki
  DEVICE_MODEL := MR32
  DEVICE_PACKAGES := $(B43) kmod-leds-pwm kmod-hwmon-ina2xx kmod-hci-uart
  DEVICE_DTS := bcm53016-meraki-mr32
# Meraki FW r23 tries to resize the part.safe partition before it will
# flash the image. This is a bit of a problem, since resizing will fail
# if the partition is smaller than the old one.
  KERNEL_LOADADDR := 0x00008000
  KERNEL_INITRAMFS_SUFFIX := .bin
  DEVICE_DTS_DELIMITER := @
  DEVICE_DTS_CONFIG := config@1
  KERNEL_INITRAMFS := kernel-bin | fit none $$(DTS_DIR)/$$(DEVICE_DTS).dtb | \
	pad-to 10362880
  KERNEL := kernel-bin | fit none $$(DTS_DIR)/$$(DEVICE_DTS).dtb
  IMAGES += sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata

# The loader is specifically looking for fdt@2:
# [    3.190000] find_itb_subimage: error finding fdt@2: FDT_ERR_NOTFOUND
# The image won't boot, if it isn't found. :(
  DEVICE_FDT_NUM := 2
endef
TARGET_DEVICES += meraki_mr32

define Device/meraki_mx6x
  KERNEL_IN_UBI := 1
  KERNEL_LOADADDR := 0x60008000
  DEVICE_PACKAGES := -oseama kmod-leds-pwm kmod-usb-ehci \
	kmod-usb-ohci kmod-usb2
  DEVICE_VENDOR := Cisco Meraki
  KERNEL = kernel-bin | gzip | fit gzip $$(DTS_DIR)/$$(DEVICE_DTS).dtb
  KERNEL_INITRAMFS := kernel-bin | gzip | fit gzip $$(DTS_DIR)/$$(DEVICE_DTS).dtb
  KERNEL_INITRAMFS_SUFFIX := .bin
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define Device/meraki_mx64
  $(call Device/meraki_mx6x)
  DEVICE_MODEL := MX64
  DEVICE_DTS_CONFIG := config@4
  DEVICE_DTS := bcm958625-meraki-mx64
endef
TARGET_DEVICES += meraki_mx64

define Device/meraki_mx64_a0
  $(call Device/meraki_mx64)
  DEVICE_VARIANT := A0
  DEVICE_DTS_CONFIG := config@2
  DEVICE_DTS := bcm958625-meraki-mx64-a0
endef
TARGET_DEVICES += meraki_mx64_a0

define Device/meraki_mx65
  $(call Device/meraki_mx6x)
  DEVICE_MODEL := MX65
  DEVICE_DTS_CONFIG := config@3
  DEVICE_DTS := bcm958625-meraki-mx65
endef
TARGET_DEVICES += meraki_mx65

define Device/netgear
  DEVICE_VENDOR := NETGEAR
  IMAGES := chk
  IMAGE/chk := append-ubi | trx-nand | netgear-chk
  NETGEAR_REGION := 1
endef

define Device/netgear_r6250
  DEVICE_MODEL := R6250
  DEVICE_PACKAGES := $(B43) $(USB3_PACKAGES)
  $(Device/netgear)
  NETGEAR_BOARD_ID := U12H245T00_NETGEAR
endef
TARGET_DEVICES += netgear_r6250

define Device/netgear_r6300-v2
  DEVICE_MODEL := R6300
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := $(B43) $(USB3_PACKAGES)
  $(Device/netgear)
  NETGEAR_BOARD_ID := U12H240T00_NETGEAR
endef
TARGET_DEVICES += netgear_r6300-v2

define Device/netgear_r7000
  DEVICE_MODEL := R7000
  DEVICE_PACKAGES := $(USB3_PACKAGES)
  $(Device/netgear)
  NETGEAR_BOARD_ID := U12H270T00_NETGEAR
endef
TARGET_DEVICES += netgear_r7000

define Device/netgear_r7900
  DEVICE_MODEL := R7900
  DEVICE_PACKAGES := $(BRCMFMAC_43602A1) $(USB3_PACKAGES)
  $(Device/netgear)
  NETGEAR_BOARD_ID := U12H315T30_NETGEAR
endef
TARGET_DEVICES += netgear_r7900

define Device/netgear_r8000
  DEVICE_MODEL := R8000
  DEVICE_PACKAGES := $(BRCMFMAC_43602A1) $(USB3_PACKAGES)
  $(Device/netgear)
  NETGEAR_BOARD_ID := U12H315T00_NETGEAR
endef
TARGET_DEVICES += netgear_r8000

define Device/netgear_r8500
  DEVICE_MODEL := R8500
  DEVICE_PACKAGES := $(BRCMFMAC_4366B1) $(USB3_PACKAGES)
  $(Device/netgear)
  NETGEAR_BOARD_ID := U12H334T00_NETGEAR
  DEFAULT := n
endef
TARGET_DEVICES += netgear_r8500

define Device/smartrg_sr400ac
  DEVICE_VENDOR := SmartRG
  DEVICE_MODEL := SR400ac
  DEVICE_PACKAGES := $(BRCMFMAC_43602A1) $(USB3_PACKAGES)
  IMAGES := trx
  IMAGE/trx := append-rootfs | trx-serial
  KERNEL_INITRAMFS_SUFFIX := .bin
  KERNEL_INITRAMFS := kernel-bin | append-dtb | lzma-d16
endef
TARGET_DEVICES += smartrg_sr400ac

define Device/phicomm_k3
  DEVICE_VENDOR := PHICOMM
  DEVICE_MODEL := K3
  DEVICE_PACKAGES := $(BRCMFMAC_4366C0) $(USB3_PACKAGES)
  IMAGES := trx
endef
TARGET_DEVICES += phicomm_k3

define Device/tenda_ac9
  DEVICE_VENDOR := Tenda
  DEVICE_MODEL := AC9
  DEVICE_PACKAGES := $(B43) $(USB2_PACKAGES)
  IMAGES := trx
  IMAGE/trx := append-rootfs | trx-serial
endef
TARGET_DEVICES += tenda_ac9

define Device/tplink_archer-c5-v2
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := Archer C5
  DEVICE_VARIANT := v2
  DEVICE_PACKAGES := $(B43) $(USB2_PACKAGES)
  IMAGES := bin
  IMAGE/bin := append-rootfs | bcm53xx-tplink-safeloader
  TPLINK_BOARD := ARCHER-C5-V2
  BROKEN := y
endef
#TARGET_DEVICES += tplink_archer-c5-v2

define Device/tplink_archer-c9-v1
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := Archer C9
  DEVICE_VARIANT := v1
  DEVICE_PACKAGES := $(USB3_PACKAGES)
  IMAGES := bin
  IMAGE/bin := append-rootfs | bcm53xx-tplink-safeloader
  TPLINK_BOARD := ARCHERC9
  BROKEN := y
endef
#TARGET_DEVICES += tplink_archer-c9-v1

$(eval $(call BuildImage))
