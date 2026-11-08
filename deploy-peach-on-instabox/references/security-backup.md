# 安全、备份、更新、迁移与回滚

## 网络与访问

- Peach 官方明确不建议把单用户服务经公网端口映射或反向代理公开：缺少审计日志与第二因素认证，密码不等于可靠公网边界。
- 宿主机默认 `PEACH_BIND=127.0.0.1`；远程使用 SSH 隧道/私有 VPN。LAN 访问需用户明确接受和设置访问密码，绑定目标 LAN IP 而非盲目 `0.0.0.0`。
- CloudDrive2 与 Jackett 管理端口仅绑定回环；有管理需求时用本机/SSH 隧道。容器 API 内网地址仅供服务之间使用，避免暴露密钥。
- SSH/CLI 和 Token 由用户自行掌握；不要打印 `docker inspect` 的完整 Env、Peach token 内容、包含 apikey 的 Torznab URL，或将密钥存入 Git、记忆、日志和技能包。

## 特权 CloudDrive2

- 仅在用户明确授权并确认是可信 Linux 宿主机时使用 `privileged: true` + `pid: host` + `/dev/fuse`；这些权限会显著扩大容器对宿主机的影响。
- 不要为了修复 CD2 而擅自执行 `mount --make-shared`、修改 systemd Docker 服务或关闭 SELinux/AppArmor；这属于主机级变更，需备份、停机评估和用户批准。
- 源文档的 host network 不是安全隔离默认配置。本包 bridge 路线不能保证适用所有 NAS；换成 host network 时 19798 绑定行为和服务间地址必须重评估。

## 什么必须备份

- Peach 完整 `/data`（含 SQLite 数据库、配置、缓存及秘密）；仅备份 `ledger.db` 不够，配置与 secrets 也必须对应。备份即包含登录凭据，必须加密存储。
- CloudDrive2 `/Config`：用于保留账户和挂载配置；备份内可能含敏感认证信息，不得上传聊天。
- Jackett `/config` 或 Prowlarr 配置：含站点设置/API key，备份必须保密。
- 运行清单：镜像版本 tag **及 digest**、Compose、部署环境变量（剔除机密）、实际宿主挂载路径、端口、机器架构与恢复说明。
- 不必把云端全部媒体复制进小容量 VPS 备份，但必须确认云端数据独立保留、可重新连接。

## 升级前检查清单

1. 明确升级对象（Peach / CloudDrive2 / Jackett），查当前官方 release / 迁移说明与架构支持；版本稳定时固定 tag/digest，别无条件拉 `edge/latest`。
2. 盘点数据库正在写入/扫描/下载任务；进入维护状态，必要时停 Peach 以取得一致性备份。若使用在线 SQLite backup API，必须确保其是完整可恢复快照。
3. 将完整数据和配置**加密**复制到原机器以外的安全位置；记录文件大小/校验值，至少验证一次可读/可解压。
4. 保存旧 Compose 与镜像 digest，再运行 `docker compose config --quiet`；仅在用户批准停机窗口后执行升级。
5. 升级后检查 `/healthz?ready=1`、用户登录、媒体真实读、扫描、云端下载、Torznab 搜索和重启恢复。

## 回滚与恢复边界

- 回滚**不仅**是把镜像 tag 改回去。若新版本升级了 SQLite schema，旧镜像可能无法读取新数据库；需要恢复与旧版配套的完整数据快照。
- **禁止**将生产数据库从两台 Peach 服务器同时挂载写入。迁移时先停旧实例，复制数据，再启动新实例。
- 保留 Peach 数据库的原逻辑路径前缀 `[media.locations]`，只调整新设备的 `[media.mounts]` 和媒体绑定。界面可开不代表历史媒体路径正确。
- 回滚成功标准：服务恢复、数据库校验、真实文件能读取、用户可登录、备份内容恢复、无意外外网端口。

## 最小权限目录建议

- Peach 容器以 UID/GID 1000 运行；全新数据目录应使 1000 可写，媒体读/遍历权限充分即可；避免对现有 NAS 目录执行不审查的递归 chown。
- 可将 Peach 媒体 bind 标为 `read_only: true`；如果需要整理/移动/删除媒体，必须单独批准写权限和确认云盘写入行为。
- `.env` 文件建议仅包含非敏感参数；密钥使用用户在官方 UI 或目标机本地机密存储管理。
