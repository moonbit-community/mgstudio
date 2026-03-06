# Bevy 对齐异常台账（Wave A）

状态: Active (SoT)  
最后校验: 2026-03-06  
范围: Wave A / 异常登记模板与判定规则  
代码参考:
- `mgstudio-engine/`
- `bevy/`
替代文档: N/A  
说明:
- 当前目标是让 `mgstudio-engine` 对齐 `./bevy` `0.19.0-dev`，并在源码结构、模块拆分、实现链路上尽量保持 `1:1`。
- 本文件不是常规 gap list，也不是延期清单；它只记录被评审确认的“无法 `1:1`”例外。
- 只有在 `MoonBit` 语法/语言机制、社区依赖能力或平台条件这三类硬约束导致无法 `1:1` 时，才允许登记异常。
- 任何“暂未实现、工期不足、人力不足、局部重构偏好、命名/目录调整偏好、先做简化版”的差异，都必须进入正常对齐工作项，不得登记为异常。

## 1. 适用范围与目标

- 本台账用于约束 Wave A 的偏离面，避免“未对齐”被误写成“例外”。
- 每一条异常都必须指向明确的 `bevy/` 锚点和 `mgstudio-engine/` 落点，不能写成抽象描述。
- 每一条异常都必须带退出条件；当 `MoonBit`、社区依赖或目标平台能力发生变化时，需要回看并尽快回收异常。
- 若能通过代码生成、局部适配层、等价模块切分、相同调度链路来维持 `1:1`，则必须继续对齐，不得登记异常。

## 2. 顶层异常分类

| 分类码 | 分类名称 | 允许登记的根因 | 典型场景 | 明确不包含 |
| --- | --- | --- | --- | --- |
| `MB-LANG` | MoonBit 语法/语言机制约束 | Rust/Bevy 依赖的语法、类型系统、宏/派生、trait 表达、生命周期或编译期机制，无法被 `MoonBit` 以等价结构与链路表达 | `derive`/属性宏、复杂 trait/关联类型、生命周期驱动接口 | “MoonBit 这样写更自然”“为了少写模板代码” |
| `DEP-ECOSYSTEM` | 社区依赖能力约束 | Bevy 上游依赖的关键能力在 `MoonBit` 生态没有可用实现、可维护绑定或可接受替代，导致无法保持相同实现链路 | 文本 shaping、音频编解码、压缩/容器处理、平台库绑定缺位 | “依赖还没接完”“暂时不想引入外部库” |
| `PLATFORM` | 平台/运行时条件约束 | 目标平台本身不提供 Bevy 假设的能力，导致同一结构或执行链路无法落地 | Web/WASM 的线程、文件系统、GPU 后端、宿主 API 限制 | “平台上能做，但我们先不做” |

## 3. 异常登记准入边界

### 3.1 必须同时满足

1. 已锁定具体的 `bevy/` 源码锚点，至少精确到 crate / 模块 / 文件 / 核心符号。
2. 已锁定 `mgstudio-engine` 的对应落点，明确原本希望保持的 `1:1` 结构与实现链路。
3. 已至少尝试过一种保持 `1:1` 的方案，并有失败证据或能力缺口证据。
4. 根因可以唯一归入 `MB-LANG`、`DEP-ECOSYSTEM`、`PLATFORM` 之一。
5. 当前偏离是“最小必要偏离”，没有借机扩大为风格性重写或架构重排。
6. 已写出退出条件与回看触发器，说明异常在什么条件下必须被回收。
7. 已有对应设计记录并完成评审，才允许正式入账。

### 3.2 任何一项命中即不得登记

- 只是“还没做完”。
- 只是“当前波次来不及”。
- 只是“这样写更简单/更 MoonBit”。
- 只是“目录/命名想更整洁”。
- 只是“先做兼容版本，后面再说”。
- 只是“性能可能更好/更省代码”，但没有硬约束阻止 `1:1`。
- 没有具体 `bevy/` 锚点。
- 没有设计评审结论。

## 4. 必填字段

每条正式异常必须完整填写以下字段，缺一不可。

