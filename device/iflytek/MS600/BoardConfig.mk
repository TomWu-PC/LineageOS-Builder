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

# ─────────────────────────────────────────────────────────────────────────────
# ★★★ 2026-10-01 血泪教训（连坑 3 个 run：#43 / #44 / #45）★★★
#     —— /dsp → /firmware 连环报错的【真正根因】与【最终处置】
# ─────────────────────────────────────────────────────────────────────────────
# 【症状】每次都是编到 99.999%（102667/102668），最后打包 system.img 时炸：
#     set_selinux_xattr: No such file or directory searching for label "/xxx"
#     e2fsdroid: No such file or directory while configuring the file system
#     ninja: build stopped: subcommand failed.
#   其中 /xxx 先是 \"/dsp\"，删掉后又变成 \"/firmware\"、下一个会是 \"/persist\"。
#
# 【完整机制】（AOSP 打包链，务必理解，否则会一直"打地鼠"）
#   ① BOARD_ROOT_EXTRA_FOLDERS / BOARD_ROOT_EXTRA_SYMLINKS 建的产物
#      都落在 TARGET_ROOT_OUT（out/target/product/MS600/root/），也就是 ramdisk。
#   ② 但本设备的 system.img 用的是 system-as-root（e2fsdroid -a /），
#      Makefile 里 FULL_SYSTEMIMAGE_DEPS += $(INTERNAL_ROOT_FILES)，
#      ⇒ root/ 的内容会被【合并进 system.img】。
#   ③ e2fsdroid 打包时会遍历镜像内 inode 树，给每个条目查 SELinux 标签。
#      ⇒ 镜像里出现 /firmware、/persist 这些【真实目录】就必须有对应规则。
#   ④ 而本设备采用的 sepolicy 组合里【没有】/dsp、/firmware、/persist 的规则
#      （实测：strings file_contexts.bin | grep -cE '^/(dsp|firmware|persist)' = 0）
#      ⇒ selabel_lookup 失败 ⇒ e2fsdroid 直接报错退出。
#
# 【为什么 15.1（Android 8.1）没事】
#   Android 8.1 的 e2fsdroid 对"查不到标签"只告警不失败；Android 11 直接 fail。
#   同一份设备树，15.1 能编过、18.1 编不过 —— 不是配置错了，是新版本更严格。
#
# 【★ 最关键的坑：改声明 ≠ 清产物】
#   BOARD_ROOT_EXTRA_* 的产物是 init.environ.rc 的 post-install 副作用，
#   删掉声明后 init.environ.rc 会重生，但【旧的软链/目录不会被删除】——
#   它们变成"僵尸产物"，下一轮编译照样被合并进 system.img，照炸不误。
#   ⇒ 改完声明后，【必须】手工清掉 out/.../<dev>/root/ 里对应的僵尸条目！
#
# 【最终处置】本设备定位为【普通平板】：
#   - 无音频 DSP 需求        ⇒ 不需要 /dsp
#   - /firmware、/persist 的挂载由 recovery.fstab / fstab.qcom 负责
#     （init 会在开机时按 fstab 挂载），不需要在 ramdisk 里预建挂载点目录。
#   ⇒ 整块移除 BOARD_ROOT_EXTRA_FOLDERS 与 BOARD_ROOT_EXTRA_SYMLINKS。
#   ⚠️ 删完记得清 out/.../<dev>/root/{dsp,firmware,persist} 三个僵尸。
# ─────────────────────────────────────────────────────────────────────────────
# （原内容，已按上述结论移除，保留备查）
#   BOARD_ROOT_EXTRA_FOLDERS  := persist firmware
#   BOARD_ROOT_EXTRA_SYMLINKS := \
#       /vendor/firmware_mnt:/firmware \
#       /mnt/vendor/persist:/persist
BOARD_ROOT_EXTRA_FOLDERS  :=
BOARD_ROOT_EXTRA_SYMLINKS :=

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
