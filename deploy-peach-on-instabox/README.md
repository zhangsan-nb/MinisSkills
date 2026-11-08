# deploy_peach_on_instabox v2.0.0

一个从用户原有 InstaBox 现场 Skill 升级而来的**跨设备兼容部署 Skill**，保留技能名 `deploy_peach_on_instabox`。核心原则：先识别设备、CPU、Docker、现有数据与 FUSE 能力，再选择 Linux 完整栈、复用现有 NAS 服务或 Peach-only 模板。**这不是对所有设备的一键通用安装器。**

## 下载与导入

- 通常将整个 `deploy_peach_on_instabox_v2/` 文件夹或 ZIP 包导入支持目录型 Skill 的工具；根入口是 `SKILL.md`。
- 如果你的自定义技能库仅允许单文件上传，请先上传单独的 `SKILL.md`，但模板和脚本不会自动随单文件一起导入；请同时保存本 ZIP 并在使用时提供辅助文件。
- 自定义技能库存储方式因产品而异；**仅生成文件并不代表已经自动同步到技能库**。

## 设备支持简表

- **优先**：InstaBox amd64、Debian/Ubuntu amd64、原生 Docker 的 amd64 VPS、能够提供稳定 FUSE 或已有媒体挂载的 amd64 NAS。
- **条件适用**：fnOS（优先原生 CloudDrive2）、其他 Linux NAS（检查 ACL / 系统权限）、Windows/macOS Docker Desktop（只运行 Peach-only 或改用远端 Linux/原生方案）。
- **不自动安装**：ARM NAS/树莓派的 Peach Docker；Peach 官方 ARM 镜像尚未验收。Docker Desktop 的动态 CloudDrive2 FUSE bind propagation。

## 在新的 Linux amd64 主机上使用

**0.** 先看 `SKILL.md` 的安全、备份与平台选路规范；**不要跳过用户批准 CloudDrive2 特权容器的步骤**。

**1.** 将包复制到目标机。先运行只读检查（替换绝对路径）：

```bash
bash scripts/preflight.sh linux-fuse /srv/peach-stack/media
```

**2.** 选取 `templates/compose.linux-fuse.yml`，复制 `.env.linux.example` 为一个独立的 `.env`；调整所有路径、端口、权限和镜像标签。InstaBox 选择 `.env.instabox.example` 并确保 `/data` 路径。

**3.** 创建**新的空目录**并按目标机文件权限准备，保证 `PEACH_DATA_ROOT` 对容器 UID 1000 可写，媒体目录可读，CloudDrive2/Jackett 配置持久；已有数据先备份，不能盲目 `chown -R`。

**4.** 假设将 `.env` 放在包目录且继续使用模板路径，验证：

```bash
docker compose --env-file .env -f templates/compose.linux-fuse.yml config --quiet
```

**5.** 若选择新建 CloudDrive2，先获取用户对特权容器的明确批准；在实际 Linux 宿主机确认 `/dev/fuse`、shared 传播及管理端口隔离后，按需启动：

```bash
docker compose --env-file .env -f templates/compose.linux-fuse.yml --profile clouddrive up -d clouddrive2
```

如需 Jackett 才执行：

```bash
docker compose --env-file .env -f templates/compose.linux-fuse.yml --profile indexer up -d jackett
```

**6.** 用户在 CloudDrive2 界面登录自己的云盘并建立目标挂载，先在宿主机验证，然后启动 Peach：

```bash
docker compose --env-file .env -f templates/compose.linux-fuse.yml up -d peach
```

**7.** 从容器执行只读检查；将第三个参数替换为真实媒体根下、用户有权读取的相对文件路径：

```bash
bash scripts/verify.sh templates/compose.linux-fuse.yml .env '云下载/测试文件.mp4'
```

脚本只验证基础健康及选定文件可读；下载任务、网络安全、索引器搜索和重启恢复仍必须分别人工/授权验收。

## Peach-only 模式

无 CloudDrive2 FUSE 子挂载要求时，改为 `templates/compose.peach-only.yml` + `.env.peach-only.example`。它不执行 Linux 传播设置；适合稳定本地目录、Peach 内置 SMB 媒体源或目标机无法使用 FUSE 的情形。Docker Desktop 的具体路径格式取决于共享盘设置，先按官方文档核对；不能直接照搬 Linux `/srv/...` 路径。

## 特别重要的安全事项

Peach 官方不建议直接在公网发布。默认端口映射均绑定 `127.0.0.1`，远端访问请走 SSH 隧道或 VPN；配置管理员密码不等于允许公网。切勿把任何登录口令或 API key 写入聊天或 Skill 文件。

## 文件清单

- `SKILL.md`：核心执行规范、兼容路由、诊断、验收
- `templates/`：Linux 完整栈、Peach-only 与环境变量示例
- `scripts/preflight.sh`：只读平台检测
- `scripts/verify.sh`：只读容器/媒体检测
- `references/`：平台兼容矩阵、InstaBox 细节、安全备份、故障诊断、官方资料、原 v1 全文存档
- `CHANGELOG.md`：升级差异与限制

**注意**：模板通过本地语法检查不等于已在你的目标设备上部署。尤其 ARM、Docker Desktop、特殊 NAS、CloudDrive2 权限、下载通道只能在相应设备做真实验收。