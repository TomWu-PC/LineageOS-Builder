# LineageOS 18.1 for iFlytek MS600（讯飞听见 L1）

> GitHub Actions 云编译工程 —— 为「讯飞听见 L1 会议平板」移植 LineageOS 18.1（Android 11）

---

## 一、为什么必须云编译

| 限制 | 本机（Windows 笔记本） | 云编译环境 |
|---|---|---|
| 操作系统 | Windows 10 IoT LTSC | Ubuntu 22.04 |
| 内存 | **7.8 GB**（Android 编译最低要 16 GB） | 16 GB |
| 结论 | ❌ 物理上无法编译 | ✅ 可行 |

**本机只负责：写设备树 → 推送到 GitHub → 触发云端编译 → 下载产物。**

---

## 二、设备事实（全部本机实测，2026-09-30）

| 项目 | 值 |
|---|---|
| 型号 | iFlytek MeetingService600（MS600） |
| SoC | **Qualcomm SDM450 / msm8953** |
| GPU | Adreno 506 |
| 内核 | **3.18.71-perf**（厂商版，**无源码，只能用 prebuilt**） |
| 原系统 | Android 8.1.0 / API 27（user 构建，release-keys） |
| Treble | ✅ 有独立 vendor 分区 |
| 屏幕 | 1200×1920 竖屏面板 + density 224 |
| 触摸 | FocalTech `fts_ts` |
| bootloader | ✅ 已解锁（`verifiedbootstate=orange`） |
| AVB | ❌ 原厂 boot/recovery 内无 AVB 签名，不做强校验 |
| 分区 | system 3.0G / vendor 1.0G / boot 64M / recovery 64M / cache 256M |

---

## 三、与 TWRP 工程的关键差异（⚠️ 不要照搬 TWRP 的 workflow）

| 项目 | TWRP 工程 | **本工程（LineageOS 18.1）** |
|---|---|---|
| Python | 需要 **Python 2.7**（deadsnakes PPA） | 需要 **Python 3**（系统自带，不要装 python2） |
| JDK | **JDK 8** | **JDK 11** |
| 源码体积 | 约 16 GB | **约 45 GB**（需 `--depth=1`） |
| 单次耗时 | 约 13 分钟 | **2~5 小时** |

---

## 四、目录结构

```
LineageOS-Builder/
├── .github/workflows/
│   └── build-lineage.yml          # 云编译工作流（14 个步骤）
├── device/iflytek/MS600/          # 设备树
│   ├── AndroidProducts.mk         # lunch 目标注册
│   ├── lineage_MS600.mk           # 产品定义
│   ├── BoardConfig.mk             # ★ 硬件配置（分区/内核/AVB/Treble）
│   ├── device.mk                  # 设备软件包
│   ├── recovery.fstab             # 分区表（已修正挂载路径）
│   └── prebuilt/
│       ├── kernel                 # 27.5 MB，与设备原厂内核逐字节一致
│       ├── dtb_ms600_live.fdt
│       └── dtb_ms600_origin.dtb
└── README.md
```

---

## 五、如何触发编译

1. 打开仓库的 **Actions** 页面
2. 选择左侧 **「Build LineageOS 18.1 for MS600」**
3. 点右侧 **「Run workflow」**，填参数：

| 参数 | 建议值 | 说明 |
|---|---|---|
| `build_target` | `recoveryimage` | 第一轮先用它验证环境（最快） |
| `jobs` | `4` | 并行度，内存吃紧就降到 2 |
| `sync_only` | `false` | 只想验证 sync 时设 true |

4. 点绿色 **「Run workflow」** 开始

---

## 六、迭代路线

| 轮次 | 目标 | 预期耗时 |
|---|---|---|
| **第 1 轮** | sync 成功 + lunch 成功 + 编出 recovery.img | 2~3 小时 |
| 第 2 轮 | 补齐 vendor blobs，编出 boot.img | 3~4 小时 |
| 第 3 轮 | 编出完整 system.img（`bacon`） | 4~5 小时 |
| 第 4 轮+ | 刷入调试、修 HAL、修显示方向 | 每轮 2~4 小时 |

---

## 七、风险与兜底

**已知风险**
- GitHub 免费 runner 磁盘约 84 GB，LineageOS 源码 45 GB + 编译产物 30 GB → **接近上限**，工作流已加入磁盘清理步骤
- 原厂 vendor 是 Android 8.1（VNDK 27），与 Android 11（VNDK 30）存在代差 → 已在 BoardConfig 声明 `PRODUCT_EXTRA_VNDK_VERSIONS := 27 28 29`
- 云编译单次上限 6 小时，工作流设为 355 分钟超时

**兜底措施**（都已就位）
- ✅ 全量分区备份（14 分区 4.6 GB，含 MD5）
- ✅ EDL 9008 救砖通道实测可用（音量加+音量减同时插线）
- ✅ TWRP 已移植成功，可随时刷回原厂 recovery
- ✅ bootloader 已解锁

---

## 八、参考

- LineageOS 官方同平台设备树：[LineageOS/android_device_xiaomi_msm8953-common](https://github.com/LineageOS/android_device_xiaomi_msm8953-common)（`lineage-18.1` 分支）
- 该参照的 `BOARD_KERNEL_BASE` / `PAGESIZE` / `ramdisk_offset` / `SYSTEMIMAGE_PARTITION_SIZE`
  **与本设备实测值逐项一致**，故直接沿用其架构
