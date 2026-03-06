# Wave A：Bevy 基线冻结与源映射（E0）

> 文档状态：Frozen（Wave A）  
> 生效日期：2026-03-06  
> 唯一基线路径：`/Users/zhengyu/Documents/projects/moon-game-studio/bevy`  
> 基线提交：`48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`

## 1. 唯一基线冻结说明（vendored `./bevy`）

1. Wave A（含 E0）所有“Bevy 对照”结论，**仅允许**引用 vendored `./bevy` 的源码与文档。
2. `./bevy` 当前冻结到提交 `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`，冻结后默认不跟随 upstream 漂移。
3. 若 upstream 文档/博客/示例与 vendored 内容不一致，**以 vendored `./bevy` 为准**。
4. 任何功能实现、缺陷分析、回归判定都必须可回溯到 `crate/file/symbol` 三级证据。
5. 解除冻结或升级基线只能通过“显式基线升级变更”（独立评审、更新本文件中的 commit 与映射状态）。

## 2. mgstudio 源映射规则（crate/file 级）

### 2.1 映射粒度与优先级

1. **crate 级映射**：先定义 Bevy crate 到 mgstudio 包（package/目录）的归属关系。
2. **file 级映射**：每个 E0 范围文件必须有明确来源文件（1:1、1:N、N:1 均可，但必须声明类型）。
3. **symbol 级映射**：核心类型/函数/常量（例如 `App`、`World`、`Handle<T>`、`Tonemapping`）需列出对应符号。
4. 优先保证**行为语义一致**，其次才是代码组织与性能策略一致。

### 2.2 标准记录字段

每条映射记录至少包含：

- `bevy_crate`
- `bevy_file`
- `bevy_symbols`
- `mgstudio_package`
- `mgstudio_file`
- `mgstudio_symbols`
- `mapping_type`（`DirectPort` / `SemanticPort` / `Adapter` / `Stub`）
- `parity_state`（`Aligned` / `Partial` / `Planned` / `Blocked`）

### 2.3 文件组织规则

1. Bevy `crates/<crate>/src/*.rs` 默认映射到 `mgstudio-engine/<module>/*.mbt`。
2. Bevy `examples/<group>/<name>.rs` 默认映射到 `mgstudio-engine/examples/<group>/<name>/main.mbt`。
3. 宿主桥接（窗口、输入、音频、GPU、a11y）统一落在 `mgstudio-engine/runtime_native/*`。
4. 着色器与渲染资产语义对照优先落在 `mgstudio-engine/assets/shaders/bevy/**` 与对应 runtime 管线代码。

## 3. E0 首版模块映射总表

