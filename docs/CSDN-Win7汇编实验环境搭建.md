# 用 VMware 从零搭 Win7 32 位汇编实验环境：无人值守安装 + 12 个坑全记录

> 面向《汇编语言与微型计算机技术》实验课（TPC 系列微机接口实验箱）。
> 宿主：Windows 11 + i9-12900H + 32 GB，VMware Workstation 26.0.0（17.6.x 同样适用）。
> 全程实机验证，不是转述教程。

## 一、为什么非要虚拟机

课程配套的软件是 2010 年前后编译的 32 位程序，实验箱的 USB 驱动 `TPCA.sys` 也是 32 位内核驱动。这两条决定了：

1. **必须装 32 位 Windows 7**（64 位系统装不了这个驱动）；
2. **必须虚拟机**（Win11 上跑不了 2010 年的 32 位 DOS 时代工具链，也不该为了它降级系统）。

于是路径很清晰：**VMware + Win7 x86 SP1 + 无人值守应答文件 + 只装必要软件**。

## 二、素材清单

| 素材 | 说明 |
|---|---|
| `cn_windows_7_ultimate_with_sp1_x86_dvd_u_677486.iso` | 微软官方 Win7 旗舰版 32 位 SP1 原版镜像，2,653,276,160 字节，SHA1 `B92119F5B732ECE1C0850EDA30134536E18CCCE7` |
| VMware Tools **11.0.6** | Win7 SP1 免打补丁就能装（关键，见第六节） |
| VMware Tools 12.4.9（可选） | 32 位 Windows 能用的最后一版，需先打 KB4490628 + KB4474419 |
| TPC 集成开发环境安装包 | 随实验箱光盘/任课老师提供，约 11 MB，序列号通常 `111111` |
| `autounatt.xml` | 无人值守应答文件（本文第五节给出全文） |

> 微软 2024 年已撤下 Win7 官方下载，镜像只能走 itellyou 的 ed2k/网盘；下完务必核对上面的 SHA1。

## 三、第一步：手写 .vmx，把 12 代 CPU 的坑一次性绕开

用 VMware 向导新建虚拟机后，先**关机**，用记事本编辑 `.vmx`。下面这些行是关键（缺一行就可能蓝屏/黑屏/开不了机）：

```ini
guestOS = "windows7"                    # 32 位 Win7；新版 VMware 不再认 win7pro
firmware = "bios"                       # Win7 x86 不支持 UEFI 引导，必须传统 BIOS
memsize = "4096"
numvcpus = "2"
bios.bootDelay = "20000"                # 给 BIOS 留出选光驱启动的时间

# 12 代以上 CPU 必加，否则极慢 / 蓝屏 / 黑屏
monitor.virtual_exec = "hardware"
monitor.virtual_mmu = "software"
mks.enableVulkanRenderer = "FALSE"
cpuid.1.ecx = "00000001"

# 磁盘：Win7 没有 NVMe 驱动，用 SCSI（LSI Logic）或 SATA
scsi0.present = "TRUE"
scsi0.virtualDev = "lsilogic"
scsi0:0.present = "TRUE"
scsi0:0.fileName = "win7.vmdk"

# 三个光驱：Win7 镜像 / 应答盘 / VMware Tools
ide1:0.present = "TRUE"
ide1:0.deviceType = "cdrom-image"
ide1:0.fileName = "D:\asm-kit\iso\cn_windows_7_ultimate_with_sp1_x86_dvd_u_677486.iso"
ide1:1.present = "TRUE"
ide1:1.deviceType = "cdrom-image"
ide1:1.fileName = "D:\asm-kit\vmx\answer.iso"
ide0:0.present = "TRUE"
ide0:0.deviceType = "cdrom-image"
ide0:0.fileName = "D:\asm-kit\tools\VMwareTools-11.0.6.iso"

# USB 控制器必须是 2.0（Win7 没有 xHCI 驱动，实验箱也是 USB 2.0 设备）
usb.present = "TRUE"
ehci.present = "TRUE"
ehci:4.present = "TRUE"
ehci:4.deviceType = "ehci"
ehci:4.virtualDev = "usb"
usb_xhci:4.present = "FALSE"
```

### 3.1 IDE 从属设备必须有主设备

VMware 里 `ide1:0/1` 是**主通道**的主/从，`ide0:0/1` 是**副通道**的主/从。只写 `ide0:1`（副通道从设备）会直接开机失败：

```
[msg.disk.slavenomaster] The IDE device (disks/CD-ROM) configuration is incorrect
```

所以三个光驱的正确排法是：`ide1:0` + `ide1:1` + `ide0:0`。

## 四、第二步：让安装程序自己跑完（无人值守）

