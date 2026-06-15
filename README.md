# Codex App LLM 节点配置（CopilotProxy）

把本地 **CopilotProxy** 配成 OpenAI **Codex**（桌面 App 与 CLI 共用）的模型后端，用你的 **GitHub Copilot 订阅** 驱动 Codex，绕开 ChatGPT 自带额度。

> 本文件夹是**日常运行的主目录**（自包含、可直接运行）。代理本体在 `CopilotProxy/` 子目录里，已 `bun install` 完依赖，可直接双击启动。
> 验证环境：Codex `0.140.0-alpha.2` · Windows 11 / zh-CN。

---

## 1. 这是什么 / 为什么

Codex App 顶部模型下拉框走的是 ChatGPT 账号额度。通过在 Codex 的用户级配置里把"模型 provider"指向本地代理 `http://localhost:4399`，Codex 的所有推理请求改由 GitHub Copilot 订阅服务，从而**绕开 ChatGPT 额度**。

- Codex App 和 CLI 是**同一个 `codex.exe` 引擎 + 同一份 `~/.codex/config.toml`**，配一次两边都生效。
- 已验证：App 用 `gpt-5.5` 正常对话；CLI 跑通对话 + agent 工具调用（建文件）；Claude（`claude-opus-4.8`）经代理也正常。

> ⚠️ CopilotProxy 是对 GitHub Copilot API 的逆向代理，非官方支持，注意用量与账号风控。

---

## 2. 文件清单

### 本文件夹（★ 日常运行主目录 — 自包含可运行）

```
codex-llm-node/
├── README.md                       # 本文档
├── config.sample.toml              # 要加进 ~/.codex/config.toml 的配置片段
├── scripts/
│   └── proxy.ps1                   # 代理助手脚本（status/start/test/models）
└── CopilotProxy/                   # ★ 代理本体（实际运行位置，已 bun install）
    ├── start-codex-proxy.bat       # 一键启动器引导壳（ASCII，双击入口）
    ├── start-codex-proxy.ps1       # 一键启动器主体（UTF-8 with BOM）
    ├── node_modules/               # 依赖（已安装，git 忽略，不进版本库）
    ├── src/                        # 代理源码（含 services/copilot/create-responses.ts 修复）
    ├── tests/  dist/  pages/       # 测试 / 构建产物 / 用量面板前端
    ├── package.json  bun.lock      # 依赖清单
    └── tsconfig.json  Dockerfile … # 其余工程文件
```

> `CopilotProxy/` 已 `bun install` 完依赖，**可直接双击 `start-codex-proxy.bat` 运行**，无需额外步骤。
> `node_modules/` 已被 git 忽略（不进版本库）；若哪天 node_modules 丢失，在该目录跑一次 `bun install` 即可重建。

### 配置与可选备份（本文件夹之外）

| 路径 | 作用 |
|---|---|
| `~/.codex/config.toml` | Codex 用户级配置（含 provider 指向）。**必需** |
| `~/.codex/config.toml.bak-before-copilot` | 改动前的备份 |
| 桌面快捷方式 `CopilotProxy (Codex).lnk` | 指向本文件夹的 start-codex-proxy.bat（可删，删后用下方命令行启动） |

> Windows 上 `~` 即 `%USERPROFILE%`（通常 `C:\Users\<你>`）。

### 相关 Skill

完整操作手册与可复用脚本已封装为技能，路径（相对仓库工作区）：

```
.claude/skills/codex-llm-node/
├── SKILL.md            # 完整配置 / 启动 / 换模型 / 看日志 / 排错手册
└── scripts/proxy.ps1   # 助手脚本（与本文件夹 scripts/proxy.ps1 一致）
```

说"配置 Codex 节点 / Codex 换模型 / 代理日志"等会自动激活该技能。

---

## 3. 快速开始

```powershell
# 1) 启动代理（二选一）
#    a. 双击  <本文件夹>/CopilotProxy/start-codex-proxy.bat
#       （或桌面快捷方式，若还留着）
#    b. 或命令行（先 cd 到本文件夹）：
cd ./CopilotProxy ; bun run src/main.ts start

# 2) 启动 / 重启 Codex App，照常使用即可
```

看到 `➜ Listening on: http://localhost:4399/` 即代理就绪。

---

## 4. 核心配置

在用户级 `~/.codex/config.toml` 顶部加入下面内容（完整片段见 `config.sample.toml`）。**只动用户级 config.toml**——`model_provider` / `model_providers` 在 project 级配置和 `--profile` 文件里会被忽略。

```toml
model = "gpt-5.5"
model_provider = "copilot-proxy"

[model_providers.copilot-proxy]
name = "CopilotProxy (GitHub Copilot)"
base_url = "http://localhost:4399/v1"
wire_api = "responses"
```

要点：

