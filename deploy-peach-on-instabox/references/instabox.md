# InstaBox 专用适配（v2）

原始现场记录在 `field-notes-v1.md`，本页优先使用当前 InstaBox 官方文档，不将一次实验结论扩大成普遍规则。

## 持久化与资源

- InstaBox 文档注明持久数据卷默认在 `/data`，常见 home 为 `/data/home`；系统根盘属于模板环境，不要将 Peach DB / CloudDrive2 Config / Jackett Config 放在可能重建的根盘。
- 免费机器默认 20 GiB 持久盘（以账户实际配额/模板为准）；媒体使用云端或外部媒体路径，必须估算 Peach 的缩略图缓存、数据库、镜像与日志占用。
- 免费计划空闲暂停为 30 分钟，官方限制可包含连续运行上限及冷却；不要把 v1 “运行超过 120 分钟”写成无上限，也不要承诺重启后即恢复运行。
- 机器启动/暂停/恢复、端口发布等操作先查询当前状态、用户权限与现有部署。不要为部署新栈直接覆盖其他工作负载；仅在用户同意时创建新机/第二账户。

## API / CLI 兼容

- API 基址 `https://api.instabox.sh`，通过 `X-API-Key` 认证（key 不进聊天、记忆、日志与 Skill）。对 key 的 401 错误先诊断有效性，不能绕过授权。
- exec 请求体支持 `cmd`（shell 字符串）或 `argv`（参数数组），**两者只能选一个**；不是 `command`。
- 生命周期、创建、端口等变更 API 的 `Idempotency-Key` 要按实时 API 契约发送；参数变化或重试需避免重复资源。
- 有 CLI/端口转发能力时优先经过授权的私有访问，如 `instabox port-forward <machine> 8900`（确切语法与行为以当前官方帮助为准）。SSH 隧道也由用户在自己设备上执行并保管令牌。
- 默认示例 Compose 的 Peach host 端口为 `127.0.0.1:8900`，可供本机或受支持的私有转发。**不要为获取日常公网 URL 自动发布 Peach 公共端口**，官方 Peach 安全文档明确不建议直接公网访问。
- 旧案例中 agent API 部署 CloudDrive2 由于特权 FUSE 规则被拦：对同类型限制应遵守拒绝，不反复绕过。若当前平台改变策略，仍需新部署的明确用户批准和权限检查。

## 操作分工

| 事项 | 代理（有实际权限才执行） | 用户 |
|---|---|---|
| 只读环境查询 | API/CLI/工具输出分析 | 必要时提供设备访问 |
| 配置与脚本 | 生成、静态验证 Compose | 确认路径、端口与备份位置 |
| 特权 CloudDrive2 | 解释所需权限和风险，不擅自启动 | 明确授权并在自己的 SSH 环境执行敏感步骤 |
| CloudDrive2/115 登录 | 不收集账号密码/令牌 | 自行在官方 UI 登录/创建 token |
| Peach token | 告知本机查询方法，避免回显进聊天 | 在目标机/SSH 私有窗口内使用 |
| 验收 | 非敏感健康与只读日志、任务状态 | 私网 UI 验证、真实云端访问 |

## 旧案例里值得沿用的精准经验

- Peach `/media` 看不到 CloudDrive2 后续挂载，不是只看宿主机 `ls`，必须看 bind propagation、重建与容器内部读取。
- CloudDrive2 token 的根目录权限可能引发“目录不存在”；核查 root、API 版本和云端目录再建议重建。
- 资源搜索 0 个候选先看 Jackett 日志和对照测试，不要先重配网络。
- CloudDrive2 有独立容器网络时，Peach 里的 `127.0.0.1` 不指向 CD2；本包在同一 Compose 网络内使用服务名。
- 已有个人 NAS 的 CD2 与云端 InstaBox 上的 CD2 是两个安装，各自有挂载、配置、缓存、凭据。

## 官方参考

- https://instabox.sh/docs
- https://instabox.sh/docs/limits
- https://instabox.sh/docs/api
- https://instabox.sh/docs/idle-suspend
- https://instabox.sh/docs/api/commands
- https://instabox.sh/docs/ports
