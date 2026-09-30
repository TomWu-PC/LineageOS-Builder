#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# 第一轮目标：先把设备树跑通（lunch + 编译 recovery/boot）。
# 因此这里刻意只保留最小自包含配置，不引用任何 vendor blob，
# 避免因缺少专有文件而在早期就中断构建。
# 后续迭代会逐步补齐 audio / display / camera / wifi 等 HAL。
#

LOCAL_PATH := device/iflytek/MS600

# ---------------------------- 屏幕 ------------------------------------------
# 本机实测：物理分辨率 1200x1920（竖屏面板）+ density 224
PRODUCT_AAPT_CONFIG      := normal
PRODUCT_AAPT_PREF_CONFIG := hdpi

# ---------------------------- 内核 ------------------------------------------
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/kernel:kernel

# ---------------------------- 属性 ------------------------------------------
PRODUCT_PROPERTY_OVERRIDES += \
    ro.adb.secure=0 \
    ro.secure=0

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.timezone=Asia/Shanghai \
    ro.sf.lcd_density=224 \
    ro.telephony.default_network=9

# 默认语言：简体中文
PRODUCT_LOCALES        := zh_CN,en_US
PRODUCT_DEFAULT_LANGUAGE := zh_CN

# ---------------------------- 外置存储 --------------------------------------
# 设备无内置 SD 卡槽/OTG 由内核支持，交给 vold 自动处理
PRODUCT_PACKAGES += \
    e2fsck \
    fsck.f2fs

# ---------------------------- 构建容错 --------------------------------------
# 第一轮允许缺失依赖，便于逐轮补齐设备树
ALLOW_MISSING_DEPENDENCIES := true

# ---------------------------- 继承 Soong 命名空间 ---------------------------
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)