思路：把 `Autounattend.xml` 放在**另一张光盘**的根目录。Win7 的安装程序（WinPE）会搜索可移动介质根目录里的这个文件——**WinPE 确实会读第二块光驱**，这一点我用报错信息里的路径 `[E:\autounattend.xml]` 验证过（E: 正是挂载 `answer.iso` 的那个光驱）。

用 `mkisofs`（VMware 自带 `mkisofs.exe` 也行）打一张 874 KB 的小光盘：

```bash
mkdir -p answer_src && cp autounatt.xml answer_src/Autounattend.xml
cd answer_src && mkisofs -o ../answer.iso -udf -J -R -V "ANSWER" Autounattend.xml
```

## 五、应答文件全文（能直接用的版本）

```xml
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="x86"
               publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>zh-CN</UILanguage></SetupUILanguage>
      <InputLocale>0804:00000804</InputLocale>
      <SystemLocale>zh-CN</SystemLocale>
      <UILanguage>zh-CN</UILanguage>
      <UserLocale>zh-CN</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup" processorArchitecture="x86"
               publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <CreatePartitions>
            <CreatePartition wcm:action="add">
              <Order>1</Order>
              <Type>Primary</Type>
              <Extend>true</Extend>
            </CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add">
              <Active>true</Active>
              <Format>NTFS</Format>
              <Label>Win7</Label>
              <Letter>C</Letter>
              <Order>1</Order>
              <PartitionID>1</PartitionID>
            </ModifyPartition>
          </ModifyPartitions>
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallFrom>
            <MetaData wcm:action="add">
              <Key>/IMAGE/INDEX</Key>
              <Value>1</Value>
            </MetaData>
          </InstallFrom>
          <InstallTo>
            <DiskID>0</DiskID><PartitionID>1</PartitionID>
          </InstallTo>
          <WillShowUI>OnError</WillShowUI>
        </OSImage>
      </ImageInstall>
      <UserData><AcceptEula>true</AcceptEula></UserData>
    </component>
  </settings>

  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86"
               publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <TimeZone>480</TimeZone>
      <ComputerName>WIN7-TPC</ComputerName>
    </component>
  </settings>

  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86"
               publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>你的密码</Value><PlainText>true</PlainText>
        </AdministratorPassword>
      </UserAccounts>
      <AutoLogon>
        <Password><Value>你的密码</Value><PlainText>true</PlainText></Password>
        <Username>Administrator</Username>
        <Enabled>true</Enabled>
        <LogonCount>3</LogonCount>
      </AutoLogon>
    </component>
  </settings>
</unattend>
```

### 5.1 五个能让你装失败无数次的细节

这段 XML 我改了四轮才跑通，每个错误都对应一条具体报错：

**① `wcm:` 命名空间必须声明在根元素**
只写在 `<Disk>` 上，出那棵子树就是"未声明前缀"，安装程序直接报：

```
Windows 无法分析或处理无人参与应答文件 [E:\autounattend.xml]。
应答文件无效。在应答文件的第 65 行第 9 列检测到该错误。
```

**② `processorArchitecture` 必须写 `x86`**
x86 安装盘的 WinPE 是 32 位。写 `amd64` 的组件会被**整段忽略**——表现是能跳过语言界面，但停在"您想将 Windows 安装在何处"，分区配置完全没生效。

**③ `specialize` 阶段的 `RunSynchronousCommand` 失败 = 安装直接失败**
如果这里放了命令又返回非零退出码，装到"安装程序正在为首次使用计算机做准备"就会弹：

```
Windows 无法完成安装。若要在此计算机上安装 Windows，请重新启动该安装。
```

日志原文（我从 VMDK 原始字节里挖出来的）是 `Error while processing RunSynchronousCommand settings`。原因是 specialize 阶段的 PATH 里没有 `reg.exe`。要么别在这个阶段放命令，要么写绝对路径并强制返回 0：

```
C:\Windows\System32\cmd.exe /c C:\Windows\System32\reg.exe add ... /f & exit /b 0
```

**④ `oobeSystem` 里不能写 Windows 8 才有的元素**

```
Windows 无法分析或处理 pass [oobeSystem] 的无人参与应答文件…
应答文件中指定的组件或设置不存在。
```

`HideLocalAccountScreen`、`HideOEMRegistrationScreen`、`HideOnlineAccountScreens` 这三个 **Win7 没有**。Win7 只认 6 个：`HideEULAPage`、`HideWirelessSetupInOOBE`、`NetworkLocation`、`ProtectYourPC`、`SkipMachineOOBE`、`SkipUserOOBE`。

**⑤ `DiskConfiguration` 必须照微软模板写**
写错不会报错，只是**静默失效**，回落到手动分区界面；此时手点"下一步"还可能报：

