---
name: deploy_peach_on_instabox
version: "2.0.0"
description: >
  Deploy, verify, repair, migrate or upgrade Peach with optional CloudDrive2
  and Jackett/Prowlarr. Detect InstaBox, Linux VPS and NAS environments first;
  select platform-specific routes and stop rather than guess when unsupported.
---

# deploy_peach_on_instabox v2 — 跨设备兼容部署

> **目标**：保留 InstaBox 成功案例，同时兼容符合条件的 Linux 主机、VPS、NAS，以及部分 Windows/macOS 场景。兼容是“探测后选路”，不是一套命令通吃。禁止从一次部署结果推导其他机器的权限、路径或服务行为。
>
> **状态**：2026-11-08 编写的可复用运行规范及示例配置；不是已在所有设备上完成测试的安装器。执行前重新检查上游文档与目标环境。历史经验见 `references/field-notes-v1.md`，它不覆盖本文件的安全约束。

## 0. 严格规则

1. **先探测再行动**：对机器、现存数据、CPU 架构、Docker Engine、可用权限、磁盘、端口、网络和 FUSE 进行只读检查；不得自动删除、重置或覆盖已有部署。
2. **用户拥有账号和凭据**：登录 CloudDrive2/115、创建 API 令牌、审批特权容器、执行敏感 SSH 操作由用户控制。代理有可用工具时负责准备配置与非敏感检查，不假定拥有 API/SSH 权限。
3. **不在聊天里交换密钥**：不得要求用户粘贴 InstaBox API key、Jackett key、CloudDrive2 token 或 Peach 登录口令到聊天中；敏感配置只存目标机器上受控文件/密钥存储（限制访问权限），诊断输出须打码。
4. **Peach 默认只接受本机/私有网络访问**：不要把 Peach 直接暴露到公网，包括普通端口映射与逆向代理；优先 VPN 或 SSH/受控端口转发。CloudDrive2/Jackett 管理端口默认绑定回环。不要通过伪造来源或清除代理头绕过 Peach 的本地管理门。
5. **CloudDrive2 特权单独授权**：`privileged: true`、`pid: host`、`/dev/fuse` 权限敏感；未获用户明确批准前不启动。若目标平台禁止，则停止该路线，选择已存在的挂载、SMB 或替代方案；不循环重试、不过权绕过。
6. **不自动清除数据**：禁止无审批的 `docker compose down -v`、`docker volume rm`、删除 `/data`/Peach 数据库、修改已存在媒体根、覆盖 `config.toml`；修改前一致性备份、校验配置、记录回滚点。
7. **版本和事实优先级**：目标机现状 + 当前官方文档 > 历史案例。原 v1 的“某个 403/无结果/启动失败必然只有一个原因”降格为排查线索。
8. **遵守合法用途和资源站点规则**：搜索与下载只限用户有权访问的资源；索引器是否可用依站点规则而异，不保证任何具体站点、内容或会员服务。

## 1. 环境探测与能力分级

### 1.1 先拿到最小环境报告

- 目标：InstaBox / 自建 Linux / VPS / Linux NAS / Windows 或 macOS / 其他；部署位置与用户日常访问位置要分开。
- 系统、CPU 架构、是否为真实 Linux Docker Engine 或 Docker Desktop；`uname -m`、`docker info` 和 `docker compose version`；网络与端口冲突。
- 是否已经运行 Peach / CloudDrive2 / Jackett/Prowlarr；检查容器、卷、目录、镜像标签、现有数据与迁移风险。
- 宿主机持久化路径、空闲空间与 inode、重启策略；InstaBox 必须优先使用 `/data`，不要把可丢失根文件系统当持久卷。
- CloudDrive2 路线时检查 `/dev/fuse`、目标目录的 `findmnt -o TARGET,PROPAGATION`、Docker 是否允许特权、宿主机架构；目录必须预先存在。
- 检查网络暴露：Peach 是否在公网，CloudDrive2/Jackett 管理端口是否只开放到回环或私有网；检测备份是否存在，但不输出机密。
- 可在**目标 Linux 宿主机**执行 `scripts/preflight.sh linux-fuse /absolute/media/path` 做只读检测；此脚本不代替实际镜像可用性和业务验收。

### 1.2 选择路线（不能跳过）

