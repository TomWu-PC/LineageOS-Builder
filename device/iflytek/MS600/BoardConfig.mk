#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# ===========================================================================
#  MS600（讯飞听见 L1）BoardConfig —— LineageOS 15.1（Android 8.1）
#
#  ★ 本文件是从 lineage-18.1 分支的设备树【降级适配】而来，
#    目标：与设备原厂 vendor（Android 8.1 / API 27）版本完全对齐，
#    从而让「自编 system + 原厂 vendor」能够正常协同工作。
#
#  降级要点（Android 11 → Android 8.1 的差异）：
#    ① TARGET_2ND_ARCH_VARIANT 改回 armv7-a-neon
#       （8.1 时代就是这么写的；armv8-a 是 Android 10+ 才强制）
#    ② 删除全部 VNDK 相关（8.1 没有 VNDK 概念）
#    ③ 删除 PRODUCT_FULL_TREBLE_OVERRIDE（8.1 无此变量）
#    ④ 删除 BUILD_BROKEN_* 系列（8.1 不认）
#    ⑤ 删除 TARGET_USES_MKE2FS（8.1 没有）
#    ⑥ 关闭 Treble 相关开关
# ===========================================================================

# ---------------------------- 架构 -----------------------------------------
# SDM450 / msm8953 = Cortex-A53 x8，64 位
TARGET_ARCH             := arm64
TARGET_ARCH_VARIANT     := armv8-a
TARGET_CPU_ABI          := arm64-v8a
TARGET_CPU_ABI2         :=
TARGET_CPU_VARIANT      := cortex-a53

TARGET_2ND_ARCH         := arm
# ⚠️ 15.1（Android 8.1）时代，32 位第二架构必须写 armv7-a-neon
#    （Android 10+ 才要求改成 armv8-a；这里是 8.1，反而要写老的）
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI      := armeabi-v7a
TARGET_2ND_CPU_ABI2     := armeabi
TARGET_2ND_CPU_VARIANT  := cortex-a53

TARGET_USES_64_BIT_BINDER  := true
TARGET_SUPPORTS_64_BIT_APPS := true

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
# ⚠️ 【不要】写 buildvariant=xxx！
#    DTB 的 bootargs 里自带 `buildvariant=user`，build 系统还会按 lunch 变体追加一个。
#    自己再写一个 → 三份重复，末尾那个生效，行为不可控。
#    正解：lunch 用 lineage_MS600-userdebug，让 build 系统自己追加。
BOARD_KERNEL_CMDLINE       := console=ttyHSL0,115200,n8 \
                              androidboot.console=ttyHSL0 \
                              androidboot.hardware=qcom \
                              msm_rtb.filter=0x237 \
                              ehci-hcd.park=3 \
                              lpm_levels.sleep_disabled=1 \
                              androidboot.bootdevice=7824900.sdhci \
                              earlycon=msm_hsl_uart,0x78af000

# ---------------------------- 分区（★ 本机实测）---------------------------
# system 3.0GB · vendor 1.0GB · boot/recovery 64MB · cache 256MB
BOARD_BOOTIMAGE_PARTITION_SIZE     := 67108864
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE   := 3221225472
BOARD_USERDATAIMAGE_PARTITION_SIZE := 21196642816
BOARD_CACHEIMAGE_PARTITION_SIZE    := 268435456
BOARD_FLASH_BLOCK_SIZE             := 131072

# 设备实测的额外根目录与软链
BOARD_ROOT_EXTRA_FOLDERS  := persist firmware
BOARD_ROOT_EXTRA_SYMLINKS := \
    /vendor/dsp:/dsp \
    /vendor/firmware_mnt:/firmware \
    /mnt/vendor/persist:/persist

# ---------------------------- 文件系统 --------------------------------------
TARGET_USERIMAGES_USE_EXT4             := true
TARGET_USERIMAGES_USE_F2FS             := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE     := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE   := ext4
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE      := ext4
BOARD_HAS_LARGE_FILESYSTEM             := true

# ---------------------------- 分区表类型 ------------------------------------
# A-only 单槽设备，无 A/B、无 dynamic partitions、无 metadata 分区
AB_OTA_UPDATER                  := false
BOARD_USES_METADATA_PARTITION   := false

# ---------------------------- AVB 验证启动 ----------------------------------
# ★ 实测结论：原厂 boot / recovery 分区内均搜不到 AVB0 / vbmeta 签名，
#   且 bootloader 处于 orange（已解锁）状态 → 本设备不做 AVB 强校验。
BOARD_AVB_ENABLE := false

# ---------------------------- Recovery ------------------------------------
TARGET_RECOVERY_FSTAB    := device/iflytek/MS600/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"

# ---------------------------- 显示 / 图形 -----------------------------------
TARGET_USES_ION := true

# ---------------------------- 构建容错 --------------------------------------
# 设备树尚未补齐全部 vendor 依赖时，允许缺失依赖继续构建（便于逐轮迭代）
BUILD_BROKEN_DUP_RULES := true

# ===========================================================================
# 【15.1 已删除的 18.1 专有配置】——记录在此，防止误加回来
# ===========================================================================
# ✗ BOARD_VNDK_VERSION                  / VNDK 是 Android 9+ 概念，8.1 无
# ✗ PRODUCT_FULL_TREBLE_OVERRIDE        / 产品级变量，且 8.1 不认
# ✗ TARGET_USES_MKE2FS                  / 8.1 没有 mke2fs 支持
# ✗ BUILD_BROKEN_ELF_PREBUILT_*         / Android 10+ 才有的开关
