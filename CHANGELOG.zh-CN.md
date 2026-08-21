<!--
  本文件是面向人类维护者的发布说明。
  刻意不被任何 llmdoc 运行时表面引用：不要在 llmdoc/index.md、startup.md、must/、
  skills/、commands/、agents/ 中引用或索引本文件，也不要让 recorder 将其纳入知识库。

  英文版(CHANGELOG.md)为默认与权威版本;本文件是其同步翻译,每个发布条目须与英文版保持一致。
-->

# 变更日志

[English](CHANGELOG.md)

## 2.3.0-team.1 — 2026-08-21

### 新增:`/llmdoc:review` 两层代码审查(command + Codex skill)

新增 `commands/review.md`(Claude Code command `/llmdoc:review`)与 `skills/llmdoc-review/SKILL.md`(Codex helper skill `llmdoc-review`),在原生 review 之上叠加 llmdoc 规范遵从审查:

- **两层审查**:原生 pass(正确性 / 并发 / 错误处理 / 安全 / 测试,正常判断力)+ 规范遵从 pass(对照项目 llmdoc 规约与团队基线);
- **遵从 finding 必须引用成文规约**(文件 + 小节或条目 ID),给不出引用的降级为原生 finding 或意见——与本版本的可证伪性原则同构;
- **团队基线感知**:`llmdoc/must/team-standards.md` 存在**且**含机读行 `- team-baseline-path:` 即视为已声明基线;基线声明了但不可读时审查可继续(只读),但报告开头必须声明「未加载团队规约」且遵从层标记为不完整,严禁凭记忆重构团队规约;文件存在但缺机读行 = 畸形声明,作为文档缺陷上报;
- **偏离登记豁免**:`reference/team-overrides.md` 已登记的偏离不报违规,但登记原因不再成立时报 `stale-override`;未登记的偏离一律算违规(即使存量代码同样偏离);
- **清单逐条判定**:存在适用自检清单(如团队 T 项 / 项目 A 项)时按条目 ID 输出 pass / fail / not-applicable;
- **只读不变量**:审查永不改文件;发现的文档缺陷作为分诊输入交给 `/llmdoc:update`;
- 范围解析复用 update 的 git plumbing 约定:默认审未提交改动,`--against REF`(基于 merge-base,排除上游提交)、`--range`、`--commits`(拒绝 merge commit)、`--staged`、`--working-tree`。

同步更新:两份 README、`skills/README.md`、`llmdoc/reference/repo-surfaces.md`、`llmdoc/must/doc-routing.md`、`.codex-plugin/plugin.json`(defaultPrompt 增加 review 入口;Codex 插件按 `skills/` 目录自动发现新 skill)。

### 新增:`/llmdoc:team-init` 团队规约 init(command + Codex skill)

新增 `commands/team-init.md`(`/llmdoc:team-init`)与 `skills/llmdoc-team-init/SKILL.md`(`llmdoc-team-init`)。标准 `/llmdoc:init` 保持纯净不变;团队项目改用 team-init,它在标准 init 契约之上叠加团队接线:

