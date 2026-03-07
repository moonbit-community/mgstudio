# Bevy API Parity Matrix

Status: Active (SoT)
Last Verified: 2026-03-08
Scope: As-Implemented
Code References:
- `mgstudio-engine/`
- `bevy/crates/`
- `docs/parity/bevy_example_parity_matrix.md`
Superseded By: N/A
Notes:
- Baseline commit: `48ec375a3a3cdc904476ef1d13f9d71c9f2820d3`.
- Status vocabulary: `done`, `partial`, `missing`.

## Track A: Core/App/ECS/State/Time/Transform/Hierarchy

| Surface | Status | Notes |
| --- | --- | --- |
| `core` ECS, change detection, message reader | partial | Message/event semantics aligned for current examples; full API surface still expanding. |
| `app` schedules/run conditions/state transitions | partial | Baseline schedule sets exist; strict Bevy transition parity ongoing. |
| `time` fixed/variable stepping | partial | Core fixed-time exists; broader state/schedule interplay pending. |
| `transform` + hierarchy propagation | partial | 2D/3D propagation available; edge-case parity still pending. |

## Track B: Asset/Scene/GLTF/Animation

| Surface | Status | Notes |
| --- | --- | --- |
| typed asset events/load folder | partial | Load-folder/event support exists; full Bevy event parity not complete. |
| scene instantiation | missing | Scene example coverage is currently absent. |
| glTF pipeline subset | missing | GLTF example coverage is currently absent. |
| animation API | missing | Animation category not yet migrated. |

## Track C: Render Core + 3D

| Surface | Status | Notes |
| --- | --- | --- |
| camera/projection conversion APIs | partial | viewport/world conversion implemented; advanced camera effects pending. |
| PBR material surface | partial | Core material parameters available; many advanced features pending. |
| post-process and fog/probe hooks | missing | Needed for many 3D examples in backlog. |

## Track D: UI/Text/A11y

| Surface | Status | Notes |
| --- | --- | --- |
| UI style/layout widgets | partial | UI baseline exists; large UI example set still missing. |
| text pipeline compatibility | partial | Text2d/UI text path exists; full Bevy UI text feature parity pending. |
| accessibility integration | partial | a11y package exists; broader parity validation pending. |

## Track E: Input/Window/Gamepad/Touch

| Surface | Status | Notes |
| --- | --- | --- |
| keyboard/mouse/touch input | partial | Core input support exists; many input examples still missing. |
| gamepad events/state/rumble | partial | `gamepad_input_events` aligned; other gamepad examples pending. |
| window events/modes | partial | Window package exists; window example category not yet migrated. |

## Track F: Audio/Diagnostics/Remote/Dev Utilities

| Surface | Status | Notes |
| --- | --- | --- |
| audio | partial | `audio`, `audio_control`, `soundtrack`, `spatial_audio_2d`, and `spatial_audio_3d` are migrated; `decodable` and `pitch` remain blocked by asset/source registration and compiler limitations. |
| diagnostics | partial | `custom_diagnostic` and `enabling_disabling_diagnostic` are migrated; `log_diagnostics` remains blocked by system information and render diagnostics parity gaps. |
| remote/dev tooling parity | missing | Remote/dev_tools categories not yet migrated. |

## Ownership

- `team-core`: Track A
- `team-asset_scene`: Track B
- `team-render`: Track C
- `team-ui_text`: Track D
- `team-input_window`: Track E
- `team-ops`: Track F
