// Copyright 2025 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Native host stubs for `mgstudio_host` and `moonbit:ffi`.
///
/// This is a "bring-up" implementation: enough to instantiate and start running
/// the wasm-gc build. Real window/GPU/input implementations will be added later.
///
/// Important: the wasm imports' signatures must match the runner.wasm import
/// section; otherwise instantiation fails.

///|
pub struct HostContext {
  mut store : @runtime.Store?
  mut instance : @runtime.ModuleInstance?
  mut gpu : GpuBackend?
  mut window : @win.Window?
  next_closure_id : Ref[Int]
  closures : Ref[Array[(Int, @types.Value, Int)]]
  // (id, env, func_idx)
  string_sink : Ref[String]
}

///|
pub fn HostContext::new() -> HostContext {
  HostContext::{
    store: None,
    instance: None,
    gpu: None,
    window: None,
    next_closure_id: Ref::new(1),
    closures: Ref::new([]),
    string_sink: Ref::new(""),
  }
}

///|
fn ft(
  params : Array[@types.ValueType],
  results : Array[@types.ValueType],
) -> @types.FuncType {
  { params, results }
}

///|
fn alloc_closure(ctx : HostContext, func_idx : Int, env : @types.Value) -> Int {
  let id = ctx.next_closure_id.val
  ctx.next_closure_id.val = id + 1
  ctx.closures.val.push((id, env, func_idx))
  id
}

///|
fn ok_i32(value : Int) -> Array[@types.Value] {
  [@types.Value::I32(value)]
}

///|
fn ok_f32(value : Float) -> Array[@types.Value] {
  [@types.Value::F32(value)]
}

///|
fn ok_extern_null() -> Array[@types.Value] {
  [@types.Value::Null]
}

///|
fn ok_extern_ref(id : Int) -> Array[@types.Value] {
  [@types.Value::ExternRef(id)]
}

///|
const HANDLE_BASE : Int = 10_000

