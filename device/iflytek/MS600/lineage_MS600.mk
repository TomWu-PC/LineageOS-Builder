#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# 继承基础产品配置
#   core_64_bit        → 64 位主 ABI（SDM450 是 arm64）
#   full_base_telephony→ 带 telephony 栈（设备有 modem 分区 / RIL）
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# 继承 LineageOS 通用配置
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# 继承设备配置
$(call inherit-product, device/iflytek/MS600/device.mk)

# 设备标识（务必与 BoardsConfig / 编译产物目录一致）
PRODUCT_DEVICE       := MS600
PRODUCT_NAME         := lineage_MS600
PRODUCT_BRAND        := iFlytek
PRODUCT_MODEL        := MS600
PRODUCT_MANUFACTURER := iFlytek
PRODUCT_BOARD        := MS600

# 覆盖 build.prop 中的部分字段，保持与设备真实身份一致
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=MS600 \
    TARGET_DEVICE=MS600 \
    BUILD_FINGERPRINT=iFlytek/MS600/MS600:8.1.0/OPM1.171019.026/eng.build.20200706.144608:user/release-keys \
    PRIVATE_BUILD_DESC="msm8953_64-user 8.1.0 OPM1.171019.026 eng.build.20200706.144608 release-keys"