```
Windows 无法安装选择的分区进行准备。
```

三个要点：`CreatePartition` 用 `<Extend>true</Extend>`（**不要**同时写 `Size`）、`ModifyPartition` 要有 `<Letter>C</Letter>`、`DiskID` 和 `WillWipeDisk` 放在 `<Disk>` 的**最后**。

## 六、第三步：VMware Tools 的版本陷阱

新版 VMware（13.x Tools）**不支持 Win7**。32 位 Windows 能用的最高版本是 12.4.9，但 12.4.9 需要 SHA-2 签名支持（KB4490628 + KB4474419）。

**最省事的选择：VMware Tools 11.0.6**，Win7 SP1 免打补丁就能装，功能（自适应分辨率、剪贴板、拖拽、共享文件夹）都够用。

装完重启，屏幕就会自动适应窗口大小——**没装 Tools 时 Win7 只有 800×600，这是"屏幕很小"的唯一原因**。

## 七、第四步：TPC 软件 + 实验箱联机

1. 双击 `TPC-ZK-II集成开发环境.exe`，序列号 `111111`，装到默认目录；
2. 实验箱 USB 线插主机 → VMware 菜单 **虚拟机 → 可移动设备 → `ST-Ericsson USB Device` → 连接**（这块 USB 芯片是 ST-Ericsson 的，所以设备名不是 TPC）；
3. 客机「设备管理器」里会有带问号的设备 → 更新驱动 → 指向软件目录下的 `driver\`（`TPCA.inf` + `TPCA.sys`）→ 装好后出现 **`TPC Adapter`**；
4. 打开 IDE → 菜单「选项 → 硬件检测」→ 显示连接正常；
5. 实验三/四的端口（源码里写死的）：**8255 = `288H~28BH`，8253 = `280H~283H`**。

## 八、常见问题速查

| 现象 | 原因与处理 |
|---|---|
| 开机报 `Guest operating system 'win7pro' is not supported` | 新版 VMware 改了客户机 ID，用 `guestOS = "windows7"` |
| 开机报 `Cannot assign available PCI slot to 'ethernet0'` | PCI 槽位用满（SCSI + 3 个 IDE 光驱 + 显卡 + USB）。把网卡关掉即可；要联网就减少光驱或把磁盘改 IDE |
| 开机报 `The IDE device configuration is incorrect` | IDE 从属设备没主设备，见 3.1 |
| 黑屏 / 花屏 / 极慢 | 缺 `monitor.virtual_mmu = "software"` 等三行，见第三节 |
| 蓝屏 0x0000007B | 磁盘控制器被换过，或用了 NVMe；Win7 只能 SCSI/SATA |
| Tools 装不上 | 用了 13.x；换 11.0.6 或先打 KB4474419 |
| 虚拟机里看不到实验箱 | USB 兼容性不是 2.0；或没在"可移动设备"里点连接 |
| 装完只有 800×600 | Tools 没装 |

## 九、两个提效小技巧

**① 没有挂载工具也能读客机磁盘里的日志**
`vmware-mount` 不一定有。Win7 的 Setup 日志是 UTF-16 文本，直接对 `.vmdk` 原始字节做 UTF-16LE 解码 + 关键字搜索，就能捞出 `setuperr.log` 的内容：

```python
data = open(r"win7x86.vmdk", "rb").read()
i = data.find("RunSynchronous".encode("utf-16-le"))
print(data[i-2000:i+2000].decode("utf-16-le", "ignore"))
```

**② `vmrun` 的两个真实限制**（踩过才知道）
- `runProgramInGuest` 跑**无参数**程序正常（`whoami.exe` 返回 0），但带重定向/UNC 的 `cmd /c ...` 一律返回 1；
- `CopyFileFromHostToGuest` 在部分版本上会静默失败。
- 所以**别指望全自动远程装机**，把安装包做成光盘/共享目录让用户在客机里双击，反而更稳。

## 十、效果

整个流程跑完后：自动分区 → 自动复制 → 重启两次 → 跳过全部欢迎界面 → 直接进桌面。**从双击 .vmx 到能用 IDE 调试，约 20 分钟，人工操作只有"装 Tools + 装 TPC"两次向导点击。**

配套文件（.vmx 模板、`autounatt.xml`、打包好的应答盘、四个实验的源码）已整理成仓库，见文末链接；Win7 镜像与 TPC 安装包属第三方资源，请按学校渠道获取。

---

**参考**：VMware 客户机 ID 权威列表见安装目录下的 `isoimages_manifest.txt`；Win7 无人值守各组件的 pass 归属以微软 `unattend` 文档为准。