| 环境 | 默认路线 | 决策边界 |
|---|---|---|
| InstaBox，Linux amd64 | `templates/compose.linux-fuse.yml` + `references/instabox.md` | 先确认平台特权策略、`/data` 持久性与私有访问；CloudDrive2 需用户许可 |
| Ubuntu/Debian 等 Linux amd64 | `compose.linux-fuse.yml` | 宿主机真实 FUSE + mount propagation 可用时支持完整三容器方案 |
| Linux x86-64 NAS（群晖/威联通/绿联/Unraid 等） | 先复用 NAS 的 CloudDrive2；或 FUSE 路线 | NAS Docker 权限、文件 ACL、挂载传播必须实测，第三方套件不作安全保证 |
| 飞牛 fnOS | 优先原生 CloudDrive2 包 + Linux Peach 运行时 | CloudDrive2 官方提示容器内 FUSE 可能因 namespace 限制失败；勿默认强装 Docker CD2 |
| ARM64/ARMv7 NAS 或树莓派 | **阻断自动 Peach Docker 部署** | CloudDrive2 有 ARM 镜像，但 Peach 官方 Docker 仅以 linux/amd64 为目标，ARM 未验收。可在用户选择下尝试源码构建并单独验收；不自动仿真 |
| Windows/macOS Docker Desktop | `compose.peach-only.yml`，且仅在镜像架构兼容时 | Docker Desktop 不支持 Linux bind mount propagation；不能承诺 Docker CD2 FUSE 子挂载透传。优先本机原生版本/已有 SMB 媒体源或远端 Linux 主机 |
| 非 Docker / 无权限容器环境 | 原生/远端服务路线 | 依据当前 Peach 官方文档确认支持情况，不能套用本包 Compose |

仅有手机/平板作为客户端时，不在手机上运行本套三容器；通过私有网络浏览器访问部署在服务器/NAS 的 Peach。

## 2. 选择模块，保持路径与地址分离

- **P（Peach）必选**：`/data` 容器目录持久化，`/media` 从宿主机媒体根只读绑定；Peach 非特权、默认只绑定 127.0.0.1 的宿主机 8900 端口。
- **C（CloudDrive2）可选**：若本机已有 CD2 与可用挂载，优先复用，不重复创建实例。新建时，CD2 `/CloudNAS` 宿主机挂载需要 `rshared`；Peach 只需只读 `rslave` 接收宿主子挂载。严格区分容器内 `/media`、宿主 `MEDIA_ROOT`、云端 `/115open/云下载`。两者一致性须实测。
- **J（Jackett/Prowlarr）可选**：已有可达服务直接复用；新建 Jackett 内网使用 `http://jackett:9117`。Torznab URL 去除查询参数，API key 单独保存。
- **D（下载通道）可选**：CloudDrive2 支持的账号、权限、目录与离线任务能力逐项验证。索引器搜索成功不等于下载通道成功。
- **访问方式**：回环/SSH 隧道、局域网绑定或 VPN 由目标设备和用户需求决定；不得默认公网 URL。

### Compose 模板使用边界

- `templates/compose.linux-fuse.yml`：单机原生 Linux，带可选 `clouddrive` 与 `indexer` profile。CD2 特权服务未批准前不能启动。
- `templates/compose.peach-only.yml`：无 CD2 子挂载要求的场景，包括已有稳定媒体目录/独立 SMB 源，适合 Docker Desktop 的**条件部署**；其本地媒体绑定不能保证动态 FUSE 传播。
- `.env.*.example` 仅为变量样例。创建 `.env` 后先按目标设备改绝对路径与端口，记录镜像版本，创建目录并检查 UID1000/ACL 权限。**现有目录先备份，不能盲目 chown -R**。
- 两种模板是示例，不替代官方 Compose；必须在目标机器上 `docker compose ... config --quiet` 验证。镜像兼容性通过镜像仓库和实际拉取确认。

## 3. 执行顺序（每步有停止条件）

