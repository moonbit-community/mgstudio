# Wave A 视觉门设计（固定机位截图门）

## 1. 目标与范围

本文定义 Wave A 的固定机位截图门（Visual Gate）规范，用于对比 `mgstudio-engine` 与 Bevy 在同一场景下的渲染结果一致性。  
本阶段目标是建立可重复、可回归、可审计的最小视觉基线流程，不覆盖性能门与动态镜头路径。

## 2. 样例集合（Wave A）

Wave A 最小样例集如下（必须全部纳入）：

1. `examples/3d/3d_scene`
2. `examples/3d/3d_shapes`
3. `examples/2d/2d_shapes`

建议可扩展样例（非阻塞）：

1. `examples/3d/tonemapping`
2. `examples/2d/bloom_2d`
3. `examples/3d/pbr`

样例选择原则：

1. 覆盖 2D/3D 两类管线。
2. 覆盖几何、材质、光照的基础组合。
3. 优先选择启动稳定、帧间抖动低的样例。

## 3. 固定策略（相机 / 光照 / 窗口）

为保证可复现性，截图前统一执行“状态冻结”。

### 3.1 窗口与渲染尺寸固定

1. 统一输出尺寸：`1280x720`（Wave A 默认）。
2. 禁止运行时窗口缩放、DPI 自适应导致的实际渲染尺寸漂移。
3. 固定颜色空间与输出格式（如 sRGB 路径保持一致）。
4. 禁用 VSync 对截图时机的影响（截图触发基于逻辑帧，而非墙钟时间）。

### 3.2 相机固定

1. 每个样例提供显式相机配置（位置、朝向、FOV/正交参数、near/far）。
2. 截图时禁用相机控制输入（鼠标/键盘/手柄）。
3. 对多相机场景，明确 `camera_id` 与激活优先级，避免“最后写入覆盖”不确定性。
4. 截图帧号固定（例如预热 `N=60` 帧后在第 `61` 帧采集）。

### 3.3 光照固定

1. 固定主光源类型与参数（方向/点光、强度、颜色、阴影开关）。
2. 固定环境光与曝光链路（包括 tonemapping 选项）。
3. 禁用时间驱动的光照动画与随机扰动。
4. 若样例自带旋转光源，截图模式下必须锁定为常量姿态。

## 4. 输出产物路径约定

统一以“运行批次”为最小隔离单元，推荐目录：

```text
.private/artifacts/visual-gates/wave-a/
  bevy/
    <example_slug>/
      images/
      metadata/
  mgstudio/
    <example_slug>/
      images/
      metadata/
  diff/
    <example_slug>/
      heatmap/
      report/
```

约束：

1. `bevy/` 保存对照基线截图与元数据。
2. `mgstudio/` 保存被测引擎截图与元数据。
3. `diff/` 保存差异热图与机器判定报告。
4. 同一 `<example_slug>` 下必须包含同名截图对。

## 5. 截图命名约定

文件名格式：

```text
<example_slug>__<engine>__cam-<camera_id>__frame-<frame_index>__w-<width>h-<height>.png
```

示例：

```text
3d_scene__bevy__cam-main__frame-0061__w-1280h-720.png
3d_scene__mgstudio__cam-main__frame-0061__w-1280h-720.png
```

配套元数据文件（JSON）同名：

```text
3d_scene__bevy__cam-main__frame-0061__w-1280h-720.json
```

元数据最小字段：

1. `example_slug`
2. `engine`
3. `frame_index`
4. `width` / `height`
5. `camera`（位置、朝向、投影参数）
6. `lighting`（关键灯光参数）
7. `renderer`（后端、色彩空间、tonemapping）
8. `git_commit`

## 6. Bevy 对照基线采集办法

### 6.1 采集原则

1. 基线必须由 vendored `bevy/` 工程直接生成，不使用外部二次截图工具。
2. 与 `mgstudio-engine` 使用同一固定配置（尺寸、帧号、相机、光照参数）。
3. 每次更新 Bevy 基线需记录变更原因（Bevy 升级 / 样例逻辑变动 / 渲染路径调整）。

### 6.2 采集流程（最小）

1. 启动目标样例（`examples/3d/3d_scene` 等）。
2. 注入或启用截图门配置（固定窗口、固定相机、固定帧号）。
3. 预热固定帧数（建议 `60` 帧）。
4. 在指定帧写出 PNG 与元数据 JSON 到 `bevy/<example_slug>/...`。
5. 对同一提交重复采集 2 次，哈希一致后确认为稳定基线。

### 6.3 基线版本管理

1. 基线目录按 `wave-a` 固定，不混入其他波次。
2. 基线变更必须伴随 `report` 记录：变更前后缩略图、原因、影响样例列表。
3. 若仅个别样例更新，不得重写全部基线。

## 7. Diff 判定规则

Wave A 采用“硬阈值 + 感知阈值”双轨判定。

### 7.1 指标

1. 像素绝对差比例（Pixel Diff Ratio）：
   `diff_pixels / total_pixels`
2. SSIM（结构相似性）：
   范围 `[0, 1]`，越高越接近。

### 7.2 默认阈值

1. `Pixel Diff Ratio <= 0.001`（0.1%）且 `SSIM >= 0.995`：通过。
2. `0.001 < Pixel Diff Ratio <= 0.003` 或 `0.990 <= SSIM < 0.995`：告警，进入人工复核。
3. `Pixel Diff Ratio > 0.003` 或 `SSIM < 0.990`：失败。

### 7.3 屏蔽规则（最小）

1. 禁止全图模糊屏蔽；仅允许声明式局部 mask（例如 UI 时间戳区域）。
2. 每个 mask 必须在元数据中记录坐标与理由。
3. 新增 mask 需要人工审批后生效。

## 8. 人工复核触发条件

满足任一条件即触发人工复核：

1. 告警区间结果（见 7.2 第 2 条）。
2. 首次纳入的新样例。
3. Bevy 基线刚更新后的首轮回归。
4. 渲染后端切换（如 Vulkan/Metal/DX12）导致系统性偏差。
5. 出现“局部高亮/阴影边界”类肉眼可见伪影，即使数值未超阈值。

人工复核记录最小内容：

1. 对比图（baseline / candidate / heatmap）。
2. 判定结论（接受 / 驳回 / 需修复后重跑）。
3. 责任模块与后续 action owner。

## 9. Wave A 落地检查清单

1. 三个必选样例均有 Bevy 与 mgstudio 成对截图。
2. 每对截图均有同名 JSON 元数据。
3. 自动 diff 报告完整输出到 `diff/report/`。
4. 所有失败项均有 issue 或复核结论。
5. 基线版本与被测提交号可追溯。

