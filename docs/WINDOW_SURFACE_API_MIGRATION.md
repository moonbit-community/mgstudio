# Window Surface Typed-Handle API Migration

This document records the intentional source-breaking window-surface API
changes introduced after upgrading to `Milky2018/window@0.6.0`,
`Milky2018/windowing@0.1.0`, and `Milky2018/wgpu_mbt@0.15.0`.

## Invariant

`RawHandleWrapper` now owns a typed `WindowHandle` and `DisplayHandle` for its
entire lifetime. Render code consumes that wrapper directly. It no longer
looks up an AppKit `NSView` encoded as `UInt64` from a numeric host-window ID.

## Public API changes

| Removed or changed API | Replacement |
|---|---|
| `WindowWrapper` | Removed. Typed handles already retain their providers. |
| `RawHandleWrapper::new(WindowWrapper)` | `RawHandleWrapper::new(HostWindow, WindowHandle, DisplayHandle)` |
| `RawHandleWrapper::content_view_handle() -> UInt64?` | Removed. Pass `RawHandleWrapper` to typed surface APIs. |
| `RawHandleWrapper::window_handle() -> WindowHandle?` | `RawHandleWrapper::window_handle() -> WindowHandle` |
| `RawHandleWrapper::display_handle() -> DisplayHandle?` | `RawHandleWrapper::display_handle() -> DisplayHandle` |
| `windowing_native::{content_view_handle, window_handle, display_handle}` | `windowing_native::handles(HostWindow) -> (WindowHandle, DisplayHandle)?` at the native-window ownership boundary |
| `host_gpu_create_surface(HostWindow)` | `host_gpu_create_surface(RawHandleWrapper)` |
| renderer `create_surface(HostWindow)` and `GpuBackend::create_surface(HostWindow)` | Pass `RawHandleWrapper` instead. |
| `WindowSurfaceCreateError::MissingContentViewHandle` | Removed. Typed-handle provider failures are reported as `NativeSurfaceCreateFailed`. |

The normal application path does not construct these handles manually. The
window runtime creates the wrapper when it creates the native window, stores
it as the `RawHandleWrapper` component, and render extraction or custom
runners read that component.

Custom runners that previously retained only `HostWindow` must retain or query
the corresponding `RawHandleWrapper` component and pass it to
`host_gpu_create_surface`.
