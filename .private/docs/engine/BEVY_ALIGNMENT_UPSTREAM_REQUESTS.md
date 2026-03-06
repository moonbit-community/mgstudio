# Bevy 对齐上游依赖请求台账

状态：Active
最后更新：2026-03-06
负责人：Wave A / 上游依赖请求台账
唯一写集：`/Users/zhengyu/Documents/projects/moon-game-studio/.private/docs/engine/BEVY_ALIGNMENT_UPSTREAM_REQUESTS.md`

## 目标

这份台账用于集中记录所有“阻塞 `mgstudio-engine` 严格对齐 Bevy，但问题不应在本仓库内部硬补”的事项。

台账的用途只有三个：

1. 把依赖缺口从本地临时修补里分离出来，避免把上游问题塞进 `.mooncakes` 或私有 fork。
2. 为 Wave A/Wave C/Wave D 等后续执行波次提供统一的“上游请求入口”，保证每个 blocker 都能落到具体维护者、具体 API、具体复现。
3. 保证所有上报都以 Bevy 基线为准，而不是以“当前能跑”为准。

非目标：

- 不记录纯内部重构任务。
- 不记录已经决定接受的非 1:1 偏差；这类内容应进入例外台账。
- 不把“还没整理清楚”的猜测直接发给上游维护者。

## 适用范围

本台账只覆盖以下类型的问题：

1. MoonBit 语言、编译器、运行时、FFI 或工具链限制，导致 Bevy 等价设计无法直接表达。
2. `wgpu_mbt` 缺失的 GPU 能力或 API 面，导致渲染、截图、readback、纹理视图、surface 管理无法 1:1 对齐。
3. windowing / input / gamepad / IME 社区库缺口，导致 `bevy_window`、`bevy_input`、`bevy_winit` 相关示例只能做 adapted/fallback。
4. audio 社区库缺口，导致 `bevy_audio` 示例与 API 无法迁移。
5. a11y 社区库缺口，导致 `bevy_a11y` 与 AccessKit 相关语义只能部分对齐。

不在范围内：

- `mgstudio-engine` 自身实现错误。
- 可在本仓库内按 Bevy 结构直接补齐、且不需要上游新能力的缺口。
- 为了赶进度而在 `.mooncakes`、临时补丁目录、私有镜像里偷偷修掉的问题。

## 记录原则

1. 每条请求必须能回答“为什么这是上游问题，而不是我们自己的实现欠账”。
2. 每条请求必须绑定至少一个 Bevy 基线引用，优先使用 `bevy/crates/**` 或 `bevy/examples/**`。
3. 每条请求必须绑定至少一个当前仓库证据，优先使用 parity note、gap audit、接口草案或实际代码路径。
4. 每条请求必须写清楚本地临时绕行方案，避免后续重复发明 workaround。
5. 如果只知道“有问题”，但还不能给出最小复现，状态只能是“待整理”，不能直接标记“待上报”。
6. 严禁因为上游缺口而直接修改 `.mooncakes`。如确需临时绕行，只能在本仓库显式记录原因、风险和退出条件。

## 记录模板

每个条目按下面模板填写。

```md
### [请求编号] 标题
- 类别：MoonBit | wgpu_mbt | windowing | input | audio | a11y | other
- 目标上游：仓库 / 包 / 维护者群
- 优先级：P0 | P1 | P2 | P3
- 状态：待整理 | 待上报 | 已上报 | 等待反馈 | 已关闭 | 已转内部处理
- 首次记录：YYYY-MM-DD
- 最后确认：YYYY-MM-DD
- 阻塞范围：受影响的 Bevy crate / example / mgstudio 子系统
- Bevy 基线：对应的 Bevy 路径、行为或 API
- 当前缺口：当前上游依赖缺失了什么
- 本地现状：当前仓库如何绕行、退化或 fallback
- 期望上游能力：希望上游提供的最小 API / 行为 / 保证
- 最小复现：最小代码、命令、输入条件、平台信息
- 证据：本仓库内的文档或代码路径
- 建议反馈话术：发给上游维护者时的一段最小摘要
- 退出条件：什么情况下这条可以关闭
- 备注：风险、兼容性、是否需要拆分子请求
```

## 优先级规则

- `P0`：当前波次的“严格 1:1 对齐”被直接卡死，且没有可接受的临时替代；继续实现只会制造错误抽象或大量返工。
- `P1`：存在临时绕行，但它会强迫我们引入长期不想保留的 adapted/fallback 路径，或者会阻塞一整类 Bevy 示例/模块。
- `P2`：不会立刻卡死当前波次，但已经明确会在后续波次形成批量返工或 API 债务。
- `P3`：影响边缘能力、低频平台或后续增强项，先记录，等主路径收敛后再推动。

