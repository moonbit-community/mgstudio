# window_settings Parity Note

- Bevy source: `bevy/examples/window/window_settings.rs`
- mgstudio target: `mgstudio-engine/examples/window/window_settings/`
- Status: Exact
- Owner: team-input_window

## Behavioral Comparison

- Runtime behavior is aligned:
  - startup window config (`title`, `name`, `resolution`, `present_mode`, theme, enabled buttons, initially hidden)
  - frame-count based visibility toggle (`visible = true` at frame 3)
  - key controls for vsync/theme/window level/window controls/cursor behavior
  - mouse left/right cycles cursor icon index

## Validation Evidence

- Check command:
  - `moon -C mgstudio-engine check --target native examples/window/window_settings`
- Screenshot command:
  - `MGSTUDIO_SCREENSHOT_PATH=/Users/zhengyu/Documents/projects/moon-game-studio/docs/parity/artifacts/window_window_settings_latest.png MGSTUDIO_SCREENSHOT_FRAME=120 MGSTUDIO_SCREENSHOT_EXIT_ON_SAVE=1 MGSTUDIO_WINDOW_FRAME_LIMIT=240 moon -C mgstudio-engine run --target native examples/window/window_settings`
- Captured artifact:
  - `docs/parity/artifacts/window_window_settings_latest.png`

## Notes

- The startup system now spawns a default `Camera2d` so the window presents the engine clear color instead of a black frame.
