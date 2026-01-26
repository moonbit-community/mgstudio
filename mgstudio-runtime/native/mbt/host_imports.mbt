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
fn find_closure(ctx : HostContext, id : Int) -> (Int, @types.Value)? {
  for entry in ctx.closures.val {
    if entry.0 == id {
      return Some((entry.2, entry.1))
    }
  }
  None
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
    fn(_args) {
      // Use a stable non-null handle to avoid guest-side unwrap/panic.
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
      // Bring-up: call the tick closure once if we can.
      if args.length() > 0 && args[0] is @types.Value::ExternRef(id) {
        if find_closure(ctx, id) is Some((func_idx, env)) {
          if ctx.store is Some(store) && ctx.instance is Some(instance) {
            // Best-effort: most MoonBit closures expect the env as the first arg.
            let _ = @executor.call_func_by_index(store, instance, func_idx, [
                env,
              ])
              |> ignore

          }
        }
      }
      ok_i32(0)
    },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_poll_events",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_width",
    fn(_args) { ok_i32(800) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_height",
    fn(_args) { ok_i32(600) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_get_scale_factor",
    fn(_args) { ok_f32(1.0) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::F32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_should_close",
    fn(_args) { ok_i32(1) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "window_request_close",
    fn(_args) { ok_i32(0) },
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
    "gpu_request_device",
    fn(_args) { ok_extern_ref(HANDLE_BASE + 2) },
    func_type=ft([], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_surface",
    fn(_args) { ok_extern_ref(HANDLE_BASE + 3) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_configure_surface",
    fn(_args) { ok_i32(0) },
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
    fn(_args) { ok_extern_ref(HANDLE_BASE + 4) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::ExternRef]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_begin_pass",
    fn(_args) { ok_i32(0) },
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
    fn(_args) { ok_i32(0) },
    func_type=ft([], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_end_frame",
    fn(_args) { ok_i32(0) },
    func_type=ft([@types.ValueType::ExternRef], [@types.ValueType::I32]),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_render_target",
    fn(_args) { ok_i32(1) },
    func_type=ft(
      [@types.ValueType::I32, @types.ValueType::I32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_capsule",
    fn(_args) { ok_i32(1) },
    func_type=ft(
      [@types.ValueType::F32, @types.ValueType::F32, @types.ValueType::I32],
      [@types.ValueType::I32],
    ),
  )
  linker.add_host_func(
    "mgstudio_host",
    "gpu_create_mesh_rectangle",
    fn(_args) { ok_i32(1) },
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
    fn(_args) { ok_i32(0) },
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
    fn(_args) { ok_i32(0) },
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