优先级判定附加规则：

1. 同时阻塞多个 Bevy 示例类别时，优先级上调一级。
2. 只影响单个 demo，但会迫使宿主 ABI 扭曲时，至少记为 `P1`。
3. 如果问题本质是“我们还没实现”，不能因为困难就标高优先级并甩给上游。
4. 如果一个大请求能明确拆成两个更小、可执行的请求，优先拆分，避免给上游丢巨型 wishlist。

## 反馈给依赖库开发者的最小信息集

任何准备发给上游维护者的请求，最少必须包含以下信息：

1. 依赖名称、版本、commit 或发布时间。
2. 使用平台：macOS/Linux/Web/WASM、运行时、编译器版本。
3. 最小复现代码或最小调用序列，不能只贴业务代码截图。
4. 实际行为与期望行为。
5. 为什么期望行为不是项目私有需求，而是通用能力。
6. 对应的 Bevy 基线路径或官方示例，说明我们在对齐什么。
7. 当前 workaround，以及这个 workaround 为什么不可长期接受。
8. 风险范围：影响哪些模块、示例、平台。
9. 期望的最小 API 形状或行为约束，不要只说“请支持某某功能”。
10. 如果有兼容性顾虑，明确说明是否接受新增 API、feature flag、实验接口或分阶段落地。

建议附带但不是硬性要求：

- 最小日志。
- 失败截图或录屏。
- 指向本仓库 parity note / audit 的链接或路径。
- 我们愿意接受的替代设计边界。

## 当前已知需要上报的类别

### 1. MoonBit 语言与工具链限制

已知关注点：

- 泛型 trait / 更强 trait 参数化能力不足，限制 Bevy 风格 Query/SystemParam 抽象。
- JS/WASM 边界上的 `String` ABI 约束，迫使宿主接口使用 `Int` 字符串句柄绕行。
- 部分需要在语言层或 FFI 层稳定承诺的能力，当前只能通过代码生成或宿主适配规避。

### 2. `wgpu_mbt` GPU 能力缺口

已知关注点：

- framebuffer / texture / buffer readback 能力不足。
- 截图导出链路缺失。
- GPU indirect 参数或统计结果无法稳定 readback，影响可观测性与严格 parity 验证。
- 纹理视图维度与 cubemap 相关控制面仍可能不足，后续需继续收敛。

### 3. `windowing` 社区库缺口

已知关注点：

- 多窗口创建、销毁、事件路由、渲染目标绑定。
- monitor 枚举、显示信息、scale factor、窗口归属信息。
- 一些窗口级行为当前只能记录日志，无法精确复现 Bevy 示例。

### 4. `input` 社区库缺口

已知关注点：

- IME/preedit/commit/cancel 事件模型缺失。
- 文本输入与逻辑按键载荷不完整。
- 某些输入行为只能通过 polling 或本地拼装事件重建，无法达到 Bevy 语义。

### 5. `audio` 社区库缺口

已知关注点：

- `bevy/examples/audio/*.rs` 当前整体阻塞。
- 解码、播放控制、pitch/rate、loop、soundtrack、2D/3D spatial audio 等能力仍未形成可对齐表面。

### 6. `a11y` 社区库缺口

已知关注点：

- AccessKit 树更新、焦点同步、动作回传、数值与文本变更粒度是否足以覆盖 Bevy 对齐需求。
- 当前 `a11y` 包已存在，但“存在 API”不等于“语义完全对齐”。

## 当前可预见的示例请求条目

以下条目是“现在就可以整理并准备上报”的样本，不代表完整 backlog。