| 字段 | 是否必填 | 说明 |
| --- | --- | --- |
| `Exception ID` | 是 | 建议格式：`WA-EXC-###` |
| `Status` | 是 | `Proposed` / `Approved` / `Active` / `Resolved` / `Rejected` |
| `Wave` | 是 | 当前固定写 `Wave A` |
| `Category` | 是 | `MB-LANG` / `DEP-ECOSYSTEM` / `PLATFORM` |
| `Severity` | 是 | `S0` / `S1` / `S2` / `S3` |
| `Bevy Version` | 是 | 当前固定写 `0.19.0-dev` |
| `Bevy Anchor` | 是 | `bevy/` 中的路径、模块、符号或调用链入口 |
| `mgstudio Anchor` | 是 | `mgstudio-engine/` 中的目标落点 |
| `Parity Contract` | 是 | 本来要保持的 `1:1` 结构、模块边界或实现链路 |
| `Blocking Constraint` | 是 | 只能写允许的三类硬约束，禁止写工期/主观偏好 |
| `Evidence` | 是 | 编译报错、原型失败、API 缺失、平台限制、依赖缺位等证据 |
| `Minimal Deviation` | 是 | 当前允许的最小偏离方案，必须可控、可回收 |
| `Impact Surface` | 是 | 影响到的模块、平台、API、测试面 |
| `Fallback / Temporary Handling` | 是 | 临时兜底策略；没有则写 `N/A` |
| `Exit Criteria` | 是 | 异常被删除或收敛回 `1:1` 的条件 |
| `Revisit Trigger` | 是 | 触发重新评估的事件，如 `MoonBit` 升级、依赖补齐、平台能力变化 |
| `Design Doc` | 是 | 对应 `.private/docs/` 设计文档路径 |
| `Review Status` | 是 | 至少写清“已评审 / 待评审 / 驳回” |
| `Issue` | 是 | 对应 `bd` issue 编号 |
| `Owner` | 是 | 当前负责人 |
| `Reviewer` | 是 | 评审人 |
| `Opened On` | 是 | 建立日期 |
| `Last Verified` | 是 | 最后一次确认该异常仍成立的日期 |

## 5. 判定规则

### 5.1 核心判定原则

- 原则 1：默认必须 `1:1`。任何差异都先视为普通对齐缺口，而不是异常。
- 原则 2：异常只记录“做不到”，不记录“暂时不做”。
- 原则 3：异常必须绑定具体源码链路，而不是绑定抽象概念。
- 原则 4：异常必须最小化，优先保留 Bevy 的目录、阶段、系统顺序、数据流和 API 形状。
- 原则 5：异常必须可回收；一旦约束消失，异常就应该关闭。

### 5.2 分类归因规则

- 如果问题根因是 `MoonBit` 本身没有对应语法、类型能力、宏机制或编译期机制，归为 `MB-LANG`。
- 如果问题根因是 `MoonBit` 社区当前没有可用依赖、稳定绑定或可维护替代，归为 `DEP-ECOSYSTEM`。
- 如果问题根因是目标平台根本不给能力，例如浏览器线程/GPU/文件系统限制，归为 `PLATFORM`。
- 如果同时涉及多种因素，必须写出主因；不能把“实现复杂”混写成多因异常。

### 5.3 审批闸门

正式登记前，评审必须回答以下问题且全部为“是”：

1. 是否已阅读对应 `bevy/` 实现而非只看公开 API？
2. 是否已证明无法通过 codegen、适配层或等价模块切分维持 `1:1`？
3. 当前偏离是否已经压缩到最小？
4. 退出条件是否具体、可验证？
5. `bd` issue 与设计文档是否已建立并互相可追踪？

只要有一项为“否”，条目状态必须停留在 `Proposed` 或被标记为 `Rejected`。

## 6. 登记流程

1. 在 `bevy/` 中定位目标实现，锁定 crate、模块、文件、符号与调用链。
2. 在 `.private/docs/` 写设计记录，说明原始 `1:1` 方案、失败尝试、根因与最小偏离。
3. 创建或更新对应 `bd` issue，标记异常来源、影响面与后续回收条件。
4. 发起评审；未评审通过前，不得把条目标记为 `Approved` 或 `Active`。
5. 评审通过后，在本台账新增条目，并同步填写所有必填字段。
6. 实施最小偏离方案时，代码和文档必须继续保留可回到 `1:1` 的路径。
7. 每次 `MoonBit` 升级、依赖补齐、平台能力变化或对应子系统重构时，必须重新校验条目。
8. 一旦约束消失，立即将条目改为 `Resolved`，并在实现中回收偏离。