- `wire_api = "responses"` 是 0.140 自定义 provider **唯一支持**的值。
- provider **不需要** `env_key` / API key——代理不校验鉴权，自包含。
- 改完 `config.toml` 后**必须完全重启 Codex App**（多进程，全部退出再开）。
- 下拉框仍显示 ChatGPT 目录名（GPT-5.5 / GPT-5.4-Mini），但因为代理里也有这两个模型，每次选择都由 Copilot 服务。

---

## 5. 一键启动器

`start-codex-proxy.bat`（纯 ASCII 引导壳）调用 `start-codex-proxy.ps1`（UTF-8 with BOM，中文界面 + 逻辑）。双击 .bat 或桌面快捷方式即可。

- **保持窗口开启 = 代理运行中；关闭窗口 = 停止。**
- 已在运行时会提示"无需重复启动"，不会重复开。
- `bun` 不在 PATH 时自动补 `~/.bun/bin`。

> 编码注意（zh-CN 机器）：`.bat` 必须**纯 ASCII**（REM 行含中文会让 cmd 报"不是内部或外部命令"）；`.ps1` 必须存为 **UTF-8 with BOM**，否则 Windows PowerShell 5.1 按 GBK 解析导致中文乱码/语法错误。本文件夹副本已是正确编码。

---

## 6. 切换模型

代理暴露约 40 个模型（`Invoke-RestMethod http://localhost:4399/v1/models` 查全量）：

- **GPT**：`gpt-5.5`、`gpt-5.4`、`gpt-5.4-mini`、`gpt-5.3-codex`（原生 Codex 模型）
- **Claude**：`claude-opus-4.8/4.7/4.6`、`claude-sonnet-4.6/4.5`、`claude-haiku-4.5`
- **Gemini**：`gemini-3.1-pro-preview`、`gemini-3.5-flash`、`gemini-2.5-pro` 等

```powershell
# CLI 临时换：
& $codex -m claude-opus-4.8 ...

# App 永久换：改 config.toml 的 model 字段后完全重启 App
#   model = "claude-opus-4.8"
```

下拉框标签不会跟着变，但实际跑的是 `model` 字段。切到 Claude/Gemini 时代理自动在 Responses ↔ ChatCompletions 间翻译。

---

## 7. 看日志

| 方式 | 怎么做 |
|---|---|
| 前台实时（默认） | 保持 `bun run src/main.ts start` 窗口，逐行 `<-- POST /v1/responses / --> 200 8s` |
| 前台详细 | `bun run src/main.ts start --verbose`（模型名、工具数、payload 大小） |
| 存文件 | `bun run src/main.ts start --verbose *> D:\proxy.log` |

---

## 8. 排错

**`The requested tool image_generation is not supported`**
Codex 0.140 自动注入 `image_generation` 等托管工具，Copilot `/responses` 拒收，且无法用 `-c tools.image_generation=false` 关掉。已在代理侧修复：`src/services/copilot/create-responses.ts` 的 `stripUnsupportedResponsesTools()` 转发前剥离这些工具，保留 function/custom 工具。改代理源码后需重启代理。

**代理日志 `failed to refresh available models: missing field 'models'`**
无害。Codex 期望 `{models:[...]}`，代理返回 OpenAI 标准 `{data:[...]}`。不影响运行。

**`status` 总说 "Daemon is not running" / `stop` 杀不掉**
Windows 11 24H2+ 移除了 `wmic`，daemon 的 `status`/`stop`/`restart` 依赖它而失效。daemon 本身能正常服务。→ **本机用前台模式，别用 `start -d`**。手动停代理：

```powershell
$lp = (Get-NetTCPConnection -LocalPort 4399 -State Listen -EA SilentlyContinue).OwningProcess | Select -Unique
if ($lp) { Stop-Process -Id $lp -Force }
```

**App 仍显示"额度用尽"横幅**
那是 ChatGPT 账号状态展示，不代表没走代理。以代理日志的 `POST /v1/responses 200` 为准。

**改了 config.toml 没生效**
Codex App 仅启动时加载配置。完全退出所有 Codex 进程再重开。

---

## 9. 回滚

```powershell
# 方式一：注释掉 config.toml 里的 model_provider 行 → 重启 App
# 方式二：恢复备份
Copy-Item "$env:USERPROFILE\.codex\config.toml.bak-before-copilot" "$env:USERPROFILE\.codex\config.toml" -Force
```

---

## 10. 验证记录（2026-06-14）

- 代理 `/v1/responses` + `gpt-5.3-codex` → `PROXY_OK`
- Codex CLI 经代理：对话 + agent shell 工具调用（建文件）均通过
- Claude `claude-opus-4.8` 经 `/v1/responses` → `CLAUDE_OK`
- App 实测：用 `gpt-5.5` 正常调用；verbose 日志确认 `Stripped N unsupported hosted tool(s)` 修复生效
- 一键启动器：中文界面无乱码、模型列表正常、`Listening on http://localhost:4399` 成功
- 助手脚本 `proxy.ps1`：`status` → 40 模型可用，`test` → `PROXY_OK`