///|
pub fn add_mgstudio_host_imports(
  linker : @runtime.Linker,
  ctx : HostContext,
) -> Unit {
  linker.add_host_func(
    "mgstudio_host",
    "string_sink_push",
    fn(_args) {
      // No-op in native bring-up. Web uses this to reconstruct strings in a
      // fallback path; native can implement it later if needed.
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "debug_string",
    fn(_args) {
      // Bring-up: ignore.
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::RefArray(1)], [@types.ValueType::I32]),
  )

  // Window.
  linker.add_host_func(
    "mgstudio_host",
    "window_create",
    fn(args) {
      let width = if args.length() >= 1 && args[0] is @types.Value::I32(w) {
        w
      } else {
        800
      }
      let height = if args.length() >= 2 && args[1] is @types.Value::I32(h) {
        h
      } else {
        600
      }
      // Title is a wasm-gc string/arrayref in practice; we ignore it for now and
      // use a fixed ASCII title. This avoids depending on guest string decoding
      // during bring-up.
      let win = @win.Window::create(width, height, "Moon Game Studio")
      ctx.window = Some(win)
      ok_extern_ref(HANDLE_BASE + 1)
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::RefArray(1),
      ],
      [@types.ValueType::ExternRef],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_run_loop",
    fn(args) {
      if args.length() == 0 {
        return ok_i32(0)
      }
      if args[0] is @types.Value::FuncRef(func_idx) {
        guard ctx.store is Some(store) else { return ok_i32(0) }
        guard ctx.instance is Some(instance) else { return ok_i32(0) }
        while true {
          if ctx.window is Some(win) {
            win.poll_events()
            if win.should_close() {
              break
            }
          }
          let _ = @executor.call_func_by_index(store, instance, func_idx, [])
            |> ignore

        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::FuncRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_poll_events",
    fn(_args) {
      ctx.window.map(fn(win) { win.poll_events() }) |> ignore
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_width",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.width())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_height",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_i32(win.height())
      } else {
        ok_i32(0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_scale_factor",
    fn(_args) {
      if ctx.window is Some(win) {
        ok_f32(win.scale_factor())
      } else {
        ok_f32(1.0)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_should_close",
    fn(_args) {
      if ctx.window is Some(win) && !win.should_close() {
        ok_i32(0)
      } else {
        ok_i32(1)
      }
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_request_close",
    fn(_args) {
      ctx.window.map(fn(win) { win.request_close() }) |> ignore
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )

  // Time.
  linker.add_host_func(
    "mgstudio_host",
    "time_now",
    fn(_args) { ok_f32(0.0) },
    func_type=ft([], [@types.ValueType::F32]),
  )

  // Input.
  linker.add_host_func(
    "mgstudio_host",
    "input_finish_frame",
    fn(_args) { ok_i32(0) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_has_cursor",
    fn(_args) { ok_i32(0) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_mouse_x",
    fn(_args) { ok_f32(0.0) },
    func_type=ft([], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_mouse_y",
    fn(_args) { ok_f32(0.0) },
    func_type=ft([], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "input_is_key_down",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::RefArray(1)], [@types.ValueType::I32]),
  )

  // Assets/GPU: stubs that return dummy ids / null handles.
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_texture",
    fn(_args) { ok_i32(1) },
    func_type=ft([@types.ValueType::RefArray(1), @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_wgsl",
    fn(_args) { ok_i32(1) },
    func_type=ft([@types.ValueType::RefArray(1)], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_font",
    fn(_args) { ok_i32(1) },
    func_type=ft([@types.ValueType::RefArray(1)], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_rasterize_glyph",
    fn(_args) { ok_i32(-1) },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_width",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_height",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_offset_x",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_glyph_offset_y",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "font_measure_advance",
    fn(_args) { ok_f32(0.0) },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::F32, @types.ValueType::I32],
      [@types.ValueType::F32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_set_texture_sampler",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_create_dynamic_texture",
    fn(_args) { ok_i32(1) },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::I32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_update_texture_region",
    fn(_args) { ok_i32(0) },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_texture_width",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_texture_height",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_is_texture_loaded",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_copy_texture_to_texture",
    fn(_args) { ok_i32(0) },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_load_folder",
    fn(_args) { ok_i32(1) },
    func_type=ft([@types.ValueType::RefArray(1)], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_poll_loaded_folder_event_kind",
    fn(_args) { ok_i32(-1) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_poll_loaded_folder_event_id",
    fn(_args) { ok_i32(-1) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_loaded_folder_handles_len",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::I32], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "asset_loaded_folder_handles_get",
    fn(_args) { ok_i32(-1) },
    func_type=ft([@types.ValueType::I32, @types.ValueType::I32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_request_device",
    fn(_args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      ok_extern_ref(HANDLE_BASE + 2)
    },
    func_type=ft([], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_surface",
    fn(_args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      if ctx.window is Some(win) {
        ctx.gpu.unwrap().create_surface(win)
      }
      ok_extern_ref(HANDLE_BASE + 3)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_configure_surface",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      if args.length() >= 4 &&
        args[2] is @types.Value::I32(width) &&
        args[3] is @types.Value::I32(height) {
        ctx.gpu.unwrap().configure_surface(width, height)
      }
      ok_i32(0)
    },
    func_type=ft(
      [
        @types.ValueType::ExternRef,
        @types.ValueType::ExternRef,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_begin_frame",
    fn(_args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      if ctx.window is Some(win) {
        ctx.gpu.unwrap().ensure_surface_configured(win.width(), win.height())
      }
      ctx.gpu.unwrap().begin_frame()
      ok_extern_ref(HANDLE_BASE + 4)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_begin_pass",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      if args.length() >= 15 &&
        args[0] is @types.Value::I32(target_id) &&
        args[1] is @types.Value::I32(width_logical) &&
        args[2] is @types.Value::I32(height_logical) &&
        args[3] is @types.Value::F32(clear_r) &&
        args[4] is @types.Value::F32(clear_g) &&
        args[5] is @types.Value::F32(clear_b) &&
        args[6] is @types.Value::F32(clear_a) &&
        args[7] is @types.Value::F32(camera_x) &&
        args[8] is @types.Value::F32(camera_y) &&
        args[9] is @types.Value::F32(camera_rot) &&
        args[10] is @types.Value::F32(camera_scale) &&
        args[11] is @types.Value::I32(vx) &&
        args[12] is @types.Value::I32(vy) &&
        args[13] is @types.Value::I32(vw) &&
        args[14] is @types.Value::I32(vh) {
        ctx.gpu
        .unwrap()
        .begin_pass(
          target_id, width_logical, height_logical, clear_r, clear_g, clear_b, clear_a,
          camera_x, camera_y, camera_rot, camera_scale, vx, vy, vw, vh,
        )
      }
      ok_i32(0)
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
        @types.ValueType::I32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_end_pass",
    fn(_args) {
      ctx.gpu.map(fn(gpu) { gpu.end_pass() }) |> ignore
      ok_i32(0)
    },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_end_frame",
    fn(_args) {
      ctx.gpu.map(fn(gpu) { gpu.end_frame() }) |> ignore
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_render_target",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      if args.length() >= 3 &&
        args[0] is @types.Value::I32(w) &&
        args[1] is @types.Value::I32(h) &&
        args[2] is @types.Value::I32(nearest_i32) {
        let id = ctx.gpu.unwrap().create_render_target(w, h, nearest_i32 != 0)
        ok_i32(id)
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::I32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_capsule",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      if args.length() >= 3 &&
        args[0] is @types.Value::F32(radius) &&
        args[1] is @types.Value::F32(half_len) &&
        args[2] is @types.Value::I32(segs) {
        ok_i32(ctx.gpu.unwrap().create_mesh_capsule(radius, half_len, segs))
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft(
      [@types.ValueType::F32, @types.ValueType::F32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_rectangle",
    fn(args) {
      if ctx.gpu is None {
        ctx.gpu = Some(GpuBackend::new())
      }
      if args.length() >= 2 &&
        args[0] is @types.Value::F32(w) &&
        args[1] is @types.Value::F32(h) {
        ok_i32(ctx.gpu.unwrap().create_mesh_rectangle(w, h))
      } else {
        ok_i32(-1)
      }
    },
    func_type=ft([@types.ValueType::F32, @types.ValueType::F32], [
      @types.ValueType::I32,
    ]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_triangles",
    fn(_args) { ok_i32(1) },
    func_type=ft([@types.ValueType::RefArray(1)], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_mesh",
    fn(args) {
      if ctx.gpu is None {
        return ok_i32(0)
      }
      if args.length() >= 10 &&
        args[0] is @types.Value::I32(mesh_id) &&
        args[1] is @types.Value::F32(x) &&
        args[2] is @types.Value::F32(y) &&
        args[3] is @types.Value::F32(rot) &&
        args[4] is @types.Value::F32(sx) &&
        args[5] is @types.Value::F32(sy) &&
        args[6] is @types.Value::F32(r) &&
        args[7] is @types.Value::F32(g) &&
        args[8] is @types.Value::F32(b) &&
        args[9] is @types.Value::F32(a) {
        ctx.gpu.unwrap().draw_mesh(mesh_id, x, y, rot, sx, sy, r, g, b, a)
      }
      ok_i32(0)
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_sprite_uv",
    fn(args) {
      if ctx.gpu is None {
        return ok_i32(0)
      }
      if args.length() >= 14 &&
        args[0] is @types.Value::I32(texture_id) &&
        args[1] is @types.Value::F32(x) &&
        args[2] is @types.Value::F32(y) &&
        args[3] is @types.Value::F32(rot) &&
        args[4] is @types.Value::F32(sx) &&
        args[5] is @types.Value::F32(sy) &&
        args[6] is @types.Value::F32(r) &&
        args[7] is @types.Value::F32(g) &&
        args[8] is @types.Value::F32(b) &&
        args[9] is @types.Value::F32(a) &&
        args[10] is @types.Value::F32(uv_min_x) &&
        args[11] is @types.Value::F32(uv_min_y) &&
        args[12] is @types.Value::F32(uv_max_x) &&
        args[13] is @types.Value::F32(uv_max_y) {
        ctx.gpu
        .unwrap()
        .draw_sprite_uv(
          texture_id, x, y, rot, sx, sy, r, g, b, a, uv_min_x, uv_min_y, uv_max_x,
          uv_max_y,
        )
      }
      ok_i32(0)
    },
    func_type=ft(
      [
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
      ],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_draw_gizmo_line",
    fn(_args) { ok_i32(0) },
    func_type=ft(
      [
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::F32,
        @types.ValueType::I32,
        @types.ValueType::F32,
        @types.ValueType::F32,
      ],
      [@types.ValueType::I32],
    ),
  )
}

///|
pub fn add_moonbit_ffi_imports(
  linker : @runtime.Linker,
  ctx : HostContext,
) -> Unit {
  linker.add_host_func(
    "moonbit:ffi",
    "make_closure",
    fn(args) {
      if args.length() >= 2 && args[0] is @types.Value::FuncRef(func_idx) {
        let env = args[1]
        let id = alloc_closure(ctx, func_idx, env)
        [@types.Value::ExternRef(id)]
      } else {
        ok_extern_null()
      }
    },
    func_type=ft([@types.ValueType::FuncRef, @types.ValueType::AnyRef], [
      @types.ValueType::ExternRef,
    ]),
  )
}
