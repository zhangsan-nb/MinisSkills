# Changelog

## v2.0.0 — 2026-11-08

**从 v1 继承**：InstaBox API exec 的 `cmd` 字段、`/data` 持久化、用户 SSH 完成敏感操作；Peach 配置本地门；CloudDrive2 FUSE 受限案例、网络可达/挂载传播/媒体扫描/下载入库/Jackett 对照测试的实操经验。原文完整保存在 `references/field-notes-v1.md`。

**新增**：兼容环境分级、amd64 镜像检查、Docker Desktop/ARM 阻断、InstaBox 与 Linux/NAS 路由、可选 P/C/J/D 模块、模板 `.env`、只读检测脚本、验收状态、备份迁移和回滚流程、敏感凭据防泄露规则。

**纠偏**：Peach 的媒体挂载改为 `rslave + read_only`；CloudDrive2 用 `rshared`；默认不公开 Peach 端口；不依赖固定公网 URL、不再假设 Docker Desktop 支持子挂载传播；不将旧版首次安装 UI 视为唯一流程；不将历史 120 分钟样本当作当前运行上限；不自动声明 ARM Peach Docker 可运行；镜像 `edge/latest` 必须在生产更新时锁定版本和备份。

**已知限制**：本包是可复用模板，未连接用户的 InstaBox、NAS、VPS；无真实网络/账号/媒体测试记录。CloudDrive2 使用官方支持的特权 FUSE 方案，但采用 bridge 网络以限制管理端口暴露，必须在目标机验证；如需切换官方 host network 路线，先审查防火墙和 Peach 的 CloudDrive API 地址，不能自动切换。某些 NAS 的 Docker 实现可能拒绝特权/FUSE。