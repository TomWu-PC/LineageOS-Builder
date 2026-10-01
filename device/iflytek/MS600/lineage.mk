#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# ★★ 本文件是 LineageOS 15.1 的标准产品入口（2026-10-01 实测修正）★★
#
# 【为什么需要这个文件】
#   LineageOS 15.1 的 android_build/core/product_config.mk 第 172-174 行：
#     ifneq ($(LINEAGE_BUILD),)
#       all_product_configs := $(shell find device -path "*/$(LINEAGE_BUILD)/lineage.mk")
#       all_product_configs += $(wildcard vendor/lineage/build/target/product/lineage_$(LINEAGE_BUILD).mk)
#   → 当 LINEAGE_BUILD 有值时，构建系统【只认 device/<vendor>/<device>/lineage.mk】，
#     完全不读 AndroidProducts.mk！
#
#   ★ 上轮 run #12 编译失败的真因：
#     只提供了 lineage_MS600.mk + AndroidProducts.mk，
#     lunch 找不到对应入口 → "Can not locate config makefile for product lineage_MS600"
#
# 【为什么不用 inherit-product】
#   lineage.mk 文件名没有产品名前缀，构建系统会把它当成产品名 "lineage"，
#   与链进来的 PRODUCT_NAME := lineage_MS600 冲突，导致 lunch 目标名混乱。
#   所以这里【完整包含】所有定义，与 lineage_MS600.mk 内容保持一致。
#
# 【同时兼容两种机制】
#   lineage.mk           → LINEAGE_BUILD 有值时的官方入口（★ 必需）
#   AndroidProducts.mk   → LINEAGE_BUILD 为空时的 AOSP 后备机制
#

# ---- 继承基础产品配置 ----
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

# ---- 继承 LineageOS 通用配置 ----
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

# ---- 继承设备配置 ----
$(call inherit-product, device/iflytek/MS600/device.mk)

# ---- 设备标识 ----
PRODUCT_DEVICE       := MS600
PRODUCT_NAME         := lineage_MS600
PRODUCT_BRAND        := iFlytek
PRODUCT_MODEL        := MS600
PRODUCT_MANUFACTURER := iFlytek
PRODUCT_BOARD        := MS600

# ---- build.prop 覆盖（保持与设备真实身份一致）----
PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=MS600 \
    TARGET_DEVICE=MS600 \
    BUILD_FINGERPRINT=iFlytek/MS600/MS600:8.1.0/OPM1.171019.026/eng.build.20200706.144608:user/release-keys \
    PRIVATE_BUILD_DESC="msm8953_64-user 8.1.0 OPM1.171019.026 eng.build.20200706.144608 release-keys"
