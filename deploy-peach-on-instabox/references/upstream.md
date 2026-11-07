# 官方参考与核验清单

> 本清单在 2026-11-08 编写。未来每次运行仍应检查官方现行文档，不把链接或接口说明当作永远稳定。

## Peach

- 仓库：https://github.com/peach-mitao/peach
- Docker 部署、版本与 CPU 支持：https://github.com/peach-mitao/peach/blob/master/docs/DOCKER.md
- 官方 Compose（`rslave` + 只读媒体）：https://github.com/peach-mitao/peach/blob/master/compose.yaml
- 安全说明（不直接对公网发布）：https://github.com/peach-mitao/peach/blob/master/SECURITY.md
- CloudDrive2 API：https://github.com/peach-mitao/peach/blob/master/docs/CLOUDDRIVE_API.md
- Torznab 资源搜索：https://github.com/peach-mitao/peach/blob/master/docs/RESOURCE_SEARCH.md
- 配置、迁移与路径映射：https://github.com/peach-mitao/peach/blob/master/docs/OPERATIONS.md

每次确认：Peach 是否仍仅发布 linux/amd64；首次登录是本机 token 还是旧初始化 UI；数据库有无迁移步骤；`/healthz?ready=1` 是否可用；是否允许 LAN/回环配置；是否改变接口/字段。

## CloudDrive2

- 官方 Docker 指南：https://www.clouddrive2.com/en/docker.html
- 平台/架构/原生安装：https://www.clouddrive2.com/en/apps/desktop.html
- 常见问题（含 fnOS namespace）：https://www.clouddrive2.com/en/help.html
- 官方产品/API：https://www.clouddrive2.com/en/

每次确认：镜像的 `amd64`、`arm64`、`arm32` tag 仍存在；宿主机 shared propagation 及 FUSE 权限；是否真正需要 `pid: host` 与特权；bridge 网络在该目标机上是否可用；CloudDrive2 的令牌、云目录权限与会员特性有否变更。

## Docker

- Bind mounts / propagation / Docker Desktop 限制：https://docs.docker.com/engine/storage/bind-mounts/
- Docker Compose 文件规范：https://docs.docker.com/reference/compose-file/

每次确认：Compose 是否支持 `bind.propagation`、`create_host_path`、profiles；目标 NAS Docker 版本与端口绑定行为；实际宿主机和 Docker daemon 是否为同一架构/主机。

## InstaBox

- https://instabox.sh/docs
- https://instabox.sh/docs/limits
- https://instabox.sh/docs/api
- https://instabox.sh/docs/api/commands
- https://instabox.sh/docs/idle-suspend
- https://instabox.sh/docs/ports

每次确认：API 认证、exec `cmd`/`argv`、Idempotency-Key、平台可用的私有端口转发、持久数据卷、免费/付费机器的空闲与最大连续运行时间；不可依赖一次 120 分钟实测。
