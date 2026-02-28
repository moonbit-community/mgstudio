# App Examples Alignment (2026-02-27)

Scope: `bevy/examples/app/*.rs` vs `mgstudio-engine/examples/app/*`.

## Result Snapshot

- Total app examples: 17
- Exact: 17
- Blocked: 0

## Bottom Modules Added for Parity

- `AppExit` event + `App::should_exit()`
- `ScheduleRunnerPlugin` (`run_once` / `run_loop`)
- `TaskPoolPlugin` + `TaskPoolOptions`
- `LogPlugin` (`custom_layer` / `fmt_layer`) + `*_once` logging
- `FileDragAndDrop` event pipeline (web + native-wasmtime)
- `RenderRuntimeError` + `RenderErrorPolicy` + handler hooks
- `asset_save_texture_png` host API (native-wasmtime PNG readback, web canvas export path)
- externally-driven runner path for manual frame pumping example

## Runtime Host Imports Added

- `app_run_loop`
- `app_request_close`
- `app_reset_close`
- `app_stdin_read_line_len`
- `app_stdin_read_line_code_unit`
- `task_pool_set_num_threads`
- `input_drag_and_drop_event_count`
- `input_drag_and_drop_event_kind`
- `input_drag_and_drop_event_len`
- `input_drag_and_drop_event_code_unit`
- `asset_save_texture_png`

## Updated Artifacts

- `docs/parity/bevy_example_parity.csv`
- `docs/parity/bevy_example_parity_matrix.md`