## 7. 严重度定义

严重度描述的是“对 `1:1` 对齐目标的破坏面”，不是工单优先级。

| 级别 | 定义 | 典型影响 |
| --- | --- | --- |
| `S0` | 阻断级异常，直接阻止核心架构或主执行链对齐 | 整个子系统无法按 Bevy 链路落地，且没有可接受的临时封装 |
| `S1` | 高影响异常，阻止公共 API、关键调度链或核心数据模型对齐 | 需要长期适配层，影响多个模块或主路径 |
| `S2` | 中影响异常，偏离局部实现链路，但可保持主要 API 与结构轮廓 | 影响单个子模块或特定平台路径 |
| `S3` | 低影响异常，只影响边缘平台、辅助能力或可封装的非主路径 | 主线 API 不变，偏离面清晰且可隔离 |

## 8. 标准条目模板

```md
## WA-EXC-###

- Status: Proposed
- Wave: Wave A
- Category: MB-LANG | DEP-ECOSYSTEM | PLATFORM
- Severity: S0 | S1 | S2 | S3
- Bevy Version: 0.19.0-dev
- Bevy Anchor: `bevy/...`
- mgstudio Anchor: `mgstudio-engine/...`
- Parity Contract:
  - <原本需要保持的 1:1 结构、模块边界、实现链路或行为契约>
- Blocking Constraint:
  - <只能写 MoonBit 语法/社区依赖/平台条件中的一种主因>
- Evidence:
  - <编译错误、原型失败、能力缺失、平台限制、依赖缺口>
  - <第二条证据；如无请补齐，不允许空缺>
- Minimal Deviation:
  - <当前允许的最小偏离，必须说明仍保留了哪些 Bevy 对齐面>
- Impact Surface:
  - <影响的模块、平台、API、测试面、文档面>
- Fallback / Temporary Handling:
  - <临时兜底；没有则写 N/A>
- Exit Criteria:
  - <满足什么条件后必须删除该异常并回收到 1:1>
- Revisit Trigger:
  - <MoonBit 版本变化、依赖补齐、平台能力变化、上游 Bevy 调整>
- Design Doc: `.private/docs/...`
- Review Status: 待评审 | 已评审 | 驳回
- Issue: `bd-...`
- Owner: <name>
- Reviewer: <name>
- Opened On: YYYY-MM-DD
- Last Verified: YYYY-MM-DD
```

## 9. 当前台账状态

- 已批准真实异常: `0`
- 待评审真实异常: `0`
- 说明: 本次仅建立模板与规则，不在未评审前预填真实异常。

## 10. 样例条目（仅示范格式，不代表已批准真实异常）

### WA-EXC-001

- Status: Sample
- Wave: Wave A
- Category: MB-LANG
- Severity: S1
- Bevy Version: 0.19.0-dev
- Bevy Anchor: `bevy/crates/bevy_ecs/macros/`, `bevy/crates/bevy_reflect/`
- mgstudio Anchor: `mgstudio-engine/ecs/`, `mgstudio-engine/app/`
- Parity Contract:
  - 保持 Bevy 依赖 `derive`/属性宏生成注册逻辑的类型声明与接线链路 `1:1`。
- Blocking Constraint:
  - `MoonBit` 不具备 Rust 风格的过程宏与属性宏机制，无法原样承载 `#[derive(...)]` 与属性标注驱动的源码展开链路。
- Evidence:
  - 若目标链路要求“在同一类型定义处以宏属性注入注册/反射逻辑”，`MoonBit` 只能改走显式代码生成或手写注册路径。
  - 即使运行时行为可逼近，源码层面的声明位置、展开入口和编译期接线方式也无法做到 `1:1`。
- Minimal Deviation:
  - 允许使用外部 codegen 产物或显式注册模块替代宏展开，但必须尽量保留 Bevy 的模块边界、初始化顺序和调用链结构。
- Impact Surface:
  - 反射、组件注册、资源注册、派生驱动元数据。