1. **Discover（只读）**：产出设备类型、架构、能力、既有服务、持久路径、网络拓扑和安全风险；不询问已知信息。
2. **Plan（逐项报备）**：选择 P/C/J/D 模块；标明必须用户操作的凭据、特权批准、可能停机、数据路径迁移；先解决是否支持 ARM、FUSE、网络安全等阻断项。
3. **Backup（必要）**：对已存在 Peach 采用停写或一致性 SQLite 备份，备份配置、数据卷、CloudDrive2 配置和索引器设置；密钥备份必须加密。记录镜像版本、Compose、`.env` 非敏感字段和回退步骤。见 `references/security-backup.md`。
4. **Prepare**：创建所需**新**目录；保证媒体根实际存在且对 Peach UID1000 可读，数据根可写；CloudDrive2 需在实际 Linux 宿主机确认 shared 传播与 `/dev/fuse`，未经允许不改变宿主级 mount/systemd 配置。
5. **Start optional components**：如获授权，先启动 CloudDrive2 / Jackett，验证各自管理端口与容器网络。CloudDrive2 由用户在其界面登录、建立目标云目录的挂载；如果复用现有 NAS 挂载，跳过新增容器。
6. **Mount acceptance**：从**宿主机和 Peach 容器内**验证同一非机密真实媒体文件的可见性与读取；如果 Peach 尚未启动，挂载成功后再启动 Peach 验证。不能仅靠目录存在或 host `ls` 宣告成功。
7. **Start Peach**：先对目标 Compose 运行 `config --quiet`，然后 `up -d peach`；使用 `http://127.0.0.1:8900/healthz?ready=1` 从容器/本机测试就绪，确认无数据库迁移阻断。
8. **First login / configuration**：遵循部署版本官方路径。较新 Docker 文档使用 `docker compose exec peach peach token` 得到本机登录口令；不要将其输出到聊天中。部分旧版首次设置和配置页有本地管理门，使用用户 SSH 隧道/私有网络，禁止构造绕行代理。`PEACH_ACCESS_PASSWORD` 只负责密码预设，不代表绕过管理门。
9. **Library**：通过受允许的本地/私有入口设置 `/media/<子目录>`，媒体来源与重定位策略；现有馆藏保留数据库路径前缀，避免重扫造成映射断裂；第一次索引要查看任务、资产计数和实际文件访问。
10. **Download channel**：从 Peach 所在容器到 CloudDrive2 API 实测可达；本包共用 Docker 网络时示例为 `http://clouddrive2:19798`，复用外部 CD2 时必须改为实际私网地址。令牌通过用户 UI 创建、按所需权限最小化；历史案例的 token root `/` 和下载目录关系仅作为该云盘/版本的检查项，不能盲目套用其他服务。保存目录前缀关联，必要时采用扫描代替付费 webhook。
11. **Indexer**：用户在 Jackett/Prowlarr 中配置合规站点并测试，Peach 使用容器可达的 Torznab 地址，移除 URL 上的 key/query；控制样本在索引器和 Peach 两边测试；0 个结果先查日志、源站和对照样本，不立即改网络。
12. **Acceptance**：逐项记录 P/C/J/D 的 PASS / FAIL / NOT_APPLICABLE / NOT_TESTED，不允许把容器运行视为业务完成。查看 `references/troubleshooting.md`。
13. **Recovery readiness**：记录当前镜像 digest/tag、Compose 内容摘要、状态文件位置、备份位置（不在聊天输出敏感路径/令牌）、恢复演练及重启后复验流程。

## 4. P/C/J/D 验收必须可观察

- **P**：Peach `/healthz?ready=1` 成功；有权限登录/配置；数据库健康，重启后配置依旧；未意外暴露公网。
- **C**：CloudDrive2 可管理；授权的目标云目录已挂载；宿主机和 Peach 容器内对同一实际媒体文件读取成功；重启后仍可访问。
- **J**：从 Peach 容器能访问 Torznab caps/搜索 API；索引器里手动可搜索；Peach 界面能展示合法测试资源结果；Jackett/Prowlarr 认证成功。
- **D**：Peach 下载通道权限和云端目标目录检查通过；真实、合法的测试下载任务达到云端完成/本地入库相应状态，若测试未执行必须标记 NOT_TESTED。
- **恢复性**：停机/恢复后挂载、服务与数据一致；实际备份经过可恢复性检查而不只是有文件。

## 5. 故障诊断按证据，而非单一症状定论

