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

# ---------------------------- Recovery 初始化脚本 ----------------------------
# ★★★ 关键修复（2026-10-01，第二次踩坑）：
#
#   AOSP recovery 的 init.rc 第一行是：
#       import /init.recovery.${ro.hardware}.rc
#   本机 ro.hardware=qcom，所以 init 会去找 /init.recovery.qcom.rc。
#   该文件 *不在 AOSP 通用源码里*，必须由设备树提供。
#
#   缺了它会连锁三件事全废：
#     ① 背光不写 panel0-backlight/brightness  → 黑屏
#     ② /config/usb_gadget/g1 (configfs) 不建 → USB 不枚举
#     ③ UDC 不绑定 → gadget 起不来 → init 空转 → watchdog 重启
#
#   ⚠️ 第一次修复只把文件放进设备树目录，但 *没有构建规则*，
#      所以根本没进 ramdisk —— 刷完依旧黑屏。
#
#   正确机制（实测 build/core/Makefile 的 build-recoveryramdisk 宏）：
#       cp $(TARGET_ROOT_OUT)/init.recovery.*.rc $(TARGET_RECOVERY_ROOT_OUT)/
#   build 只从 **root 分区目录** 捞 init.recovery.*.rc 进 recovery ramdisk，
#   所以这里必须把目标写成根目录下的 init.recovery.qcom.rc，
#   它会先被装进 out/target/product/MS600/root/，再自动进 recovery ramdisk。
#   （Android 8.1 与 11 的机制完全一致。）
#
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.recovery.qcom.rc:$(TARGET_COPY_OUT_ROOT)/init.recovery.qcom.rc

# ---------------------------- 构建容错 --------------------------------------
ALLOW_MISSING_DEPENDENCIES := true
