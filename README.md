# Win7 32 位汇编实验环境 · 一键装机套件

给《汇编语言与微型计算机技术》实验课（TPC 系列微机接口实验箱）用的 **VMware + Win7 x86 SP1 无人值守安装套件**。

目标：**双击 `.vmx` → 等 20 分钟 → 直接进桌面**，人工只在"装 VMware Tools""装 TPC 软件"两个向导里各点几下。

> 配套长文教程见 [`docs/CSDN-Win7汇编实验环境搭建.md`](docs/CSDN-Win7汇编实验环境搭建.md)（含全部 12 个坑的报错原文与解法）。

## 目录

```
vmx/win7x86.vmx       虚拟机配置模板（已含 12 代 CPU 避坑参数）
vmx/win7.vmdk         预建的 80GB 虚拟磁盘（占用按实际增长）
vmx/answer.iso        无人值守应答盘（874 KB，ISO9660+Joliet+UDF）
vmx/autounatt.xml     应答文件源文件（改密码/计算机名后重新打包）
scripts/make-answer-iso.sh   用 mkisofs 重新生成 answer.iso
docs/CSDN-Win7汇编实验环境搭建.md   长文教程（投稿版）
docs/踩坑速查.md        按现象查原因
```

## 快速开始

1. 把本仓库克隆或解压到 **`E:\asm-kit`**（放其它盘也行，需改 `vmx/win7x86.vmx` 里 3 行路径）
2. 准备两个文件放到 `iso/` 与 `tools/` 下（**本仓库不含，见下节**）：
   - `iso/cn_windows_7_ultimate_with_sp1_x86_dvd_u_677486.iso`
   - `tools/VMwareTools-11.0.6.iso`
3. 双击 `vmx/win7x86.vmx` → 问"已移动/已复制"选 **我已复制** → 等 20 分钟

装完进桌面：账号 `Administrator`，密码见你改过的 `autounatt.xml`（模板默认 `tpc2026`）。

## 本仓库不含什么（以及为什么）

| 缺的东西 | 原因 | 从哪来 |
|---|---|---|
| Win7 镜像（2.5 GB） | GitHub 单文件上限 100 MB | itellyou 的 ed2k/网盘，SHA1 `B92119F5B732ECE1C0850EDA30134536E18CCCE7` |
| VMware Workstation 安装程序 | 需注册 Broadcom 账号，且不允许二次分发 | support.broadcom.com（17.6.x / 26.x 免费） |
| VMware Tools ISO | 同上 | Broadcom 归档，或本仓库 `docs` 里写的替代方案 |
| TPC 集成开发环境 | 厂商软件，请走学校渠道 | 任课老师/实验中心光盘 |

## 素材获取（我实际用的下载源，均已亲自下载校验）

| 素材 | 地址 | 校验值 / 备注 |
|---|---|---|
| **Win7 旗舰版 x86 SP1 原版 ISO** | <https://msdn.itellyou.cn/> → 搜 `Windows 7` → 选「Windows 7 简体中文旗舰版 with SP1 x86 (MSDN, 6.1.7601.17514, 2011-11)」 | `cn_windows_7_ultimate_with_sp1_x86_dvd_u_677486.iso`，2,653,276,160 字节，SHA1 `B92119F5B732ECE1C0850EDA30134536E18CCCE7` |
| **VMware Tools 11.0.6（Win7 免补丁，推荐）** | <https://packages-prod.broadcom.com/tools/frozen/windows/WindowsToolsVista/SP2/windows.iso> | 143,421,440 字节，实测可直下 |
| VMware Tools 11.0.6 备份 | <https://github.com/YorkWaugh/vmware_tools_backup/releases/download/Archives/winVista.iso> | 同一文件 |
| VMware Tools 12.4.9（32 位最后一版） | 同仓库 `windows-x86.iso` | 54,243,328 字节；需先打 KB4490628 + KB4474419 |
| **TPC 集成开发环境** | <https://gitcode.com/open-source-toolkit/33c3d>，文件 `1. 集成开发环境.rar` | ⚠️ 是 **TPC-ZK-II** 版，与 TPC-USB 同厂同架构但不完全等同；纯软件实验可用，硬件联机需机型支持；序列号 `111111` |

> **版权说明**：以上为镜像/索引站点与第三方项目页，本仓库**不托管任何安装文件**。请核对 SHA1 后于合规范围内使用；校园环境建议优先走学校渠道（MSDN 订阅 / 机房统一镜像 / 实验箱配套光盘）。
>
> 实测提醒：`GitCode` 对匿名直链有限流（API `429`、`raw.gitcode.com` `403`），请用浏览器登录后下载。

## 已验证环境

| 项 | 值 |
|---|---|
| 宿主 | Windows 11，i9-12900H，32 GB |
| VMware | Workstation 26.0.0（17.6.x 同样适用） |
| 客机 | Windows 7 旗舰版 **32 位** SP1，单分区 80 GB |
| 关键参数 | `guestOS="windows7"`、`firmware="bios"`、USB 2.0、SCSI(LSILogic)、无网卡 |
| 实测 | 自动分区 + 自动安装 + 跳过全部 OOBE，约 20 分钟进桌面 |

## 三条最容易踩的坑（详情见 docs）

1. **Win7 x86 只能用传统 BIOS 引导** —— `firmware = "bios"`，写 UEFI 会卡在无引导设备；
2. **`processorArchitecture` 必须是 `x86`** —— 写 `amd64` 的组件会被整段忽略，分区配置无声失效；
3. **`specialize` 阶段的 `RunSynchronousCommand` 返回非零码 = 安装直接失败** —— 要么别放，要么写绝对路径 + `& exit /b 0`。

## License

脚本与文档：MIT。第三方软件与镜像版权归各自厂商，本仓库不包含它们的二进制。
