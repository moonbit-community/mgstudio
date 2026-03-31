# RAPIER 3D Visual Audit

- 抓图目录：`/tmp/mgstudio_rapier_visual_3d_20260331`
- 接触板：`/tmp/mgstudio_rapier_visual_3d_20260331/contact_sheet.png`
- 校验方式：`visual_image_sanity.py`

## 明显异常

- `static_trimesh3`：画面几乎为空，只看到右上方一个很小的点，`ramp + bowl` 这类大体量几何没有正常进入画面，疑似相机 framing 或渲染/布局异常。

## 示例清单

- [x] `boxes3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/boxes3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/boxes3.sanity.json`
- [x] `character_controller3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/character_controller3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/character_controller3.sanity.json`
- [x] `contact_filter3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/contact_filter3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/contact_filter3.sanity.json`
- [x] `custom_system_setup3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/custom_system_setup3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/custom_system_setup3.sanity.json`
- [x] `debug_toggle3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/debug_toggle3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/debug_toggle3.sanity.json`
- [x] `debugdump3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/debugdump3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/debugdump3.sanity.json`
- [x] `despawn3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/despawn3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/despawn3.sanity.json`
- [x] `events3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/events3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/events3.sanity.json`
- [x] `joints3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/joints3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/joints3.sanity.json`
- [x] `joints_despawn3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/joints_despawn3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/joints_despawn3.sanity.json`
- [x] `locked_rotations3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/locked_rotations3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/locked_rotations3.sanity.json`
- [x] `multi_contexts3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/multi_contexts3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/multi_contexts3.sanity.json`
- [x] `multiple_colliders3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/multiple_colliders3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/multiple_colliders3.sanity.json`
- [x] `picking3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/picking3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/picking3.sanity.json`
- [x] `rapier_context_component`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/rapier_context_component.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/rapier_context_component.sanity.json`
- [x] `rapier_to_bevy_mesh`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/rapier_to_bevy_mesh.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/rapier_to_bevy_mesh.sanity.json`
- [x] `ray_casting3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/ray_casting3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/ray_casting3.sanity.json`
- [!] `static_trimesh3`：疑似异常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/static_trimesh3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/static_trimesh3.sanity.json`
- [x] `testbed3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/testbed3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/testbed3.sanity.json`
- [x] `voxels3`：正常，截图 `/tmp/mgstudio_rapier_visual_3d_20260331/voxels3.png`，sanity `/tmp/mgstudio_rapier_visual_3d_20260331/voxels3.sanity.json`

## 备注

- 本轮 20 个 3D rapier 示例均已生成截图；除 `static_trimesh3` 外未见明确的空场景、几何尖刺、鬼影拖尾或朝向错误。
