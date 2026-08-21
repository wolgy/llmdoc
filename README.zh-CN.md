# llmdoc for Claude Code 和 Codex

[English](README.md)

`llmdoc` 是一个同时面向 Claude Code 和 Codex 的文档驱动工作流。

- Core skill: `llmdoc`
- Claude Code commands: `/llmdoc:init`、`/llmdoc:team-init`、`/llmdoc:update`、`/llmdoc:review`
- Codex helper skills: `llmdoc-init`、`llmdoc-team-init`、`llmdoc-update`、`llmdoc-review`

## 关于本分叉

本仓库是 [TokenRollAI/llmdoc](https://github.com/TokenRollAI/llmdoc) 的分叉，分叉点为上游 **v2.3.0**（commit `1ad676f`，2026-07-28）。v2.3.0 以下的全部能力——有界冷启动上下文、L0/L1 路由、commit 水位线更新、生命周期感知 hooks——原样继承自上游。本分叉（v2.3.0-team.1）与原版有五点不同：

1. **移除叙事性过程记忆。** 上游存储任务反思（`memory/reflections/`，由 `reflector` agent 写入）、长期决策（`memory/decisions/`）和数量触发的 `lessons-learned.md` 归档机制。本分叉删除了这三类表面和 `reflector` agent。理由：稳定文档的断言可以对照仓库现状证伪，而"关于一段已消失过程的叙事"不可证伪——被当作质量输入读取的不可验证叙事会持续污染后续任务。过程信号改为在 update 时**三出口分诊**：当场修复可核实的文档缺陷、写成带关闭条件的 `doc-gaps.md` 条目、或丢弃。`memory/` 只剩 `doc-gaps.md` 一个文件且无永久居民；长期设计理由以现状事实的形式写进稳定文档正文。
2. **新增 `/llmdoc:review`**（Codex 侧 `llmdoc-review`）：只读的两层变更集审查——原生 pass（正确性、并发、安全、测试）叠加规范遵从 pass（对照项目 llmdoc 规约与团队基线）。每条遵从 finding 必须引用它违反的成文规约；已登记的偏离豁免上报，登记原因失效反过来上报 stale-override，存在适用清单时按条目逐条判定。
3. **新增 `/llmdoc:team-init`**（Codex 侧 `llmdoc-team-init`）：为受共享团队规约仓管辖的项目做初始化或 retrofit——询问团队仓的同级位置（不可读则 fail-closed 停止）、按团队仓自带模板接线门禁（`must/team-standards.md`）与偏离登记表（`reference/team-overrides.md`）、项目文档只写引用团队规约的增量而不复制。
4. **团队基线层成为一等概念**：机读声明行 `- team-baseline-path:`、recorder 的"基线只读"不变量、通用兜底模板、doc-structure reference 中定义的双层知识模型。
5. **`.llmdoc-tmp/` 清理从"许可"变为"机制"。** 上游只授权删除临时产物但从不真正删除。本分叉加入确定性清理：`/llmdoc:update` 在每次成功推进水位线后回收已消费的调查报告，`/llmdoc:init` 重建时删除按自身元数据判定过期的报告，可选的 `Stop` hook 自动清理 7 天以上的自身日志。

完整变更记录、设计理由与既有项目迁移指引见 [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md)。

推荐的默认配置很简单：

- `CLAUDE.md` 和 `AGENTS.md` 里只保留一条短规则：step one 是加载 `llmdoc` skill
- core skill 入口保持简短，详细的方法论、协议和模板拆到 `skills/llmdoc/references/`
- core skill 还定义了主动阅读 guides，以及在非简单改动前主动和用户沟通
- startup package 只在冷启动读取一次；Codex compact 后通过精简的 `LLMDOC_STATE` 恢复，而不是重放 llmdoc
- 巨石仓库使用有固定预算的根路由和子系统索引，不加载覆盖全仓库的叶子文档清单
- 整套工作流还恢复了一个好模式：在非简单任务结束时，主动询问是否运行 `/llmdoc:update`
- `/llmdoc:update` 支持轻量和重型模式，所以刚完成实现后的文档更新不必每次都跑完整多 agent 流水线
- Codex helper skills 提供了接近 command 的入口，但不会误导用户以为 Codex 已经支持这个插件的自定义 slash command
- agent 和 command contract 只负责执行，不再各自复制一大段说明

## 为什么这么改（上游 2.0 重构历史）

本节记录的是上游 2.0 重设计的理由，原样继承；本分叉的差异见上文「关于本分叉」。

旧设计暴露了太多内部步骤：

- 读文档、调研、文档工作流都做成了独立 skill
- `scout` 和 `investigator` 角色高度重叠
- 默认输出倾向于行级引用，不利于文件级检索

这次改动把外部接口缩到最小，把详细协议统一收敛到一个可复用的核心 skill，加上少量 Codex helper skills 入口。

## 公开接口

- Core skill: `llmdoc`
- Claude Code commands: `/llmdoc:init`、`/llmdoc:team-init`、`/llmdoc:update`、`/llmdoc:review`
- Codex helper skills: `llmdoc-init`、`llmdoc-team-init`、`llmdoc-update`、`llmdoc-review`
- Claude Code plugin 支持：`.claude-plugin/`
- Codex CLI plugin 支持：已提供 `.codex-plugin/plugin.json` 和 `.agents/plugins/marketplace.json`
- Codex CLI subagents 支持：已提供 `.codex/agents/*.toml`
- Codex CLI hooks：插件内置生命周期感知的 `SessionStart`；另提供 `Stop` 与 compact-prompt 模板

## 工作流

### `use`

`use` 不是命令。

它是由 `llmdoc` skill 定义的默认工作模式。推荐做法是在系统提示词里先要求模型加载这个 skill，再按 skill 里的规则工作。

### `/llmdoc:init`

用 `/llmdoc:init` 初始化或修复 `llmdoc` 结构。

在 Claude Code 里，它是 command。
在 Codex 里，用 helper skill `llmdoc-init` 走等价工作流。

这个命令会：

1. 检查仓库结构
2. 创建 llmdoc 目录骨架
3. 启动多个 investigator 生成临时调查草稿，显式检查覆盖面，并补做一轮查缺补漏
4. 生成初始 MUST、overview、architecture、reference 文档
5. 同步 `llmdoc/index.md`

### `/llmdoc:team-init`

受共享团队规约仓管辖的项目（团队级规约仓库，例如 `hmbird-llmdoc`），用 `/llmdoc:team-init` 代替 `/llmdoc:init`。

在 Claude Code 里，它是 command。
在 Codex 里，用 helper skill `llmdoc-team-init` 走等价工作流。

命令会**询问**用户团队规约仓的位置（也可作为参数直接传入），不做猜测或探测；询问时会提醒同级约束：规约仓必须克隆为**项目根目录的同级目录**，因为所有引用都写成相对项目根的 `../<目录名>/...` 路径——只接受同级形式的路径。fail-closed：声明的规约仓 `index.md` 不可读时命令直接停止、不做任何改动。它在标准 init 工作流之上：

1. 接线 `must/team-standards.md`（fail-closed 门禁 + 机读声明行 `- team-baseline-path: <同级路径>` + 团队必读清单 + 团队↔项目对照表）和 `reference/team-overrides.md`（偏离登记表），内容取自团队仓自带模板
2. 把门禁写为 `startup.md` 第 0 步
3. investigator 先读团队规约再看代码，避免把偏离当成项目风格记录下来
4. 项目文档只写项目增量、按相对路径引用团队规约而不复制；只有核实过的偏离才落入偏离登记表
5. 对已有 `llmdoc/` 的项目同样适用：只补团队接线（retrofit），不重新生成已正确的文档

### `/llmdoc:update`

在一次有价值的任务完成后，用 `/llmdoc:update` 持久化新知识。

在 Claude Code 里，它是 command。
在 Codex 里，用 helper skill `llmdoc-update` 走等价工作流。

这个命令会让 tracked `llmdoc/` 文档和当前仓库保持一致。稳定文档应该保持紧凑：要么比它描述的源码更小，要么能解释源码搜索无法快速提供的架构、实现意图、边界和稳定契约。

变更检测是**基于 commit** 的。一个被 git 跟踪的水位线 `llmdoc/state/sync.md` 记录 `llmdoc/` 已反映到的最后一个 source commit。默认对 `水位线..HEAD` 做 diff（自上次同步以来所有提交的净变更），成功后推进水位线。未提交的工作树变更作为附加输入纳入，但永不移动水位线。

它可以在一次运行里吞掉多批 commit —— `--range A..B`（可重复）、`--commits SHA,…`、`--since REF`、`--from SHA`、`--working-tree-only` —— 并在非 git 项目、shallow clone、首次运行无水位线、rebase/孤儿水位线等情况下优雅降级。

这个命令会选择能保证文档正确的最轻模式，触发器是 范围大小 × 作者归属 × 风险：

- `fast`：小范围、自己作者、受影响文档可点名
- `analysis`：较大范围、含任一他人提交、或恢复/首次运行的 baseline —— 一次聚焦证据 pass
- `full`：大范围或高风险、多批回填、或历史重写恢复 —— 独立的调研与记录

这个命令会：

1. 读水位线并计算 commit 范围（外加任何批次 flag 与工作树）
2. 主动阅读相关 guides 和 `doc-gaps.md` 中的未关闭条目
3. 基于范围大小、作者归属、风险选择 update mode
4. 只在所选模式需要时调研受影响的概念
5. 分诊过程信号：能对照当前仓库核实的文档缺陷当场修复；真实但本次修不了的写成带关闭条件的 `doc-gaps.md` 条目；其余丢弃 —— 不写任何叙事性记忆文件
6. 更新稳定文档，并清账 `llmdoc/memory/doc-gaps.md`
7. 同步 `llmdoc/index.md`，并在成功后推进水位线

在日常使用里，如果任务产生了值得长期保留的知识或暴露了文档缺陷，主 assistant 应该主动询问是否现在运行 `/llmdoc:update`。

### `/llmdoc:review`

在提交 / 推送 / 合并前，用 `/llmdoc:review` 审查一个变更集。

在 Claude Code 里，它是 command。
在 Codex 里，用 helper skill `llmdoc-review` 走等价工作流。

审查在解析出的 diff 上跑两层（默认审未提交改动；`--against REF`、`--range`、`--commits` 审分支或显式范围）：

1. **原生 pass** —— 正确性、并发、错误处理、安全、测试，按正常 review 判断力执行
2. **规范遵从 pass** —— 对照项目 llmdoc 规约，以及 `llmdoc/must/team-standards.md` 声明了团队基线时的团队规约

每条遵从 finding 必须引用它违反的成文规约（文件 + 小节，或规约条目 ID）；给不出引用的属于原生 finding 或个人意见，不得冒充规范遵从。`reference/team-overrides.md` 里登记过的偏离会豁免对应的基线 finding —— 但登记原因已不再成立时会作为 stale-override 上报，未登记的偏离一律算违规。存在适用清单（如 T/A 自检清单）时逐条判定。审查只读不改：发现的文档缺陷作为分诊输入交给 `/llmdoc:update`。

## Context 生命周期

`llmdoc` 区分冷启动和 compact 热恢复：

- `startup`、`clear`：只加载一次 core skill、根 index、startup 列表和 MUST pack
- `resume`：优先复用有效的 `LLMDOC_STATE`，没有有效状态时才执行一次冷启动
- `compact`：继续同一任务，不重新加载 skill、startup pack 或已经加载的任务文档

插件内置的 Codex `SessionStart` hook 会计算 startup pack 指纹和字节数。只有指纹变化、相关文档被修改、任务进入新子系统或 compact 状态不足时，才读取最小的相关文档集合。

`index.md` + `startup.md` + `must/` 的默认预算是 24 KiB；这是确定性的近似约束，不是精确 token 数。巨石仓库应让 `llmdoc/index.md` 只做 L0 路由，在相关文档旁建立子系统索引，并且只加载当前子系统的路由。

## llmdoc 结构

```text
llmdoc/
├── index.md
├── startup.md
├── must/                 # 冷启动时读取一次的小型上下文
├── overview/             # 项目和特性的身份与边界
├── architecture/         # 检索地图、不变量、所有权边界
├── guides/               # 一篇文档只讲一个工作流
├── reference/            # 稳定的查阅型事实和约定
└── memory/
    └── doc-gaps.md       # 带关闭条件的可执行文档缺口

.llmdoc-tmp/
└── investigations/       # 临时调查草稿
```

`llmdoc/index.md` 是有固定预算的全局路由。
`llmdoc/startup.md` 只负责冷启动阅读顺序。
两者可以互相链接，但不应该重复同一批内容。

`.llmdoc-tmp/` 是本地临时 context cache。investigator 报告可以跨相邻会话保留，帮助减少重复调研，但它被 git 忽略、不会进入 index，也不是 source of truth。只有稳定、可复用的结论才应该提升到 tracked `llmdoc/` 文档里。

## 内部 Agents

| Agent | 用途 |
|------|------|
| `investigator` | 做证据驱动的调研，可回对话、调研当前现状，也可输出临时调查草稿 |
| `worker` | 执行明确的任务并上交过程信号 |
| `recorder` | 维护稳定 llmdoc 文档和 `memory/doc-gaps.md` |

## 安装

### Claude Code

先安装 Claude Code。Anthropic 官方文档当前给出的安装方式包括：

- `npm install -g @anthropic-ai/claude-code`
- 或 macOS/Linux/WSL 原生安装：`curl -fsSL https://claude.ai/install.sh | bash`

官方文档：

- https://docs.anthropic.com/en/docs/claude-code/quickstart
- https://docs.anthropic.com/en/docs/claude-code/setup

然后安装这个插件市场和插件：

```bash
/plugin marketplace add https://github.com/wolgy/llmdoc
/plugin install llmdoc@llmdoc-cc-plugin
```

安装后：

1. 把 [`CLAUDE.example.md`](CLAUDE.example.md) 复制到 `~/.claude/CLAUDE.md`
2. 如果你还想加仓库级约束，可以把 [`AGENTS.example.md`](AGENTS.example.md) 改成项目根目录下的 `AGENTS.md`
3. 重启 Claude Code，让新的 prompt 和 plugin 状态生效

### Codex CLI

先安装 Codex CLI。OpenAI 官方文档当前给出的最小安装方式是：

```bash
npm i -g @openai/codex
codex
```

官方文档：

- https://developers.openai.com/codex/cli
- https://developers.openai.com/codex/plugins
- https://developers.openai.com/codex/plugins/build
- https://developers.openai.com/codex/subagents
- https://developers.openai.com/codex/hooks

这个仓库里有两类不同的 Codex 集成面：

- `llmdoc` 插件本身的打包文件：
  - [`.codex-plugin/plugin.json`](.codex-plugin/plugin.json)
  - [`skills/llmdoc/`](skills/llmdoc/)
  - [`skills/llmdoc-init/`](skills/llmdoc-init/)
  - [`skills/llmdoc-team-init/`](skills/llmdoc-team-init/)
  - [`skills/llmdoc-update/`](skills/llmdoc-update/)
  - [`skills/llmdoc-review/`](skills/llmdoc-review/)
  - [`hooks/hooks.json`](hooks/hooks.json)，插件内置的生命周期感知 `SessionStart` hook
  - [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json)，作为 repo 级本地 marketplace 示例
- 这个仓库自己的 repo-local Codex 工作流文件：
  - [`.codex/config.toml`](.codex/config.toml)
  - [`.codex/agents/`](.codex/agents)
  - [`skills/llmdoc/templates/codex-hooks.json`](skills/llmdoc/templates/codex-hooks.json)
  - [`skills/llmdoc/templates/compact-prompt.md`](skills/llmdoc/templates/compact-prompt.md)

#### 方式一：从 GitHub 安装（推荐）

适合你希望这台机器上的所有仓库都能使用 `llmdoc` 插件。

```bash
codex plugin marketplace add wolgy/llmdoc
```

然后：

1. 重启 Codex，让新的 marketplace 源加载进来
2. 在 Codex 中执行 `/plugins`
3. 在插件列表中找到 `llmdoc`，选中进入详情页
4. 安装插件
5. 在 `/hooks` 中检查并信任插件内置的生命周期 hook
6. 在任意仓库里新开一个对话，然后按你的目标选择入口：
   - 正常工作时，让 Codex 先加载 `llmdoc` skill
   - 要执行 `/llmdoc:init` 等价流程时，选择 `llmdoc-init`
   - 要执行 `/llmdoc:team-init` 等价流程时（团队规约项目），选择 `llmdoc-team-init`
   - 要执行 `/llmdoc:update` 等价流程时，选择 `llmdoc-update`
   - 要执行 `/llmdoc:review` 等价流程时，选择 `llmdoc-review`
   - 或者输入 `@`，再显式选择这个插件或它打包进来的 skill

#### 方式二：直接在 Codex 里使用这个仓库（本地开发）

适合你正在这个仓库里工作——参与贡献或测试本地改动。

1. 用 Codex 打开这个仓库
2. 确认 [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json) 存在
3. 如果 Codex 已经在运行，先重启一次，让 repo marketplace 和 project-scoped agents 重新加载
4. 在 Codex 中执行 `/plugins`
5. 在插件列表中找到 `llmdoc`，选中进入详情页
6. 安装插件
7. 在这个仓库里新开一个对话，然后按你的目标选择入口：
   - 正常工作时，让 Codex 先加载 `llmdoc` skill
   - 要执行 `/llmdoc:init` 等价流程时，选择 `llmdoc-init`
   - 要执行 `/llmdoc:team-init` 等价流程时（团队规约项目），选择 `llmdoc-team-init`
   - 要执行 `/llmdoc:update` 等价流程时，选择 `llmdoc-update`
   - 要执行 `/llmdoc:review` 等价流程时，选择 `llmdoc-review`
   - 或者输入 `@`，再显式选择这个插件或它打包进来的 skill
8. 在 `/hooks` 中检查并信任插件内置 hook。如果你更希望使用 repo-local hook，可以把 [`skills/llmdoc/templates/codex-hooks.json`](skills/llmdoc/templates/codex-hooks.json) 复制到 `.codex/hooks.json`，再按机器路径调整脚本；不要同时启用两份

compact-prompt 模板是可选增强，因为配置 `compact_prompt` 或 `experimental_compact_prompt_file` 会覆盖 Codex 内置 compaction prompt。只有在需要更强的 `LLMDOC_STATE` 结构保证，并愿意随 Codex 演进持续检查模板时才启用。

当你打开的就是这个仓库时，Codex 还会同时使用 [`.codex/agents/`](.codex/agents) 里的 project-scoped agents，以及 [`.codex/config.toml`](.codex/config.toml) 里的 agent 限制配置。

### 从上游安装切换到本分叉(SOP)

已经从上游市场([TokenRollAI/llmdoc](https://github.com/TokenRollAI/llmdoc))安装过 llmdoc 的机器,按以下步骤切换到本分叉。分叉沿用了相同的市场名(`llmdoc-cc-plugin`)和插件名(`llmdoc`),所以必须**先移除上游源**——两者无法共存。

**Claude Code**

```bash
/plugin uninstall llmdoc@llmdoc-cc-plugin
/plugin marketplace remove llmdoc-cc-plugin
/plugin marketplace add https://github.com/wolgy/llmdoc
/plugin install llmdoc@llmdoc-cc-plugin
```

然后重启 Claude Code,在 `/plugin` 里核对已安装的 llmdoc 版本:**带 `-team` 后缀(如 `2.3.0-team.1`)= 本分叉,纯 `2.3.0` = 仍在上游**——版本号是确认当前源最快的办法。`~/.claude/CLAUDE.md` 无需改动。

**Codex CLI**

1. 在 `/plugins` 里卸载 `llmdoc`。
2. 移除上游市场源(用 `codex plugin marketplace list` 查它注册的名字),再添加本分叉:`codex plugin marketplace add wolgy/llmdoc`。
3. 重启 Codex,在 `/plugins` 里安装 `llmdoc`,确认版本带 `-team` 后缀。
4. 在 `/hooks` 里重新审查并信任内置的 `SessionStart` hook —— hook 脚本在本分叉有变更,信任前应重新过目。

**项目侧迁移**

切换插件不会动任何项目的 `llmdoc/` 内容。要把项目文档迁到本分叉的记忆模型(退役 `memory/reflections/`、`memory/decisions/`、`lessons-learned.md`),按 [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md) 的迁移指引执行。受团队规约管辖的项目,随后再跑一次 `/llmdoc:team-init`——它只补团队接线,不会重新生成已正确的文档。

## 仓库内文件

可复用 skill 位于 [`skills/llmdoc/SKILL.md`](skills/llmdoc/SKILL.md)。
Codex helper 入口 skills 位于 [`skills/llmdoc-init/SKILL.md`](skills/llmdoc-init/SKILL.md)、[`skills/llmdoc-team-init/SKILL.md`](skills/llmdoc-team-init/SKILL.md)、[`skills/llmdoc-update/SKILL.md`](skills/llmdoc-update/SKILL.md) 和 [`skills/llmdoc-review/SKILL.md`](skills/llmdoc-review/SKILL.md)。
详细参考文档位于 [`skills/llmdoc/references/`](skills/llmdoc/references/)。
Codex CLI hooks 模板位于 [`skills/llmdoc/templates/`](skills/llmdoc/templates/)。
插件内置的 Codex hook 位于 [`hooks/hooks.json`](hooks/hooks.json)。

## Codex Subagents

这个仓库现在也包含 project-scoped 的 Codex 自定义 agents：

- [`.codex/config.toml`](.codex/config.toml)
- [`.codex/agents/llmdoc-investigator.toml`](.codex/agents/llmdoc-investigator.toml)
- [`.codex/agents/llmdoc-worker.toml`](.codex/agents/llmdoc-worker.toml)
- [`.codex/agents/llmdoc-recorder.toml`](.codex/agents/llmdoc-recorder.toml)

这些文件遵循官方 Codex subagents 文档里 project-scoped TOML agents 的模式，放在 `.codex/agents/` 下，所以它们是在“打开这个仓库”时生效的。

这里使用了 `llmdoc_` 前缀，避免覆盖 Codex 自带的 `worker`、`explorer` 等内置 agents。

## 迁移说明

这个版本把旧的碎片化 skill 收敛成一个 skill：

- 当前 skill: `llmdoc`
- 移除 skills: `read-doc`、`investigate`、`update-doc`、`doc-workflow`、`deep-dive`、`commit`
- 移除 commands: `initDoc`、`withScout`、`what`
- 移除 agent: `scout`

如果你之前依赖这些入口：

- 用 `/llmdoc:init` 替代旧的 `tr` 前缀 init 命令
- 用 `/llmdoc:update` 替代 `/update-doc`
- 用 `llmdoc` skill 替代分散的 read/investigate skill
