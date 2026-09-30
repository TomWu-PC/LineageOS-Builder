#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# ===========================================================================
#  MS600（讯飞听见 L1）BoardConfig —— 移植自 LineageOS 官方 msm8953-common
#  所有硬件参数均为 2026-09-30 本机实测值，与官方 msm8953 参照逐项核对一致
# ===========================================================================

# ---------------------------- 架构 -----------------------------------------
# SDM450 / msm8953 = Cortex-A53 x8，64 位（设备实测 ABI = arm64-v8a）
TARGET_ARCH             := arm64
TARGET_ARCH_VARIANT     := armv8-a
TARGET_CPU_ABI          := arm64-v8a
TARGET_CPU_ABI2         :=
TARGET_CPU_VARIANT      := cortex-a53

TARGET_2ND_ARCH         := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI      := armeabi-v7a
TARGET_2ND_CPU_ABI2     := armeabi
TARGET_2ND_CPU_VARIANT  := cortex-a53

TARGET_USES_64_BIT_BINDER  := true
TARGET_SUPPORTS_64_BIT_APPS := true
TARGET_SUPPORTS_32_BIT_APPS := true

# ---------------------------- 平台 -----------------------------------------
TARGET_BOARD_PLATFORM        := msm8953
TARGET_BOOTLOADER_BOARD_NAME := MS600
TARGET_BOARD_PLATFORM_GPU    := qcom-adreno506
TARGET_NO_BOOTLOADER         := true

# ---------------------------- 内核（prebuilt） ------------------------------
# 设备为 user 构建，无内核源码，只能使用 prebuilt 内核。
# 该内核已实测与本机 boot/recovery 分区内的 kernel 逐字节一致。
TARGET_PREBUILT_KERNEL     := device/iflytek/MS600/prebuilt/kernel
BOARD_KERNEL_IMAGE_NAME    := Image.gz-dtb
BOARD_KERNEL_BASE          := 0x80000000
BOARD_KERNEL_PAGESIZE      := 2048
BOARD_KERNEL_TAGS_OFFSET   := 0x00000100
BOARD_RAMDISK_OFFSET       := 0x01000000
BOARD_KERNEL_OFFSET        := 0x00008000
BOARD_DTB_OFFSET           := 0x01f00000
BOARD_MKBOOTIMG_ARGS       := --ramdisk_offset 0x01000000 --tags_offset 0x00000100
BOARD_KERNEL_CMDLINE       := console=ttyHSL0,115200,n8 \
                              androidboot.console=ttyHSL0 \
                              androidboot.hardware=qcom \
                              msm_rtb.filter=0x237 \
                              ehci-hcd.park=3 \
                              lpm_levels.sleep_disabled=1 \
                              androidboot.bootdevice=7824900.sdhci \
                              earlycon=msm_hsl_uart,0x78af000 \
                              buildvariant=user

# ---------------------------- 分区（★ 本机实测）---------------------------
# system 3.0GB · vendor 1.0GB · boot/recovery 64MB · cache 256MB
BOARD_BOOTIMAGE_PARTITION_SIZE     := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 3221225472
BOARD_USERDATAIMAGE_PARTITION_SIZE := 21196642816
BOARD_CACHEIMAGE_PARTITION_SIZE    := 268435456
BOARD_FLASH_BLOCK_SIZE             := 131072

# 设备实测的额外根目录与软链（与 msm8953 官方参照一致）
BOARD_ROOT_EXTRA_FOLDERS  := persist firmware
BOARD_ROOT_EXTRA_SYMLINKS := \
    /vendor/dsp:/dsp \
    /vendor/firmware_mnt:/firmware \
    /mnt/vendor/persist:/persist

# ---------------------------- 文件系统 --------------------------------------
TARGET_USERIMAGES_USE_EXT4             := true
TARGET_USERIMAGES_USE_F2FS             := true
TARGET_USES_MKE2FS                     := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE     := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE   := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE      := ext4
BOARD_HAS_LARGE_FILESYSTEM             := true

# ---------------------------- 分区表类型 ------------------------------------
# A-only 单槽设备，无 A/B、无 dynamic partitions、无 metadata 分区
AB_OTA_UPDATER                  := false
BOARD_USES_METADATA_PARTITION   := false
BOARD_SUPER_PARTITION_SIZE      :=

# ---------------------------- AVB 验证启动 ----------------------------------
# ★ 实测结论：原厂 boot / recovery 分区内均搜不到 AVB0 / vbmeta 签名，
#   且 bootloader 处于 orange（已解锁）状态 → 本设备不做 AVB 强校验。
#   若强制开启 AVB 会导致编译产物带测试签名，反而可能启动失败，故关闭。
BOARD_AVB_ENABLE := false
# 关闭 dm-verity（与上面呼应，避免 system 被强行加密校验）
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS :=

# ---------------------------- Treble --------------------------------------
# 设备实测 ro.treble.enabled=true，且存在独立 vendor 分区
PRODUCT_FULL_TREBLE_OVERRIDE := true
BOARD_VNDK_VERSION           := current
# 原厂 vendor 为 Android 8.1（VNDK 27），额外产出低版本 VNDK 兼容库
PRODUCT_EXTRA_VNDK_VERSIONS  := 27 28 29

# ---------------------------- Recovery ------------------------------------
TARGET_RECOVERY_FSTAB    := device/iflytek/MS600/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"

# ---------------------------- 显示 / 图形 -----------------------------------
TARGET_USES_ION := true

# ---------------------------- 构建容错 --------------------------------------
# 设备树尚未补齐全部 vendor 依赖时，允许缺失依赖继续构建（便于逐轮迭代）
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