- Fallback / Temporary Handling:
  - 以生成文件或注册函数承接原本的宏展开结果。
- Exit Criteria:
  - `MoonBit` 提供可等价承载该类编译期注入能力的稳定机制，或项目建立了被评审认可的等价语言级方案。
- Revisit Trigger:
  - `MoonBit` 发布新的宏/元编程能力；现有 codegen 链重构。
- Design Doc: `.private/docs/engine/<待补设计文档>.md`
- Review Status: 样例
- Issue: `bd-<sample>`
- Owner: Wave A
- Reviewer: Wave A reviewer
- Opened On: 2026-03-06
- Last Verified: 2026-03-06

### WA-EXC-002

- Status: Sample
- Wave: Wave A
- Category: DEP-ECOSYSTEM
- Severity: S2
- Bevy Version: 0.19.0-dev
- Bevy Anchor: `bevy/crates/bevy_text/`
- mgstudio Anchor: `mgstudio-engine/text/`
- Parity Contract:
  - 保持 Bevy 文本 shaping / fallback / layout 所依赖的实现链路与行为边界 `1:1`。
- Blocking Constraint:
  - `MoonBit` 社区若不存在可维护的文本 shaping 依赖或稳定绑定，则无法照搬 Bevy 所依赖的上游能力链。
- Evidence:
  - 若缺少可用 shaping/back-end 依赖，复杂脚本文本、字形回退与测量链路只能改走宿主适配或替代实现。
  - 在没有等价依赖的前提下，继续强行保持相同后端接线只会留下不可维护空壳。
- Minimal Deviation:
  - 保留 Bevy 风格的前端数据结构、系统顺序与调用入口，后端通过单独适配层接入替代 shaping 能力。
- Impact Surface:
  - 文本布局、字形回退、换行与测量一致性、多语言渲染测试。
- Fallback / Temporary Handling:
  - 以平台文本后端或受控适配器兜底，并补齐 golden case。
- Exit Criteria:
  - 出现可维护的 `MoonBit` shaping 依赖/绑定，足以恢复 Bevy 风格后端链路。
- Revisit Trigger:
  - 新增社区依赖；现有文本后端能力升级；文本一致性测试新增失败样本。
- Design Doc: `.private/docs/engine/<待补设计文档>.md`
- Review Status: 样例
- Issue: `bd-<sample>`
- Owner: Wave A
- Reviewer: Wave A reviewer
- Opened On: 2026-03-06
- Last Verified: 2026-03-06

### WA-EXC-003

- Status: Sample
- Wave: Wave A
- Category: PLATFORM
- Severity: S2
- Bevy Version: 0.19.0-dev
- Bevy Anchor: `bevy/crates/bevy_tasks/`, `bevy/crates/bevy_render/`
- mgstudio Anchor: `mgstudio-engine/runtime/`, `mgstudio-engine/render/`
- Parity Contract:
  - 在 Web/WASM 路径上保持与 Bevy 原生目标一致的任务调度与渲染执行链。
- Blocking Constraint:
  - 目标平台若不提供所需线程、GPU 后端或宿主能力，则原生 Bevy 的执行模型无法原样落地。
- Evidence:
  - 浏览器线程能力、文件系统语义或 GPU 特性与原生目标不一致时，同一执行链无法直接复用。
  - 即使 API 表面保持一致，底层调度和资源访问路径也必须对平台能力做最小收敛。
- Minimal Deviation:
  - 保留相同阶段名、主调度边界和资源流向，仅在平台专属适配层中裁剪不可用能力。
- Impact Surface:
  - Web 任务执行模型、平台渲染后端、资源上传/回读路径。
- Fallback / Temporary Handling:
  - 对受限平台降级到单线程或能力裁剪路径，并保持主线 API 不变。
- Exit Criteria:
  - 目标平台提供缺失能力，或宿主桥接补齐后可回收平台专属分叉。
- Revisit Trigger:
  - 浏览器能力更新、宿主 API 扩展、渲染后端切换。
- Design Doc: `.private/docs/engine/<待补设计文档>.md`
- Review Status: 样例
- Issue: `bd-<sample>`
- Owner: Wave A
- Reviewer: Wave A reviewer
- Opened On: 2026-03-06
- Last Verified: 2026-03-06
