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
# ⚠️ 必须是 armv8-a，不能写 armv7-a-neon！
#    Android 10+ 的 build/make/core/combo/TARGET_linux-arm.mk:53 强制要求：
#    64 位设备上的 32 位第二架构，CPU 实际是 ARMv8，写 armv7-a-neon 会直接报
#      error: Incorrect TARGET_2ND_ARCH_VARIANT, armv7-a-neon. Use armv8-a instead..
#    → dumpvars 失败 → lunch 失败 → 编译一行都没跑（2026-09-30 第二次云编译死因）
#    注意：Android 8.1 时代的 msm8953 设备树写的是 armv7-a-neon，不可照搬！
TARGET_2ND_ARCH_VARIANT := armv8-a
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
# ⚠️ 这里【不要】写 buildvariant=xxx！
#    原因：DTB 的 bootargs 里本来就自带 `buildvariant=user`（实测 dtb_ms600_live.fdt 确认），
#    而 build 系统还会按 lunch 变体再追加一个 `buildvariant=<变体>`。
#    自己再写一个 → 三份重复，且末尾那个覆盖前面，行为不可控。
#
#   实测 2026-09-30 第二轮：lunch 选了 -eng，结果 cmdline 变成
#       ... buildvariant=user buildvariant=eng    ← 末尾 eng 生效，错的
#    正解：lunch 用 lineage_MS600-userdebug，让 build 系统自己追加 userdebug。
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

# 设备实测的额外根目录与软链（与 msm8953 官方参照一致）
BOARD_ROOT_EXTRA_FOLDERS  := persist firmware
# ⚠️ 【2026-10-01 第三次云编译（#43）失败教训 —— 已移除 /vendor/dsp:/dsp】
#   症状：编到 99.999%（102667/102668），最后打包 system.img 时炸：
#     set_selinux_xattr: No such file or directory searching for label "/dsp"
#     e2fsdroid: No such file or directory while configuring the file system
#   根因：这里声明了软链 /vendor/dsp:/dsp，但 out/target/product/MS600/system/ 下
#         并没有 /dsp 这个实际目录；而 device/qcom/sepolicy-legacy/common/file_contexts:610
#         有一条 `/dsp(/.*)?  u:object_r:adsprpcd_file:s0`。
#         Android 11 的 e2fsdroid 会【严格校验】file_contexts 每条规则的目标是否存在，
#         找不到 /dsp 就直接失败（Android 8.1 的 15.1 不校验，所以 15.1 能过）。
#   处置：本设备定位为【普通平板】，不需要音频 DSP（adsprpcd）相关目录，
#         故直接去掉该软链声明，让 file_contexts 的 /dsp 规则成为"无目标的孤儿规则"。
#   ⚠️ 注意：只删这一行即可，不要删 file_contexts 里那条规则（那是公共 sepolicy 仓）。
BOARD_ROOT_EXTRA_SYMLINKS := \
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
# ⚠️ 这里绝对不能写 PRODUCT_EXTRA_VNDK_VERSIONS！
#    它是【产品级只读变量】，只能写在产品配置文件（device.mk / lineage_MS600.mk）里。
#    写在这里会直接报错：
#      BoardConfig.mk:101: error: cannot assign to readonly variable: PRODUCT_EXTRA_VNDK_VERSIONS
#      → dumpvars failed → lunch 失败 → 编译一行都没跑
#    （2026-09-30 第一次云编译就是死在这一行）
#
# 【遗留问题，后续轮次再处理】
#   原厂 vendor 是 Android 8.1（VNDK 27），理论上需要额外产出低版本 VNDK 兼容库，
#   但 AOSP 11 的 prebuilts/vndk/ 里只有 v28/v29，**没有 v27**，
#   所以直接把 27 填进去大概率还是会报「不支持的 VNDK 版本」。
#   正确解法留待第二轮评估（可选方向：BOARD_VNDK_VERSION 降级 / 从原厂 vendor 提取 v27 库）。

# ---------------------------- Recovery ------------------------------------
TARGET_RECOVERY_FSTAB    := device/iflytek/MS600/recovery.fstab
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"

# ---------------------------- 显示 / 图形 -----------------------------------
TARGET_USES_ION := true

# ---------------------------- 构建容错 --------------------------------------
# 设备树尚未补齐全部 vendor 依赖时，允许缺失依赖继续构建（便于逐轮迭代）
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
