# AGENTS.md

The role of this file is to describe common mistakes and confusion points that agents might encounter as they work in this project. If you ever encounter something in the project that surprises you, please alert the developer working with you and indicate that this is the case in the AGENTS.md file to help prevent future agents from having the same issue.

- `Milky2018/wgpu_mbt@0.12.9` added macOS `NSView*` compatibility helpers that accept `UInt64` handles from `Milky2018/window@0.4.1`. Use `Instance::create_surface_macos_ns_view_u64` with `Window::content_view_handle()` data instead of reintroducing project-local `CAMetalLayer` attach stubs or unsafe casts.
- When `moon test` fails with a tcc framework lookup error, rerun the same test with `--release`.