| 现象 | 首先排查 | 才考虑修改 |
|---|---|---|
| 公网入口配置页 403 | Peach 版本、路径、响应、来源地址和安全策略 | 用本地/私网入口；绝不修改代理头绕过 |
| CD2 宿主机可见、Peach `/media` 空 | 真实子挂载、传播方向、Peach 启动顺序、文件权限、Docker Desktop | Linux 上检查 CD2 `rshared` + Peach `rslave`，必要时有备份地 recreate |
| FUSE `Operation not permitted` | `/dev/fuse`、真实 Linux、权限与平台限制、fnOS namespace | 获授权后选择官方支持路线，受阻停止而非循环提权 |
| Peach 连不到 CloudDrive2 | 服务自身健康、Docker DNS、共享网络、实际地址 | 修正服务名或远端私网地址，不填容器内 127.0.0.1 |
| CD2 token “路径不存在” | token 根路径、权限、目标目录、API 版本 | 必要时用户重建 root `/` token，仅赋所需权限 |
| 库扫描报限流失败 | 后端已有记录数、具体失败项、日志与任务状态 | 按限流策略补跑，避免反复整体重配 |
| 搜索 0 结果 | 索引器日志、控制查询、源站是否有资源 | 再排查 feed、URL、apikey 或网络 |
| 机器停止/失联 | 设备电源、休眠、平台冷却/配额、磁盘 | 按厂商规则恢复；不承诺云机常驻 |

## 6. 平台专用适配

- **InstaBox**：读 `references/instabox.md`；仅 `/data` 可靠持久；使用其当前受支持的 API/CLI，`exec` 用 `cmd` 或 `argv`；尊重 idempotency/lifecycle/配额；绝不假设云端代理能经 SSH、也绝不把 v1 的 120 分钟实测当当前配额。
- **Linux 主机/VPS**：选择真实 Docker Engine + 私有网络访问，宿主机 FUSE propagation 检查；公网 VPS 不对 Peach、CD2、Jackett 直接发布管理端口。
- **NAS**：优先利用已有可读本地媒体、SMB、CloudDrive2 原生包/容器；检查应用商店兼容、ACL、实际处理器。fnOS 参见平台表。
- **Windows/macOS**：不要运行 Linux FUSE 模板。若使用 Docker Desktop 的 Peach-only，须验证 amd64 镜像能运行、映射目录持久性与权限。云挂载等高级功能若不可达，改用已验证的 SMB/远端 Linux 路线。

## 7. 切换设备和迁移

- 明确是“**新装**”还是“**迁移**”。不同机器上的 CloudDrive2 不是同一实例；已有 NAS 盘挂载不能自动变成云端 VPS 的目录。
- 迁移 Peach 先停写并备份完整 `/data`，核对镜像/数据库迁移版本，**只有一台 Peach 可以写同一份数据库**。
- 保留数据库 `[media.locations]` 旧逻辑路径前缀；只调整实际 `[media.mounts]`、Compose 媒体挂载及源地址。不得把数据库中的 Windows 风格逻辑路径当作 Linux 实际文件路径。
- 数据迁移完成后验证 SQLite 一致性、资源计数、真实文件读取、登录和下载/搜索设置；不允许只因界面能打开就宣布迁移成功。

## 8. 配套文档与模板

- `README.md`：部署选择和开始步骤
- `templates/compose.linux-fuse.yml`：Linux 完整栈（可选 CloudDrive2/Jackett）
- `templates/compose.peach-only.yml`：不依赖子挂载传播的 Peach
- `templates/.env.*.example`：分平台变量样例；不含密钥
- `scripts/preflight.sh`：只读环境检测
- `scripts/verify.sh`：只读容器、应用和媒体读取验证（需真实目标设备）
- `references/platform-matrix.md`：设备与架构细化决策
- `references/instabox.md`：InstaBox API、持久化、休眠和分工
- `references/security-backup.md`：公网边界、备份、更新、回滚
- `references/troubleshooting.md`：保留 v1 经验并改写为证据驱动诊断
- `references/field-notes-v1.md`：原始现场记录，留档不作自动执行指令
- `references/upstream.md`：官方文档与重新核验清单

## 9. 最终汇报格式

只报告：**目标环境与 CPU / 选定路线 / 已执行和需用户执行的操作 / P-C-J-D 验收状态 / 实际访问方式 / 备份与回滚准备 / 未验证限制**。绝不输出密钥、CloudDrive2 账号、Peach token、SSH 凭据或完整含密钥 URL。未实际执行就写“模板已准备，目标设备未验证”，不能宣称已经部署成功。