| E0 模块 | Bevy 基线（crate/file/symbol） | mgstudio 映射（package/file/symbol） | 映射类型 | 当前状态 |
|---|---|---|---|---|
| ecs | `bevy_ecs` / `src/world/*`, `src/query/*`, `src/event/mod.rs` / `World`, `Query`, `Events` | `ecs/ecs.mbt`, `ecs/query.mbt`, `ecs/event.mbt` / `World`, `Query1/2/3`, `EventKey` | SemanticPort | Partial |
| app | `bevy_app` / `src/app.rs`, `src/sub_app.rs`, `src/main_schedule.rs`, `src/plugin*.rs` / `App`, `SubApp`, `Plugin`, schedules | `app/app.mbt`, `app/runtime_plugins.mbt` / `App`, `AppLabel`, `Plugin`, `ScheduleStage` | SemanticPort | Partial |
| asset（核心） | `bevy_asset` / `src/assets.rs`, `src/loader.rs`, `src/path.rs`, `src/folder.rs` / `Assets`, `Handle`, `AssetServer` | `asset/asset.mbt`, `asset/assets.mbt`, `asset/folder.mbt`, `runtime_native/native_asset/asset.mbt` / `Handle`, `AssetId`, `AssetServer` | SemanticPort + Adapter | Partial |
| asset（图像/纹理语义） | `bevy_image` + `bevy_render::texture` / `texture/*`, `fallback_image.rs` / `Image`, fallback texture | `asset/mipmap.mbt`, `asset/texture_atlas.mbt`, `assets/shaders/bevy/**`, `runtime_native/native_gpu/gpu.mbt` | SemanticPort + Adapter | Partial |
| render（主干） | `bevy_render` / `src/view/*`, `src/camera.rs`, `render_resource/*` | `render2d/render2d.mbt`, `render3d/render3d.mbt`, `runtime_native/native_gpu/gpu.mbt` | SemanticPort + Adapter | Partial |
| render（3D/core pipeline） | `bevy_core_pipeline` / `src/core_3d/mod.rs`, `src/tonemapping/mod.rs`, `src/tonemapping/node.rs` / `Core3d`, `Tonemapping` | `render3d/render3d.mbt`, `assets/shaders/bevy/bevy_core_pipeline/**` | SemanticPort | Partial |
| render（PBR/mesh material） | `bevy_pbr` / `src/material.rs`, `src/mesh_material.rs`, `src/render/mesh*.rs|wgsl` / `StandardMaterial`, mesh pipeline | `render3d/render3d.mbt`, `mesh/*`, `assets/shaders/bevy/bevy_pbr/**` / `StandardMaterial`, `Mesh3d`, `MeshMaterial3dBundle` | SemanticPort | Partial |
| input | `bevy_input` / `src/button_input.rs`, `src/keyboard.rs`, `src/mouse.rs`, `src/gamepad.rs` | `input/input.mbt`, `input/gamepad.mbt`, `runtime_native/native_input/input.mbt` / `ButtonInput`, `Key`, gamepad types | SemanticPort + Adapter | Partial |
| window | `bevy_window` / `src/window.rs`, `src/event.rs`, `src/cursor/*`, `src/system.rs` | `window/window.mbt`, `runtime_native/native_window/window.mbt` / `HostWindow`, `HostEvent`, `WindowMode` | SemanticPort + Adapter | Partial |
| a11y | `bevy_a11y` / `src/lib.rs` / accessibility plugin & state | `a11y/a11y.mbt`, `runtime_native/native_a11y/a11y.mbt` / `A11yState`, host bridge APIs | SemanticPort + Adapter | Partial |
| audio | `bevy_audio` / `src/audio.rs`, `src/audio_source.rs`, `src/sinks.rs` | `runtime_native/audio/moon.pkg`（当前占位） | Stub | Planned |
| examples | `bevy/examples/**`（如 `2d/sprite.rs`, `2d/bloom_2d.rs`, `3d/3d_scene.rs`） | `examples/2d/*/main.mbt`, `examples/3d/3d_scene/main.mbt` | SemanticPort | Partial |
| docs | `bevy/docs/*.md` + 各 crate `README.md` | `.private/docs/engine/*.md`, `mgstudio-engine/README.mbt.md` | SemanticPort | Partial |

## 4. 允许差异与不允许差异边界

### 4.1 允许差异（Allowed）

1. Rust -> MoonBit 的语法/类型系统差异导致的实现细节重排。
2. 单文件拆分或多文件合并（前提是语义与执行顺序不变）。
3. 宿主相关适配层（`runtime_native/*`）的接口封装差异。
4. 非 E0 目标特性的暂不实现，但必须标注 `Planned/Stub` 且不可伪装为 `Aligned`。
5. 性能优化实现路径不同，但不得改变可观察行为与默认值语义。

### 4.2 不允许差异（Not Allowed）

1. 未经记录地更改默认行为（尤其是渲染、相机、材质、输入、窗口事件语义）。
2. 未经记录地更改渲染关键链路语义（提取/准备/排队/渲染阶段、tonemapping、fallback 材质/纹理语义）。
3. 将 Bevy 明确错误路径静默吞掉，导致“看似运行但语义退化”。
4. 没有 `crate/file/symbol` 证据的“经验性对齐声明”。
5. 将 E0 必选模块标记为完成，但缺少对应文件级映射或示例验证。

## 5. 执行约束（Wave A）

1. Wave A 内新增或改动的 E0 相关实现，必须同步更新本映射文档状态字段。
2. 评审时以“先看映射证据、再看代码”作为默认流程。
3. 若出现基线冲突，先修正文档映射，再进入代码改动评审。