- **询问而非猜测**:init 时询问用户团队规约仓的位置(也可作为参数传入),不做探测;询问时提醒**同级约束**——规约仓必须克隆为项目根的同级目录,因为所有引用都是相对项目根的 `../<目录名>/...` 路径,只接受同级形式;仓库现居他处时要求先克隆/移动到同级再继续。fail-closed:声明路径的 `index.md` 不可读时整个命令停止、零改动;严禁在基线缺席时凭记忆或通用模板脚手架团队文件;
- **团队接入脚手架**:生成 `must/team-standards.md`(fail-closed 门禁 + 机读声明行 `- team-baseline-path: <同级路径>` + 团队必读清单 + 团队↔项目对照表)与 `reference/team-overrides.md`(偏离登记表),内容取自团队仓自带 `templates/`(`references/templates.md` 的通用模板仅作无模板基线的兜底);门禁写为 `startup.md` 第 0 步;
- **双模式**:无 `llmdoc/` 时执行完整 init 工作流 + 团队增强;已有 `llmdoc/` 时仅 retrofit 团队接线,不重新生成已正确的文档;
- **调研顺序约束**:investigator 先读基线规约再看代码,且每个 investigator prompt 都携带该上下文——否则会把偏离当成项目风格记录下来;
- **增量原则**:项目文档只写项目专有增量,团队规约按相对路径引用、不复制;核实过的偏离(引用规约条目 + 当前仍成立的原因)落入偏离登记表,存疑的写成带关闭条件的 doc-gap;项目清单条目遵循基线的 ID 分域约定;
- **基线只读不变量**:`doc-structure.md` 新增 "Team baseline layer" 一节定义双层知识模型;recorder(agent + Codex TOML)新增规则——声明的基线仓永远只读,其相对路径引用不算悬空引用,门禁文案不算过时断言,防止 `/llmdoc:update` 误伤团队接线;worker 新增门禁继承——即使调用方引用了具体文档,也必须先遵守 fail-closed 门禁。

机读声明行 `- team-baseline-path:` 同时是 `/llmdoc:review` 遵从层的解析锚点。全部表面保持通用,不硬编码任何团队仓名称;`hmbird-llmdoc` 仅作为示例出现。

### 新增:`.llmdoc-tmp/` 确定性清理机制

上游对临时产物只有"可以删"的许可,没有任何主动清理。本版本加入三条确定性规则(零模型成本):

- **update 终末 GC**:`/llmdoc:update` 成功推进水位线后,删除 `.llmdoc-tmp/investigations/` 下 recorded `Range:` tip 已是新水位线祖先的报告(证据已消费),以及 recorded revision 已不存在于仓库的报告;未推进水位线的运行完全跳过 GC;
- **init 重建清场**:`/llmdoc:init` 修复既有骨架时,删除按自身元数据判定过期(revision 缺失、Reuse Conditions 不再成立)的调查报告;
- **stop.sh 日志自清理**:写入新日志前 `find ... -mtime +7 -delete`,清掉 `.llmdoc-tmp/hooks/` 下 7 天以上的 `stop-*.json`。

`.llmdoc-tmp/` 从不被 git 跟踪,删除即终态,无归档负担。update 报告项新增 tmp-GC 结果。

### 破坏性变更:移除叙事性过程记忆(reflection / decision / lessons-learned)

llmdoc 不再存储任何叙事性过程记忆。`llmdoc/memory/` 收敛为唯一文件 `doc-gaps.md`。

**动机。** 稳定文档的断言可以对照仓库现状证伪,而"关于一段已消失过程的叙事"(reflection)不可证伪:写下时就错的归因会永远错下去,且旧协议要求把 reflection 当作质量输入来读,错误叙事会持续污染后续任务。decision 文档同理——仍然成立的决定本质是系统的现状事实,应写进对应稳定文档的正文("X 刻意不存在,因为 Y"),而不是独立的决策档案。反思这个**动作**保留,但它的产出只允许是可验证的修改。

**新机制:过程信号三出口分诊(signal triage)。** `/llmdoc:update` 第 5 步由"写 reflection"改为分诊。信号来源包括 worker 的 `Process Signals` 上交、`/llmdoc:review` 上报的文档缺陷、失败的命令/测试、用户纠正、返工痕迹、与文档断言矛盾的证据。每个信号进入且仅进入一个出口:

1. **fix now** — 能对照当前仓库核实的文档缺陷(断言错误、路由缺失、契约含糊),当场修复;
2. **doc-gap** — 真实但本次修不了,写入 `memory/doc-gaps.md`,必须带可验证的关闭条件;
3. **discard** — 无法归因到可验证文档缺陷的一律视为噪声,不允许"先存着以后看"。

**移除的表面:**

