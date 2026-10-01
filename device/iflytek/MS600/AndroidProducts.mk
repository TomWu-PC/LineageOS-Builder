#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# ★ Android 8.1 适配要点（2026-10-01 实测修复）：
#   $(LOCAL_DIR) 是 Android 10+ 才引入的变量，在 8.1 里【不会被定义】，
#   导致 PRODUCT_MAKEFILES 展开成 "/lineage_MS600.mk" → lunch 找不到产品。
#   8.1 时代的正确写法是 $(LOCAL_PATH)（由 build 系统在解析本文件前设置）
#   或者干脆写死相对源码根的路径。
#
#   另一个 8.1 的坑：COMMON_LUNCH_CHOICES 是 Android 10+ 的变量，
#   8.1 不认，必须改用 PRODUCT_MAKEFILES 本身的命名约定 +
#   AndroidProducts.mk 的 glob 机制。这里保留它（16.0+ 兼容），无副作用。

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_MS600.mk

COMMON_LUNCH_CHOICES := \
    lineage_MS600-user \
    lineage_MS600-userdebug \
    lineage_MS600-eng