### [UP-MOONBIT-001] 支持泛型 trait 或等价机制以表达 Query/SystemParam 抽象
- 类别：MoonBit
- 目标上游：MoonBit language / compiler
- 优先级：P1
- 状态：待整理
- 首次记录：2026-03-06
- 最后确认：2026-03-06
- 阻塞范围：`bevy_ecs` 风格 Query API；`mgstudio-engine/app` 与 `mgstudio-engine/core/query` 的 Bevy 对齐体验
- Bevy 基线：系统参数与 Query 能以签名级抽象表达依赖，而不是靠每次传 getter 函数
- 当前缺口：MoonBit 当前无法直接使用类似 `trait X[T]` 的泛型 trait 写法，导致 Query store/provider 抽象不能按原设计落地
- 本地现状：改用代码生成 getter 函数和 `App::add_system_queryN` 作为折中路径，减少样板但仍非 Bevy 式签名体验
- 期望上游能力：支持泛型 trait，或提供等价的语言机制，允许以类型参数抽象 store/provider/query accessor
- 最小复现：尝试定义带类型参数的 trait，例如 `trait QueryStore[T] { ... }`，当前会在语法层失败
- 证据：`.private/docs/engine/query_phase2_non_generic_trait_2026-02-28.md`、`.private/docs/engine/APP_GENERIC_WORLD.md`
- 建议反馈话术：我们在对齐 Bevy ECS Query API 时，需要以类型参数抽象 query store/provider；当前 MoonBit 缺少泛型 trait 或等价机制，迫使我们退回代码生成 getter + 手写注册入口，导致 API 形状长期偏离上游设计。希望讨论最小可行的语言支持或替代方案。
- 退出条件：MoonBit 提供可落地的泛型 trait 或官方推荐的等价抽象能力，且能消除当前 getter 生成式 workaround
- 备注：这不是“想要更好语法糖”，而是直接影响 Query/SystemParam 是否能保持可扩展结构

### [UP-WGPU-MBT-001] 提供稳定的 GPU readback / screenshot 导出能力
- 类别：wgpu_mbt
- 目标上游：`wgpu_mbt`
- 优先级：P1
- 状态：待整理
- 首次记录：2026-03-06
- 最后确认：2026-03-06
- 阻塞范围：`bevy/examples/window/screenshot.rs`、`3d/occlusion_culling` 等依赖 readback 可观测性的对齐项
- Bevy 基线：支持对 framebuffer、纹理或 buffer 做可控 readback，用于截图、统计回读、调试验证
- 当前缺口：当前路径缺少 framebuffer screenshot capture/export API，也缺少稳定的 GPU 间接参数或统计结果 readback 路径
- 本地现状：示例只能退化为 `window.host_debug_string` 日志证明行为，无法给出与 Bevy 等价的截图/回读结果
- 期望上游能力：提供最小 readback API，至少覆盖 render target / staging buffer 回读，以及可用于 screenshot 导出的稳定路径
- 最小复现：运行 `mgstudio-engine/examples/window/screenshot` 或尝试为 `occlusion_culling` 增加 GPU 结果回读，当前无对应宿主/后端能力可调用
- 证据：`docs/parity/notes/window_screenshot.md`、`docs/parity/notes/3d_alignment_round3_worker_b.md`、`docs/parity/notes/3d_alignment_worker_remaining_round2_a.md`
- 建议反馈话术：我们在对齐 Bevy 的 screenshot 和 occlusion 可观测性路径时，需要最小化的 GPU readback 能力；当前 `wgpu_mbt` 路径没有稳定的 screenshot/export 或 staging readback API，导致这类示例只能保留日志版 adapted 行为。希望讨论一个小而稳定的 readback surface。
- 退出条件：可以稳定回读截图或缓冲区结果，并在至少一个截图示例和一个 readback 依赖示例中闭环验证
- 备注：如果上游希望分阶段，可先交付 buffer readback，再补 texture/surface 导出

### [UP-WINDOWING-001] 提供多窗口编排与 monitor 枚举能力
- 类别：windowing
- 目标上游：windowing 社区库 / native window host backend
- 优先级：P1
- 状态：待整理
- 首次记录：2026-03-06
- 最后确认：2026-03-06
- 阻塞范围：`bevy/examples/window/multiple_windows.rs`、`multi_window_text.rs`、`monitor_info.rs`
- Bevy 基线：支持多窗口创建与标识、事件路由、窗口目标选择、monitor 枚举与显示信息读取
- 当前缺口：当前路径没有稳定的 secondary window orchestration API、multi-window target routing API、monitor enumeration/details API
- 本地现状：相关示例只能输出日志，无法真实绑定第二窗口、目标窗口文本或 monitor 信息
- 期望上游能力：至少提供窗口创建/销毁、稳定窗口 ID、按窗口路由事件与渲染目标、monitor 列表与基础属性读取
- 最小复现：尝试迁移 `mgstudio-engine/examples/window/multiple_windows`、`multi_window_text`、`monitor_info` 为 exact 行为，当前缺少宿主接口
- 证据：`docs/parity/notes/window_multiple_windows.md`、`docs/parity/notes/window_multi_window_text.md`、`docs/parity/notes/window_monitor_info.md`、`.private/docs/engine/HOST_INTERFACE.md`
- 建议反馈话术：我们在对齐 Bevy window 类示例时，需要最小多窗口与 monitor surface。当前 host/windowing 路径仅够单窗口与基本轮询，无法表达 Bevy 的 secondary window、target routing 和 monitor inspection。希望讨论分阶段补齐的最小 API。
- 退出条件：上述三个窗口示例至少能从 adapted/logging 收敛到真实窗口行为
- 备注：建议先交付窗口 ID 与 monitor API，再补多窗口渲染目标路由

