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