- `agents/reflector.md`、`.codex/agents/llmdoc-reflector.toml`(reflector agent 整体移除)
- `skills/llmdoc/references/lessons-learned.md` 及 `/llmdoc:update` 原第 7 步 "active-memory archive check"(count>5 触发的 lessons-learned 蒸馏 + archive/ 搬迁机制整体移除)
- `llmdoc/memory/reflections/`、`llmdoc/memory/decisions/` 从目录骨架与所有契约中移除
- 本仓库 dogfood 的两篇既有 reflection(其晋升候选早已全部落进 `context-lifecycle.md` 等稳定文档,剩余价值为零;git 历史即归档)

**修改的表面:**

- `commands/update.md` / `skills/llmdoc-update/SKILL.md`:第 5 步改为信号分诊,原第 7 步删除并重新编号,报告项由 reflection/archive 改为分诊结果
- `skills/llmdoc/references/update-and-memory.md`:Reflection protocol 段替换为 Process-signal triage 段;Memory ownership 收敛为 doc-gaps 单文件,并写入"memory 无永久居民"不变量
- `skills/llmdoc/references/doc-structure.md`、`templates.md`、`operating-protocol.md`、`design-goals.md`、`codex-cli-hooks.md`、`skills/llmdoc/SKILL.md`:同步移除 reflection/decision/lessons 相关协议
- `agents/worker.md` / `llmdoc-worker.toml`:输出字段 `Reflection Handoff` 更名为 `Process Signals`,交由调用方分诊
- `agents/investigator.md`、`agents/recorder.md` 及对应 TOML:移除 reflection 阅读要求;recorder 的 memory 所有权收敛为 doc-gaps.md
- `skills/llmdoc/templates/stop.sh`:count>5 归档提醒改为"memory/ 出现 doc-gaps.md 以外文件"的污染告警
- `skills/llmdoc/templates/session-start.sh`:冷启动指引不再要求读取 lessons-learned.md / reflections
- `commands/init.md` / `skills/llmdoc-init/SKILL.md`:骨架由 `memory/reflections/` + `memory/decisions/` 改为 `memory/doc-gaps.md`
- `README.md`、`README.zh-CN.md`、`AGENTS.example.md`、`CLAUDE.example.md`、`skills/README.md`:公开叙述同步
- 本仓库 dogfood `llmdoc/` 文档全量同步(index、startup、must/、architecture/、guides/、reference/)

### 既有项目迁移指引

1. 对每篇现存 reflection 做一次终审分诊:教训已被稳定文档吸收或已失效的直接删除;仍然有效但未落地的,把结论翻译成对应稳定文档的现状陈述,或写成带关闭条件的 doc-gap。
2. `memory/decisions/` 下的决定:仍然成立的写进相关稳定文档正文;前提已失效的直接删除。
3. 删除 `memory/lessons-learned.md` 与 `memory/archive/`(先把其中仍有效的规则按第 1 条处理)。
4. 完成后 `llmdoc/memory/` 应只剩 `doc-gaps.md`。所有删除无需另行备份——git 历史即归档。

### 版本与版本号方案

- `.claude-plugin/plugin.json`、`.codex-plugin/plugin.json`:`2.3.0` → `2.3.0-team.1`。
- 本分叉采用**上游锚定式版本号** `<上游基线版本>-team.<分叉迭代号>`,不再使用独立主版本号(曾短暂命名为 3.0.0,已弃用)——独立版本号会与上游未来的版本序列冲突,无法从版本号读出对应的上游基线。
- 规则:分叉自身迭代只递增末位(`2.3.0-team.2`、`.3`…);rebase 到新的上游版本后重置为 `<新基线>-team.1`(如上游发布 2.4.0 → `2.4.0-team.1`)。
- 判别:版本号**带 `-team` 后缀 = 本分叉,纯上游版本号 = 上游原版**。安装与切换 SOP 中的版本核对均以此为准。
- 注意 semver 语义:按严格 semver 比较,`2.3.0-team.1` 的优先级**低于** `2.3.0`(预发布后缀规则)。当前 Claude Code / Codex 插件市场按源安装、不做跨源版本比较,无实际影响;但未来引入任何自动版本比较的工具链之前,需先处理这一点。
