# Dynamic Task List — Codex LLM 节点（CopilotProxy）

> 这个文件由 dynamic-task-list skill 维护。
> 每次开发任务前/后，agent 都会读取并更新此文件。
> CEO 可以直接编辑此文件（agent 下次会读到）。

**Last updated**: 2026-06-14 by agent（本次会话完成 Codex 节点配置 + 集中化 + 提升为主运行目录）

---

## 🚧 In Progress (max 1-2 items)

- （无）核心目标已全部达成，Codex App/CLI 已稳定经 CopilotProxy 走 Copilot 订阅。

---

## 🔴 P0 — Now (this week)

- （无）

---

## 🟡 P1 — Next (next 1-2 weeks)

- [ ] 让 App 下拉框能直接选 Claude / gpt-5.3-codex — 研究自定义 `model_catalog_json`（schema 无官方文档，需先验证）
- [ ] 修复 daemon 生命周期在 Win11 24H2+ 失效 — `src/daemon/pid.ts` 把 `wmic` 换成 `Get-CimInstance`，恢复 `status`/`stop`/`restart`

---

## 🔵 P2 — Later

- [ ] 把 `/v1/models` 返回体补成 `{models:[...]}` 形状 — 消除 Codex `failed to refresh available models` 的无害告警
- [ ] 把 codex-llm-node 接入 skill-map / 项目索引，便于发现
- [ ] 评估是否做成开机自启服务（当前结论：前台手动启动已够用，不做）

---

## 🔧 Tech Debt

- [ ] 上游 `Jer-y/copilot-proxy` 更新时，同步 `output/project/2026/codex-llm-node/CopilotProxy/` 快照 + 重打 `stripUnsupportedResponsesTools()` 补丁
- [ ] 补丁 `stripUnsupportedResponsesTools()` 是本地改动，未回流上游（如需长期维护可考虑 PR / fork 记录）

---

## 🐛 Known Issues / Waiting

- [ ] App 顶部下拉框只列 ChatGPT 目录（gpt-5.5 / gpt-5.4-mini）；Claude/Gemini/codex 模型需改 config.toml 的 `model` 字段或 CLI `-m`，下拉框不会自动列出（平台机制限制）
- [ ] Win11 24H2+ 移除 `wmic` → daemon `status`/`stop`/`restart` 失效（已规避：用前台模式）
- [ ] App 可能仍显示"ChatGPT 额度用尽"横幅 — 纯账号状态展示，不影响走代理（无害）
- [ ] CopilotProxy 是对 GitHub Copilot API 的逆向代理，非官方支持，存在账号风控风险（持续观察用量）

---

## ✅ Recently Done (last 7 days, auto-trimmed after 30 days)

- [x] 2026-06-14 — 删除桌面快捷方式（旧位置的 CopilotProxy 安装目录保留作备份）
- [x] 2026-06-14 — 把项目文件夹副本提升为日常运行主目录：`bun install`（454 包）+ 实测 PROXY_OK + 重指快捷方式 + README/helper 路径改为新位置
- [x] 2026-06-14 — 集中化到 `output/project/2026/codex-llm-node/`：README + config.sample.toml + scripts/proxy.ps1 + CopilotProxy 源码快照（排除 node_modules/.git）
- [x] 2026-06-14 — 一键启动器：`start-codex-proxy.bat`（纯 ASCII）→ `start-codex-proxy.ps1`（UTF-8 with BOM），中文无乱码
- [x] 2026-06-14 — 封装技能 `.claude/skills/codex-llm-node/`（SKILL.md + scripts/proxy.ps1）
- [x] 2026-06-13 — 代理侧修复 `stripUnsupportedResponsesTools()`：剥离 `image_generation` 等托管工具，解决 Codex `/responses` 被拒
- [x] 2026-06-13 — 在用户级 `~/.codex/config.toml` 配置 `model_provider = copilot-proxy`（App + CLI 共用，已备份原配置）
- [x] 2026-06-13 — 端到端验证：`gpt-5.3-codex`→PROXY_OK、CLI agent 建文件、`claude-opus-4.8`→CLAUDE_OK

---

## 📝 Open Questions (need CEO decision)

- [ ] 是否需要让 App 下拉框真正显示 Claude/codex 模型？（要投入研究 `model_catalog_json`；当前用 config.toml `model` 字段切换已可用）
- [ ] 旧位置的 CopilotProxy 安装目录（含 185MB node_modules）—— 当前决定：保留作备份。是否某天清理由 CEO 定。
