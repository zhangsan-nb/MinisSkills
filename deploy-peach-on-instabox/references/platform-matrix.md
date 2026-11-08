# 平台能力矩阵（2026-11-08）

下面按“部署是否有现实路径”分类，**不表示本次已实机测试**。重跑前核对官方最新镜像 manifest 与目标机器权限。

| 平台 | Peach Docker | CloudDrive2 FUSE | Jackett/Prowlarr | 建议路线 / 限制 |
|---|---|---|---|---|
| InstaBox amd64 | 官方目标架构 | 仅在平台允许特权/FUSE 时 | 可选 | API/CLI + `/data` + 用户批准 SSH 步骤；尽量使用私有访问 |
| Ubuntu/Debian amd64 裸机 | 官方目标架构 | Linux Engine + shared mounts + FUSE | 可选 | Linux full stack |
| 通用 amd64 VPS | 官方目标架构 | 取决于 VPS 宿主虚拟化/权限 | 可选 | 原生 Docker；不能特权则复用外部媒体/Peach-only |
| x86-64 群晖/威联通/Unraid/绿联 | 官方目标架构 | 需检查 NAS Docker、ACL、挂载传播 | 可选 | 优先复用 NAS 上已有 CloudDrive2 或已有本地媒体 |
| fnOS x86-64 | 官方目标架构 | 官方提示 Docker 内 FUSE 有 namespace 限制 | 可选 | 优先 fnOS 原生 CloudDrive2 包；Peach 单独安装/复用挂载 |
| ARM64 NAS/树莓派 | **尚未官方 Docker 验收** | CloudDrive2 `arm64` tag 可用 | 视索引器镜像 | 默认停止 Peach Docker 自动安装；用户单独决定源码构建/验证 |
| ARMv7 Linux | **尚未官方 Docker 验收** | CloudDrive2 `arm32` tag 可用 | 不保证 | 同上，不承诺三容器方案 |
| Windows Docker Desktop amd64 | x86 Linux 容器可尝试，须单独验证 | 子挂载传播不可用 | 可选 | Peach-only + 稳定文件共享，或本机原生 Peach / 远程 Linux |
| macOS Docker Desktop Intel/Apple Silicon | Intel 条件可用；Apple Silicon 需评估仿真 | 子挂载传播不可用 | 可选 | 优先原生/远端 Linux；不使用 Linux FUSE Compose |
| 仅手机/平板 | 不属于该技能的 Docker 主机 | 不适用 | 不适用 | 作为 VPN/私网浏览器客户端 |

## 选路问答（机器自测优先）

1. **CPU 是 amd64 吗？** 不是则停止官方 Peach Docker 自动部署；CloudDrive2 的 ARM 支持不能证明 Peach ARM 支持。
2. **Docker 是真实 Linux Engine 吗？** 不是则不能用 FUSE bind mount propagation 模板。
3. **是否已经有媒体可读？** 如果有既存 CloudDrive2/本地目录/SMB，先复用，不重复建立一套特权 CD2。
4. **是否要求云下载？** 如果否，无需强制配置 CloudDrive2 token 和离线下载模块。
5. **从何处访问？** 仅本机可回环；远程优先 VPN/SSH 隧道；不能以“防止别人看到配置页”为理由开放 Peach 公网端口。
6. **是否有历史馆藏？** 有则先迁移计划和一致性备份，不自动重新初始化数据库。

## 几个容易混淆的兼容概念

- CloudDrive2 原生 Windows/macOS 程序存在，不代表其本机 FUSE 挂载可直接透传到 Docker Desktop 内 Peach。
- Docker 运行一个服务 ≠ 与宿主机共享新的子挂载；必须读真实测试文件并重启复验。
- 能通过网络访问另一台 NAS 的 CD2 API ≠ 另一台机器天然拥有 NAS 的 `/CloudNAS` 目录。媒体读取路径另行配置。
- `MEDIA_ROOT`、Peach 容器 `/media`、CloudDrive2 `/CloudNAS`、云盘服务路径各自不同，必须分别验证。
- 资源搜索、离线下载、媒体扫描是三个子系统；可以只安装必要部分。