### [UP-INPUT-001] 提供 IME / composition / logical-key 完整输入事件模型
- 类别：input
- 目标上游：input 社区库 / host input backend
- 优先级：P1
- 状态：待整理
- 首次记录：2026-03-06
- 最后确认：2026-03-06
- 阻塞范围：`bevy/examples/input/text_input.rs`、`keyboard_input_events.rs` 以及后续依赖 IME 的 UI/文本输入能力
- Bevy 基线：具备 IME enabled、preedit、commit/cancel、逻辑按键、文本输入生命周期等事件模型
- 当前缺口：当前路径没有 Bevy 类似的 `Ime` message stream，`KeyboardInput.logical_key` 虽部分可用，但 composition/layout-aware 行为不完整
- 本地现状：`text_input` 只能以简化编辑缓冲和日志方式维持交互，无法复现 Bevy 的完整输入语义
- 期望上游能力：提供 IME 事件流、preedit/commit/cancel 生命周期、逻辑按键与必要的窗口/焦点关联信息
- 最小复现：运行 `mgstudio-engine/examples/input/text_input`，开启 IME 输入并观察当前只能处理简化字符追加，无法得到完整 composition 语义
- 证据：`docs/parity/notes/input_text_input.md`、`docs/parity/notes/input_keyboard_input_events.md`
- 建议反馈话术：我们在对齐 Bevy 文本输入行为时，需要的不只是 key polling，而是完整的 IME/composition 事件模型。当前输入路径能覆盖部分 `logical_key`，但不足以承载 preedit/commit/cancel 与布局相关行为。希望讨论最小 IME surface。
- 退出条件：`text_input` 从 adapted 收敛为 exact 或接近 exact，且后续 UI 文本输入不再需要自造事件拼装
- 备注：如果上游担心一次做大，可以先交付 preedit + commit 两段式模型

### [UP-AUDIO-001] 提供可覆盖 Bevy 示例的基础播放控制与空间音频能力
- 类别：audio
- 目标上游：`moon_cpal` / `moon_rodio`
- 优先级：P1
- 状态：待整理
- 首次记录：2026-03-06
- 最后确认：2026-03-06
- 阻塞范围：`bevy/examples/audio/*.rs` 全部 7 个示例当前处于 `Blocked`
- Bevy 基线：基础音频播放、控制、可解码源、pitch/rate 调整、soundtrack、2D/3D spatial audio
- 当前缺口：当前仓库已接入 `moon_cpal`、`moon_rodio`，但尚未形成足够覆盖 Bevy 音频示例的稳定 API 组合
- 本地现状：音频类别示例还没有迁移入口，当前只能在依赖层能力未清晰前保持阻塞
- 期望上游能力：提供明确的播放控制表面（播放/暂停/停止/循环/状态）、可解码资源接入、pitch 或等价速率控制、listener/emitter 或等价空间音频模型
- 最小复现：对照 `docs/parity/bevy_example_parity_matrix.md` 中音频 7 个示例，尝试建立统一 runtime API 时会遇到能力面缺口无法收敛
- 证据：`docs/parity/bevy_api_parity_matrix.md`、`docs/parity/bevy_example_parity_matrix.md`、`.private/docs/engine/MGSTUDIO_BEVY_FULL_GAP_AUDIT_2026-03-05.md`
- 建议反馈话术：我们已接入 `moon_cpal` / `moon_rodio`，但在对齐 Bevy 音频示例时，仍缺少足够稳定且可组合的播放控制、解码与空间音频 surface。希望先讨论一个能覆盖基础 `audio/audio_control/pitch/soundtrack/spatial_audio_*` 的最小交集 API。
- 退出条件：至少能支撑第一批 Bevy 音频示例迁移，并形成可复用的 engine-level audio surface
- 备注：如需拆分，优先拆成“基础播放控制”和“空间音频”两条请求

## 后续维护约定

1. 新增条目时，优先补“最小复现”和“建议反馈话术”，这两项缺失时不允许直接对外发送。
2. 一条请求一旦进入“已上报”，必须记录上报位置，例如 issue 链接、讨论串或 commit 引用。
3. 上游如果给出 workaround 或拒绝理由，必须回填到本台账，而不是只留在聊天记录里。
4. 当某个缺口被证明更适合内部实现时，将状态改为“已转内部处理”，并注明原因，避免长期悬挂。
