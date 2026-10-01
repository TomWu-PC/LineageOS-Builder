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
# 内核由 BoardConfig.mk 的 TARGET_PREBUILT_KERNEL 交给 build 系统打包进 boot.img，
# 不要再用 PRODUCT_COPY_FILES 往 /system 根目录塞一份（27.5MB 冗余，
# 且 Android 11 会警告 "copying to system root is deprecated"）。
# 2026-09-30 修正。

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
#   正确机制（实测 build/make/core/Makefile:2234）：
#       cp $(TARGET_ROOT_OUT)/init.recovery.*.rc $(TARGET_RECOVERY_ROOT_OUT)/
#   build 只从 **root 分区目录** 捞 init.recovery.*.rc 进 recovery ramdisk，
#   所以这里必须把目标写成根目录下的 init.recovery.qcom.rc，
#   它会先被装进 out/target/product/MS600/root/，再自动进 recovery ramdisk。
#
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/init.recovery.qcom.rc:$(TARGET_COPY_OUT_ROOT)/init.recovery.qcom.rc

# ---------------------------- 构建容错 --------------------------------------
# 第一轮允许缺失依赖，便于逐轮补齐设备树
ALLOW_MISSING_DEPENDENCIES := true

# ---------------------------- Soong 命名空间 --------------------------------
# ⚠️ 暂不声明 PRODUCT_SOONG_NAMESPACES：本设备树目前没有任何 Android.bp，
#    声明空的命名空间目录会让 Soong 在扫描阶段报错。
#    等第二轮补 prebuilt HAL（每个目录带 Android.bp）时再恢复，写法：
#      PRODUCT_SOONG_NAMESPACES += device/iflytek/MS600
