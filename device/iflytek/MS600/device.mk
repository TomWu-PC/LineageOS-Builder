#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# MS600 设备配置 —— LineageOS 15.1（Android 8.1）
#
# 目标：与设备原厂 vendor（Android 8.1）版本对齐，
#       先用最小自包含配置把 ROM 跑起来，后续再逐步补 HAL。
#

LOCAL_PATH := device/iflytek/MS600

# ---------------------------- 屏幕 ------------------------------------------
# 本机实测：物理分辨率 1200x1920（竖屏面板）+ density 224
PRODUCT_AAPT_CONFIG      := normal
PRODUCT_AAPT_PREF_CONFIG := hdpi

# ---------------------------- 内核 ------------------------------------------
# 内核由 BoardConfig.mk 的 TARGET_PREBUILT_KERNEL 交给 build 系统打包进 boot.img，
# 不要再用 PRODUCT_COPY_FILES 往 /system 根目录塞一份（27.5MB 冗余）。

# ---------------------------- 属性 ------------------------------------------
# ⚠️ Android 8.1 的 ro.secure / ro.adb.secure 是【只读属性】，
#    从产品配置文件覆盖不生效（会被 build 系统的默认值覆盖）。
#    真正生效的方式是改 system/core 或使用 userdebug 变体（默认 adb root 可用）。
#    此处保留是为了记录意图，实际行为以 lunch 变体为准。
PRODUCT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.timezone=Asia/Shanghai \
    ro.sf.lcd_density=224 \
    ro.telephony.default_network=9

# 默认语言：简体中文
PRODUCT_LOCALES        := zh_CN,en_US
PRODUCT_DEFAULT_LANGUAGE := zh_CN

# ---------------------------- 外置存储 --------------------------------------
PRODUCT_PACKAGES += \
    e2fsck \
    fsck.f2fs

# ---------------------------- 构建容错 --------------------------------------
ALLOW_MISSING_DEPENDENCIES := true
