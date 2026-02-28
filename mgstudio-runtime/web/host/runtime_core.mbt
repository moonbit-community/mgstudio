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
fn sampler_kind_from_nearest(nearest : Bool) -> Int {
  if nearest {
    1
  } else {
    0
  }
}

///|
fn sampler_kind_is_nearest(sampler_kind : Int) -> Bool {
  sampler_kind == 1 || sampler_kind == 3
}

///|
fn sampler_kind_is_repeat(sampler_kind : Int) -> Bool {
  sampler_kind == 2 || sampler_kind == 3
}

///|
const PASS_KIND_BASE_MASK : Int = 255

///|
const PASS_KIND_DISABLE_POSTPROCESS_FLAG : Int = 1 << 8

///|
const PASS_KIND_DISABLE_FOG_FLAG : Int = 1 << 9

///|
const PASS_KIND_DISABLE_DECAL_FLAG : Int = 1 << 10

///|
const MESH3D_CULL_MODE_MASK : Int = 3

///|
const MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
const MESH3D_DRAW_FLAG_FOG : Int = 1 << 9

///|
const MESH3D_DRAW_FLAG_POSTPROCESS_PROXY : Int = 1 << 10

///|
fn pass_kind_base_kind(pass_kind : Int) -> Int {
  pass_kind & PASS_KIND_BASE_MASK
}

///|
fn pass_kind_postprocess_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_POSTPROCESS_FLAG) == 0
}

///|
fn pass_kind_fog_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_FOG_FLAG) == 0
}

///|
fn pass_kind_decal_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_DECAL_FLAG) == 0
}

///|
fn mesh3d_draw_is_decal(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_DECAL) != 0
}

///|
fn mesh3d_draw_is_fog(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_FOG) != 0
}

///|
fn mesh3d_draw_is_postprocess_proxy(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_POSTPROCESS_PROXY) != 0
}

///|
fn create_sampler(state : State, sampler_kind : Int) -> @webgpu.GPUSampler? {
  if state.gpu.device is None {
    return None
  }
  if state.gpu.device is Some(device) {
    let filter = if sampler_kind_is_nearest(sampler_kind) {
      @webgpu.FilterMode::Nearest
    } else {
      @webgpu.FilterMode::Linear
    }
    let address_mode = if sampler_kind_is_repeat(sampler_kind) {
      "repeat"
    } else {
      "clamp-to-edge"
    }
    let descriptor = @js.from_entries([
      ("magFilter", @js.any(filter.to_js_string())),
      ("minFilter", @js.any(filter.to_js_string())),
      ("mipmapFilter", @js.any(filter.to_js_string())),
      ("addressModeU", @js.any(address_mode)),
      ("addressModeV", @js.any(address_mode)),
      ("addressModeW", @js.any(address_mode)),
    ])
    Some(device.create_sampler(descriptor))
  } else {
    None
  }
}

///|
fn active_color_pipeline_format(state : State) -> @webgpu.TextureFormat {
  let default_format = state.gpu.format.unwrap_or(
    @webgpu.TextureFormat::Bgra8Unorm,
  )
  let format = if state.gpu.current_pass_info is Some(info) &&
    info.target_id >= 0 {
    let target_entry = map_get(state.gpu.textures, @js.any(info.target_id))
    if host_is_nullish(target_entry) {
      default_format
    } else {
      let target_format_any = target_entry._get("format")
      if host_is_nullish(target_format_any) {
        default_format
      } else {
        @webgpu.texture_format_from_string(any_to_string(target_format_any))
      }
    }
  } else {
    default_format
  }
  let format_key = format.to_js_string()
  if state.gpu.pipeline_color_format != format_key {
    let previous_format = state.gpu.pipeline_color_format
    state.gpu.pipeline = None
    state.gpu.mesh_pipeline = None
    state.gpu.ui_pipeline = None
    state.gpu.ui_shadow_pipeline = None
    state.gpu.ui_slice_pipeline = None
    state.gpu.gizmo_pipeline = None
    state.gpu.sprite_globals_bind_group = None
    state.gpu.ui_globals_bind_group = None
    state.gpu.ui_shadow_globals_bind_group = None
    state.gpu.ui_slice_globals_bind_group = None
    let texture_entries = map_values(state.gpu.textures)
    for i in 0..<array_len(texture_entries) {
      let entry = array_get(texture_entries, i)
      if !host_is_nullish(entry) {
        entry._set("bindGroup", js_null()) |> ignore
        entry._set("meshBindGroup", js_null()) |> ignore
        entry._set("uiBindGroup", js_null()) |> ignore
        entry._set("uiShadowBindGroup", js_null()) |> ignore
        entry._set("uiSliceBindGroup", js_null()) |> ignore
      }
    }
    state.gpu.pipeline_color_format = format_key
    let pass_target_text = match state.gpu.current_pass_info {
      Some(pass_info) => pass_info.target_id.to_string()
      None => "<none>"
    }
    report_debug_once(
      state,
      "pipeline_color_format_" + format_key,
      "pipeline format switch: " +
      previous_format +
      " -> " +
      format_key +
      " target_id=" +
      pass_target_text,
    )
  }
  format
}

///|
fn ensure_pipeline_resources(state : State) -> Unit {
  active_color_pipeline_format(state) |> ignore
  if state.gpu.pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.sprite_shader_id <= 0 {
      return
    }
    let shader_source = get_shader_source(state, state.gpu.sprite_shader_id)
    if shader_source is None {
      return
    }
    let format = active_color_pipeline_format(state)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    // Sprite vertices are generated from @builtin(vertex_index) in WGSL.
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    let uniform_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_uniform(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let uniform_desc = @webgpu.buffer_descriptor(512, uniform_usage)
    let uniform_buffer = device.create_buffer(uniform_desc.to_js())
    let sprite_uniform_desc = @webgpu.buffer_descriptor(32, uniform_usage)
    let sprite_uniform_buffer = device.create_buffer(
      sprite_uniform_desc.to_js(),
    )
    let instance_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_storage(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let instance_capacity = 65536
    let instance_desc = @webgpu.buffer_descriptor(
      instance_capacity, instance_usage,
    )
    let sprite_instance_buffer = device.create_buffer(instance_desc.to_js())
    let default_size = 1
    let texture_usage = @webgpu.combine_flags(
      @webgpu.combine_flags(
        @webgpu.texture_usage_texture_binding(),
        @webgpu.texture_usage_copy_dst(),
      ),
      @webgpu.texture_usage_render_attachment(),
    )
    let texture_desc = @webgpu.texture_descriptor(
      @webgpu.texture_size(default_size, default_size),
      @webgpu.TextureFormat::Rgba8Unorm,
      texture_usage,
    )
    let texture = device.create_texture(texture_desc.to_js())
    let pixel_data = create_solid_rgba_data(
      default_size, default_size, 255, 255, 255, 255,
    )
    write_texture(
      device.queue().as_any(),
      texture.as_any(),
      pixel_data,
      default_size * 4,
      default_size,
      default_size,
    )
    let sampler = create_sampler(state, sampler_kind_from_nearest(true))
    if sampler is Some(sampler_value) {
      let entry = @js.from_entries([
        ("id", @js.any(state.gpu.default_texture_id)),
        ("texture", texture.as_any()),
        ("view", texture.create_view().as_any()),
        ("sampler", sampler_value.as_any()),
        ("bindGroup", js_null()),
        ("meshBindGroup", js_null()),
        ("mesh3dBindGroup", js_null()),
        ("uiBindGroup", js_null()),
        ("width", @js.any(default_size)),
        ("height", @js.any(default_size)),
        ("format", @js.any(@webgpu.TextureFormat::Rgba8Unorm.to_js_string())),
      ])
      map_set(state.gpu.textures, @js.any(state.gpu.default_texture_id), entry)
    }
    state.gpu.pipeline = Some(pipeline)
    state.gpu.vertex_count = 6
    state.gpu.uniform_buffer = Some(uniform_buffer)
    state.gpu.sprite_uniform_buffer = Some(sprite_uniform_buffer)
    state.gpu.sprite_instance_buffer = Some(sprite_instance_buffer)
    state.gpu.sprite_instance_capacity = instance_capacity
    state.gpu.sprite_globals_bind_group = None
    state.gpu.sprite_instance_data.clear()
    state.gpu.sprite_batches.clear()
    state.gpu.sprite_instance_count = 0
    state.gpu.sprite_instance_buffer_write_offset = 0
  }
}

///|
fn ensure_bind_group_for_texture(state : State, entry : @js.Any) -> Unit {
  if state.gpu.pipeline is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if !host_is_nullish(entry._get("bindGroup")) {
    return
  }
  if host_is_nullish(entry._get("sampler")) ||
    host_is_nullish(entry._get("view")) {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(0)
    let sampler : @webgpu.GPUSampler = entry._get("sampler").cast()
    let view : @webgpu.GPUTextureView = entry._get("view").cast()
    let entries = [
      @webgpu.bind_group_entry_sampler(0, sampler),
      @webgpu.bind_group_entry_texture(1, view),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    entry._set("bindGroup", bind_group.as_any()) |> ignore
  }
}

///|
fn ensure_mesh_bind_group_for_texture(state : State, entry : @js.Any) -> Unit {
  if state.gpu.mesh_pipeline is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if !host_is_nullish(entry._get("meshBindGroup")) {
    return
  }
  if host_is_nullish(entry._get("sampler")) ||
    host_is_nullish(entry._get("view")) {
    return
  }
  if state.gpu.device is Some(device) &&
    state.gpu.mesh_pipeline is Some(mesh_pipeline) {
    let layout = mesh_pipeline.get_bind_group_layout(1)
    let sampler : @webgpu.GPUSampler = entry._get("sampler").cast()
    let view : @webgpu.GPUTextureView = entry._get("view").cast()
    let entries = [
      @webgpu.bind_group_entry_sampler(0, sampler),
      @webgpu.bind_group_entry_texture(1, view),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    entry._set("meshBindGroup", bind_group.as_any()) |> ignore
  }
}

///|
fn ensure_mesh3d_bind_group_for_texture(state : State, entry : @js.Any) -> Unit {
  state |> ignore
  entry |> ignore
}

///|
fn ensure_sprite_globals_bind_group(state : State) -> Unit {
  if state.gpu.pipeline is None ||
    state.gpu.sprite_uniform_buffer is None ||
    state.gpu.sprite_instance_buffer is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.sprite_globals_bind_group is Some(_) {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(1)
    let uniform_buffer = state.gpu.sprite_uniform_buffer.unwrap()
    let instance_buffer = state.gpu.sprite_instance_buffer.unwrap()
    let entries = [
      @webgpu.bind_group_entry_buffer(0, uniform_buffer),
      @webgpu.bind_group_entry_buffer(1, instance_buffer),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    state.gpu.sprite_globals_bind_group = Some(bind_group)
  }
}

///|
fn ensure_ui_pipeline_resources(state : State) -> Unit {
  active_color_pipeline_format(state) |> ignore
  if state.gpu.ui_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.ui_shader_id <= 0 {
      report_asset_error_once(
        state, "ui_pipeline_missing_shader_id", "UI pipeline error: ui shader id not initialized",
      )
      return
    }
    let shader_source = get_shader_source(state, state.gpu.ui_shader_id)
    if shader_source is None {
      let path_hint_any = map_get(
        state.assets.shader_paths,
        @js.any(state.gpu.ui_shader_id),
      )
      let suffix = if host_is_nullish(path_hint_any) {
        ""
      } else {
        " (path: " + any_to_string(path_hint_any) + ")"
      }
      report_asset_error_once(
        state,
        "ui_pipeline_missing_shader_source",
        "UI pipeline error: shader source not loaded" + suffix,
      )
      return
    }
    let format = active_color_pipeline_format(state)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    // UI vertices are generated from @builtin(vertex_index) in WGSL.
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    device.push_error_scope("validation")
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    let pipeline_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "ui_pipeline_validation_error",
          "UI pipeline validation error: " + any_to_string(err_any),
        )
      }
    })
    let instance_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_storage(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let instance_capacity = 65536
    let instance_desc = @webgpu.buffer_descriptor(
      instance_capacity, instance_usage,
    )
    let ui_instance_buffer = device.create_buffer(instance_desc.to_js())
    state.gpu.ui_pipeline = Some(pipeline)
    state.gpu.ui_instance_buffer = Some(ui_instance_buffer)
    state.gpu.ui_instance_capacity = instance_capacity
    state.gpu.ui_globals_bind_group = None
    state.gpu.ui_instance_data.clear()
    state.gpu.ui_batches.clear()
    state.gpu.ui_instance_count = 0
  }
}

///|
fn ensure_ui_bind_group_for_texture(state : State, entry : @js.Any) -> Unit {
  if state.gpu.ui_pipeline is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if !host_is_nullish(entry._get("uiBindGroup")) {
    return
  }
  if host_is_nullish(entry._get("sampler")) ||
    host_is_nullish(entry._get("view")) {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.ui_pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(0)
    let sampler : @webgpu.GPUSampler = entry._get("sampler").cast()
    let view : @webgpu.GPUTextureView = entry._get("view").cast()
    let entries = [
      @webgpu.bind_group_entry_sampler(0, sampler),
      @webgpu.bind_group_entry_texture(1, view),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    entry._set("uiBindGroup", bind_group.as_any()) |> ignore
  }
}

///|
fn ensure_ui_globals_bind_group(state : State) -> Unit {
  if state.gpu.ui_pipeline is None ||
    state.gpu.sprite_uniform_buffer is None ||
    state.gpu.ui_instance_buffer is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.ui_globals_bind_group is Some(_) {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.ui_pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(1)
    let uniform_buffer = state.gpu.sprite_uniform_buffer.unwrap()
    let instance_buffer = state.gpu.ui_instance_buffer.unwrap()
    let entries = [
      @webgpu.bind_group_entry_buffer(0, uniform_buffer),
      @webgpu.bind_group_entry_buffer(1, instance_buffer),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    device.push_error_scope("validation")
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    let bind_group_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = bind_group_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "ui_globals_bind_group_validation_error",
          "UI globals bind group validation error: " + any_to_string(err_any),
        )
      }
    })
    state.gpu.ui_globals_bind_group = Some(bind_group)
  }
}

///|
fn ensure_ui_shadow_pipeline_resources(state : State) -> Unit {
  active_color_pipeline_format(state) |> ignore
  if state.gpu.ui_shadow_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.ui_shadow_shader_id <= 0 {
      report_asset_error_once(
        state, "ui_shadow_pipeline_missing_shader_id", "UI box shadow pipeline error: shader id not initialized",
      )
      return
    }
    let shader_source = get_shader_source(state, state.gpu.ui_shadow_shader_id)
    if shader_source is None {
      let path_hint_any = map_get(
        state.assets.shader_paths,
        @js.any(state.gpu.ui_shadow_shader_id),
      )
      let suffix = if host_is_nullish(path_hint_any) {
        ""
      } else {
        " (path: " + any_to_string(path_hint_any) + ")"
      }
      report_asset_error_once(
        state,
        "ui_shadow_pipeline_missing_shader_source",
        "UI box shadow pipeline error: shader source not loaded" + suffix,
      )
      return
    }
    let format = active_color_pipeline_format(state)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    device.push_error_scope("validation")
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    let pipeline_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "ui_shadow_pipeline_validation_error",
          "UI box shadow pipeline validation error: " + any_to_string(err_any),
        )
      }
    })
    let instance_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_storage(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let instance_capacity = 65536
    let instance_desc = @webgpu.buffer_descriptor(
      instance_capacity, instance_usage,
    )
    let instance_buffer = device.create_buffer(instance_desc.to_js())
    state.gpu.ui_shadow_pipeline = Some(pipeline)
    state.gpu.ui_shadow_instance_buffer = Some(instance_buffer)
    state.gpu.ui_shadow_instance_capacity = instance_capacity
    state.gpu.ui_shadow_globals_bind_group = None
    state.gpu.ui_shadow_instance_data.clear()
    state.gpu.ui_shadow_batches.clear()
    state.gpu.ui_shadow_instance_count = 0
  }
}

///|
fn ensure_ui_shadow_bind_group_for_texture(
  state : State,
  entry : @js.Any,
) -> Unit {
  if state.gpu.ui_shadow_pipeline is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if !host_is_nullish(entry._get("uiShadowBindGroup")) {
    return
  }
  if host_is_nullish(entry._get("sampler")) ||
    host_is_nullish(entry._get("view")) {
    return
  }
  if state.gpu.device is Some(device) &&
    state.gpu.ui_shadow_pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(0)
    let sampler : @webgpu.GPUSampler = entry._get("sampler").cast()
    let view : @webgpu.GPUTextureView = entry._get("view").cast()
    let entries = [
      @webgpu.bind_group_entry_sampler(0, sampler),
      @webgpu.bind_group_entry_texture(1, view),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    entry._set("uiShadowBindGroup", bind_group.as_any()) |> ignore
  }
}

///|
fn ensure_ui_shadow_globals_bind_group(state : State) -> Unit {
  if state.gpu.ui_shadow_pipeline is None ||
    state.gpu.sprite_uniform_buffer is None ||
    state.gpu.ui_shadow_instance_buffer is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.ui_shadow_globals_bind_group is Some(_) {
    return
  }
  if state.gpu.device is Some(device) &&
    state.gpu.ui_shadow_pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(1)
    let uniform_buffer = state.gpu.sprite_uniform_buffer.unwrap()
    let instance_buffer = state.gpu.ui_shadow_instance_buffer.unwrap()
    let entries = [
      @webgpu.bind_group_entry_buffer(0, uniform_buffer),
      @webgpu.bind_group_entry_buffer(1, instance_buffer),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    device.push_error_scope("validation")
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    let bind_group_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = bind_group_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "ui_shadow_globals_bind_group_validation_error",
          "UI box shadow globals bind group validation error: " +
          any_to_string(err_any),
        )
      }
    })
    state.gpu.ui_shadow_globals_bind_group = Some(bind_group)
  }
}

///|
fn ensure_ui_slice_pipeline_resources(state : State) -> Unit {
  active_color_pipeline_format(state) |> ignore
  if state.gpu.ui_slice_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.ui_slice_shader_id <= 0 {
      report_asset_error_once(
        state, "ui_slice_pipeline_missing_shader_id", "UI texture slice pipeline error: shader id not initialized",
      )
      return
    }
    let shader_source = get_shader_source(state, state.gpu.ui_slice_shader_id)
    if shader_source is None {
      let path_hint_any = map_get(
        state.assets.shader_paths,
        @js.any(state.gpu.ui_slice_shader_id),
      )
      let suffix = if host_is_nullish(path_hint_any) {
        ""
      } else {
        " (path: " + any_to_string(path_hint_any) + ")"
      }
      report_asset_error_once(
        state,
        "ui_slice_pipeline_missing_shader_source",
        "UI texture slice pipeline error: shader source not loaded" + suffix,
      )
      return
    }
    let format = active_color_pipeline_format(state)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    // UI slice vertices are generated from @builtin(vertex_index) in WGSL.
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    device.push_error_scope("validation")
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    let pipeline_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "ui_slice_pipeline_validation_error",
          "UI texture slice pipeline validation error: " +
          any_to_string(err_any),
        )
      }
    })
    let instance_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_storage(),
      @webgpu.buffer_usage_copy_dst(),
    )
    let instance_capacity = 65536
    let instance_desc = @webgpu.buffer_descriptor(
      instance_capacity, instance_usage,
    )
    let instance_buffer = device.create_buffer(instance_desc.to_js())
    state.gpu.ui_slice_pipeline = Some(pipeline)
    state.gpu.ui_slice_instance_buffer = Some(instance_buffer)
    state.gpu.ui_slice_instance_capacity = instance_capacity
    state.gpu.ui_slice_globals_bind_group = None
    state.gpu.ui_slice_instance_data.clear()
    state.gpu.ui_slice_batches.clear()
    state.gpu.ui_slice_instance_count = 0
  }
}

///|
fn ensure_ui_slice_bind_group_for_texture(
  state : State,
  entry : @js.Any,
) -> Unit {
  if state.gpu.ui_slice_pipeline is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if !host_is_nullish(entry._get("uiSliceBindGroup")) {
    return
  }
  if host_is_nullish(entry._get("sampler")) ||
    host_is_nullish(entry._get("view")) {
    return
  }
  if state.gpu.device is Some(device) &&
    state.gpu.ui_slice_pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(0)
    let sampler : @webgpu.GPUSampler = entry._get("sampler").cast()
    let view : @webgpu.GPUTextureView = entry._get("view").cast()
    let entries = [
      @webgpu.bind_group_entry_sampler(0, sampler),
      @webgpu.bind_group_entry_texture(1, view),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    entry._set("uiSliceBindGroup", bind_group.as_any()) |> ignore
  }
}

///|
fn ensure_ui_slice_globals_bind_group(state : State) -> Unit {
  if state.gpu.ui_slice_pipeline is None ||
    state.gpu.sprite_uniform_buffer is None ||
    state.gpu.ui_slice_instance_buffer is None {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.ui_slice_globals_bind_group is Some(_) {
    return
  }
  if state.gpu.device is Some(device) &&
    state.gpu.ui_slice_pipeline is Some(pipeline) {
    let layout = pipeline.get_bind_group_layout(1)
    let uniform_buffer = state.gpu.sprite_uniform_buffer.unwrap()
    let instance_buffer = state.gpu.ui_slice_instance_buffer.unwrap()
    let entries = [
      @webgpu.bind_group_entry_buffer(0, uniform_buffer),
      @webgpu.bind_group_entry_buffer(1, instance_buffer),
    ]
    let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
    device.push_error_scope("validation")
    let bind_group = device.create_bind_group(bind_group_desc.to_js())
    let bind_group_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = bind_group_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "ui_slice_globals_bind_group_validation_error",
          "UI texture slice globals bind group validation error: " +
          any_to_string(err_any),
        )
      }
    })
    state.gpu.ui_slice_globals_bind_group = Some(bind_group)
  }
}

///|
fn ensure_mesh_pipeline(state : State) -> Unit {
  active_color_pipeline_format(state) |> ignore
  if state.gpu.mesh_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.mesh_shader_id <= 0 {
      report_asset_error_once(
        state, "mesh_pipeline_missing_shader_id", "Mesh pipeline error: mesh shader id not initialized",
      )
      return
    }
    let shader_source = get_shader_source(state, state.gpu.mesh_shader_id)
    if shader_source is None {
      let path_hint_any = map_get(
        state.assets.shader_paths,
        @js.any(state.gpu.mesh_shader_id),
      )
      let suffix = if host_is_nullish(path_hint_any) {
        ""
      } else {
        " (path: " + any_to_string(path_hint_any) + ")"
      }
      report_asset_error_once(
        state,
        "mesh_pipeline_missing_shader_source",
        "Mesh pipeline error: shader source not loaded" + suffix,
      )
      return
    }
    let format = active_color_pipeline_format(state)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let position_attr = @webgpu.vertex_attribute(
      shader_location=0,
      offset=0,
      format=@webgpu.VertexFormat::Float32x2,
    )
    let uv_attr = @webgpu.vertex_attribute(
      shader_location=1,
      offset=8,
      format=@webgpu.VertexFormat::Float32x2,
    )
    let color_attr = @webgpu.vertex_attribute(
      shader_location=2,
      offset=16,
      format=@webgpu.VertexFormat::Float32x4,
    )
    let vertex_layout = @webgpu.vertex_buffer_layout(32, [
      position_attr, uv_attr, color_attr,
    ])
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [
      vertex_layout,
    ])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    device.push_error_scope("validation")
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    let pipeline_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "mesh_pipeline_validation_error",
          "Mesh pipeline validation error: " + any_to_string(err_any),
        )
      }
    })
    state.gpu.mesh_pipeline = Some(pipeline)
  }
}

///|
fn ensure_depth_texture(state : State, width : Int, height : Int) -> Unit {
  if state.gpu.device is None {
    return
  }
  let safe_width = if width > 0 { width } else { 1 }
  let safe_height = if height > 0 { height } else { 1 }
  if state.gpu.depth_texture is Some(_) &&
    state.gpu.depth_view is Some(_) &&
    state.gpu.depth_width == safe_width &&
    state.gpu.depth_height == safe_height {
    return
  }
  if state.gpu.device is Some(device) {
    let usage = @webgpu.combine_flags(
      @webgpu.texture_usage_render_attachment(),
      @webgpu.texture_usage_texture_binding(),
    )
    let descriptor = @webgpu.texture_descriptor(
      @webgpu.texture_size(safe_width, safe_height),
      @webgpu.TextureFormat::Other("depth24plus"),
      usage,
    )
    let texture = device.create_texture(descriptor.to_js())
    let view = texture.create_view()
    state.gpu.depth_texture = Some(texture)
    state.gpu.depth_view = Some(view)
    state.gpu.depth_width = safe_width
    state.gpu.depth_height = safe_height
  }
}

///|
fn mesh3d_topology_kind_from_entry(mesh_entry : @js.Any) -> Int {
  let topology_any = mesh_entry._get("primitiveTopologyKind")
  if host_is_nullish(topology_any) {
    0
  } else {
    to_int(number_or(topology_any, 0))
  }
}

///|
fn mesh3d_webgpu_topology(kind : Int) -> @webgpu.PrimitiveTopology {
  match kind {
    1 => @webgpu.PrimitiveTopology::LineList
    2 => @webgpu.PrimitiveTopology::LineStrip
    _ => @webgpu.PrimitiveTopology::TriangleList
  }
}

///|
fn mesh3d_pipeline_get(
  state : State,
  topology_kind : Int,
  transparent : Bool,
  cull_mode : Int,
) -> @webgpu.GPURenderPipeline? {
  let format_key = state.gpu.format
    .unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
    .to_js_string()
  let transparent_key = if transparent { "1" } else { "0" }
  let cull_key = mesh3d_cull_mode_sanitize(cull_mode).to_string()
  let key = format_key +
    "|" +
    topology_kind.to_string() +
    "|" +
    transparent_key +
    "|" +
    cull_key
  let pipeline_any = map_get(state.gpu.mesh3d_pipeline_cache, @js.any(key))
  if host_is_nullish(pipeline_any) {
    None
  } else {
    Some(pipeline_any.cast())
  }
}

///|
fn mesh3d_pipeline_set(
  state : State,
  topology_kind : Int,
  transparent : Bool,
  cull_mode : Int,
  pipeline : @webgpu.GPURenderPipeline?,
) -> Unit {
  let format_key = state.gpu.format
    .unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
    .to_js_string()
  let transparent_key = if transparent { "1" } else { "0" }
  let cull_key = mesh3d_cull_mode_sanitize(cull_mode).to_string()
  let key = format_key +
    "|" +
    topology_kind.to_string() +
    "|" +
    transparent_key +
    "|" +
    cull_key
  match pipeline {
    Some(value) =>
      map_set(state.gpu.mesh3d_pipeline_cache, @js.any(key), value.as_any())
    None => map_set(state.gpu.mesh3d_pipeline_cache, @js.any(key), js_null())
  }
}

///|
fn mesh3d_topology_key_suffix(topology_kind : Int) -> String {
  match topology_kind {
    1 => "_line_list"
    2 => "_line_strip"
    _ => "_triangle_list"
  }
}

///|
fn mesh3d_cull_mode_sanitize(cull_mode : Int) -> Int {
  match cull_mode & MESH3D_CULL_MODE_MASK {
    1 => 1
    2 => 2
    _ => 0
  }
}

///|
fn mesh3d_webgpu_cull_mode(cull_mode : Int) -> String {
  match mesh3d_cull_mode_sanitize(cull_mode) {
    1 => "front"
    2 => "back"
    _ => "none"
  }
}

///|
fn mesh3d_cull_mode_key_suffix(cull_mode : Int) -> String {
  match mesh3d_cull_mode_sanitize(cull_mode) {
    1 => "_cull_front"
    2 => "_cull_back"
    _ => "_cull_none"
  }
}

///|
fn ensure_mesh3d_pipeline(
  state : State,
  topology_kind : Int,
  cull_mode : Int,
) -> Unit {
  if mesh3d_pipeline_get(state, topology_kind, false, cull_mode) is Some(_) &&
    mesh3d_pipeline_get(state, topology_kind, true, cull_mode) is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.mesh3d_shader_id <= 0 {
      report_asset_error_once(
        state, "mesh3d_pipeline_missing_shader_id", "Mesh3d pipeline error: shader id not initialized",
      )
      return
    }
    let shader_source = get_shader_source(state, state.gpu.mesh3d_shader_id)
    if shader_source is None {
      let path_hint_any = map_get(
        state.assets.shader_paths,
        @js.any(state.gpu.mesh3d_shader_id),
      )
      let suffix = if host_is_nullish(path_hint_any) {
        ""
      } else {
        " (path: " + any_to_string(path_hint_any) + ")"
      }
      report_asset_error_once(
        state,
        "mesh3d_pipeline_missing_shader_source",
        "Mesh3d pipeline error: shader source not loaded" + suffix,
      )
      return
    }
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    @js.run_async(async fn() noraise {
      let info_any : @js.Any = shader_module_get_compilation_info(
        shader_module.as_any(),
      ).wait() catch {
        _ => js_null()
      }
      let info_text = shader_compilation_info_to_text(info_any)
      if info_text != "" {
        report_debug_once(
          state,
          "mesh3d_shader_compilation_info",
          "Mesh3d shader compilation info:\n" + info_text,
        )
      }
    })
    if state.gpu.mesh3d_uniform_layout is None {
      let fragment_stage = @webgpu.shader_stage_fragment()
      let vertex_fragment_stage = @webgpu.combine_flags(
        @webgpu.shader_stage_vertex(),
        fragment_stage,
      )
      let uniform_layout_desc = @js.from_entries([
        (
          "entries",
          @js.any([
            @js.from_entries([
              ("binding", @js.any(0)),
              ("visibility", @js.any(vertex_fragment_stage)),
              ("buffer", @js.from_entries([("type", @js.any("uniform"))])),
            ]),
          ]),
        ),
      ])
      let uniform_layout = device.create_bind_group_layout(uniform_layout_desc)
      state.gpu.mesh3d_uniform_layout = Some(uniform_layout)
      let material_layout_desc = @js.from_entries([
        (
          "entries",
          @js.any([
            @js.from_entries([
              ("binding", @js.any(0)),
              ("visibility", @js.any(fragment_stage)),
              ("sampler", @js.from_entries([("type", @js.any("filtering"))])),
            ]),
            @js.from_entries([
              ("binding", @js.any(1)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(2)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(3)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(4)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(5)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(6)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(7)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(8)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(9)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                ]),
              ),
            ]),
          ]),
        ),
      ])
      let material_layout = device.create_bind_group_layout(
        material_layout_desc,
      )
      state.gpu.mesh3d_material_layout = Some(material_layout)
    }
    let position_attr = @webgpu.vertex_attribute(
      shader_location=0,
      offset=0,
      format=@webgpu.VertexFormat::Float32x3,
    )
    let uv_attr = @webgpu.vertex_attribute(
      shader_location=1,
      offset=12,
      format=@webgpu.VertexFormat::Float32x2,
    )
    let color_attr = @webgpu.vertex_attribute(
      shader_location=2,
      offset=20,
      format=@webgpu.VertexFormat::Float32x4,
    )
    let vertex_layout = @webgpu.vertex_buffer_layout(36, [
      position_attr, uv_attr, color_attr,
    ])
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [
      vertex_layout,
    ])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state_js = @webgpu.primitive_state(
      mesh3d_webgpu_topology(topology_kind),
    ).to_js()
    primitive_state_js._set(
      "cullMode",
      @js.any(mesh3d_webgpu_cull_mode(cull_mode)),
    )
    guard state.gpu.mesh3d_uniform_layout is Some(uniform_layout) else {
      return
    }
    guard state.gpu.mesh3d_material_layout is Some(material_layout) else {
      return
    }
    let pipeline_layout_desc = @js.from_entries([
      (
        "bindGroupLayouts",
        @js.any([uniform_layout.as_any(), material_layout.as_any()]),
      ),
    ])
    let pipeline_layout = device.create_pipeline_layout(pipeline_layout_desc)
    let depth_state_opaque = @js.from_entries([
      ("format", @js.any("depth24plus")),
      ("depthWriteEnabled", @js.any(true)),
      ("depthCompare", @js.any("less-equal")),
    ])
    let pipeline_desc_opaque = @js.from_entries([
      ("layout", pipeline_layout.as_any()),
      ("vertex", vertex_state.to_js()),
      ("fragment", fragment_state.to_js()),
      ("primitive", primitive_state_js),
      ("depthStencil", depth_state_opaque),
    ])
    device.push_error_scope("validation")
    let pipeline_opaque = device.create_render_pipeline(pipeline_desc_opaque)
    let pipeline_error_promise_opaque = device.pop_error_scope()
    let topology_suffix = mesh3d_topology_key_suffix(topology_kind) +
      mesh3d_cull_mode_key_suffix(cull_mode)
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise_opaque.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "mesh3d_pipeline_validation_error" + topology_suffix,
          "Mesh3d pipeline validation error: " + any_to_string(err_any),
        )
        mesh3d_pipeline_set(state, topology_kind, false, cull_mode, None)
      }
    })
    mesh3d_pipeline_set(
      state,
      topology_kind,
      false,
      cull_mode,
      Some(pipeline_opaque),
    )

    let depth_state_transparent = @js.from_entries([
      ("format", @js.any("depth24plus")),
      ("depthWriteEnabled", @js.any(false)),
      ("depthCompare", @js.any("less-equal")),
    ])
    let pipeline_desc_transparent = @js.from_entries([
      ("layout", pipeline_layout.as_any()),
      ("vertex", vertex_state.to_js()),
      ("fragment", fragment_state.to_js()),
      ("primitive", primitive_state_js),
      ("depthStencil", depth_state_transparent),
    ])
    device.push_error_scope("validation")
    let pipeline_transparent = device.create_render_pipeline(
      pipeline_desc_transparent,
    )
    let pipeline_error_promise_transparent = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise_transparent.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "mesh3d_pipeline_transparent_validation_error" + topology_suffix,
          "Mesh3d transparent pipeline validation error: " +
          any_to_string(err_any),
        )
        mesh3d_pipeline_set(state, topology_kind, true, cull_mode, None)
      }
    })
    mesh3d_pipeline_set(
      state,
      topology_kind,
      true,
      cull_mode,
      Some(pipeline_transparent),
    )
  }
}

///|
fn ensure_motion_vector_pipeline(state : State) -> Unit {
  if state.gpu.motion_vector_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.motion_vector_shader_id <= 0 {
    report_asset_error_once(
      state, "motion_vector_pipeline_missing_shader_id", "Motion-vector pipeline error: shader id not initialized",
    )
    return
  }
  let shader_source = get_shader_source(
    state,
    state.gpu.motion_vector_shader_id,
  )
  if shader_source is None {
    report_asset_error_once(
      state, "motion_vector_pipeline_missing_shader_source", "Motion-vector pipeline error: shader source not loaded",
    )
    return
  }
  if state.gpu.device is Some(device) {
    let format = @webgpu.TextureFormat::Other("rgba16float")
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let vertex_stage = @webgpu.shader_stage_vertex()
    let uniform_layout_desc = @js.from_entries([
      (
        "entries",
        @js.any([
          @js.from_entries([
            ("binding", @js.any(0)),
            ("visibility", @js.any(vertex_stage)),
            ("buffer", @js.from_entries([("type", @js.any("uniform"))])),
          ]),
        ]),
      ),
    ])
    let uniform_layout = device.create_bind_group_layout(uniform_layout_desc)
    let pipeline_layout_desc = @js.from_entries([
      ("bindGroupLayouts", @js.any([uniform_layout.as_any()])),
    ])
    let pipeline_layout = device.create_pipeline_layout(pipeline_layout_desc)
    let position_attr = @webgpu.vertex_attribute(
      shader_location=0,
      offset=0,
      format=@webgpu.VertexFormat::Float32x3,
    )
    let uv_attr = @webgpu.vertex_attribute(
      shader_location=1,
      offset=12,
      format=@webgpu.VertexFormat::Float32x2,
    )
    let color_attr = @webgpu.vertex_attribute(
      shader_location=2,
      offset=20,
      format=@webgpu.VertexFormat::Float32x4,
    )
    let vertex_layout = @webgpu.vertex_buffer_layout(36, [
      position_attr, uv_attr, color_attr,
    ])
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [
      vertex_layout,
    ])
    let color_target = @js.from_entries([
      ("format", @js.any(format.to_js_string())),
    ])
    let fragment_state = @js.from_entries([
      ("module", shader_module.as_any()),
      ("entryPoint", @js.any("fs_main")),
      ("targets", @js.any([color_target])),
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let depth_state = @js.from_entries([
      ("format", @js.any("depth24plus")),
      ("depthWriteEnabled", @js.any(true)),
      ("depthCompare", @js.any("less-equal")),
    ])
    let pipeline_desc = @js.from_entries([
      ("layout", pipeline_layout.as_any()),
      ("vertex", vertex_state.to_js()),
      ("fragment", fragment_state),
      ("primitive", primitive_state.to_js()),
      ("depthStencil", depth_state),
    ])
    device.push_error_scope("validation")
    let pipeline = device.create_render_pipeline(pipeline_desc)
    let pipeline_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "motion_vector_pipeline_validation_error",
          "Motion-vector pipeline validation error: " + any_to_string(err_any),
        )
        state.gpu.motion_vector_pipeline = None
      }
    })
    state.gpu.motion_vector_pipeline = Some(pipeline)
  }
}

///|
fn ensure_motion_blur_pipeline(state : State) -> Unit {
  if state.gpu.motion_blur_pipeline is Some(_) &&
    state.gpu.motion_blur_bind_layout is Some(_) &&
    state.gpu.motion_blur_settings_buffer is Some(_) &&
    state.gpu.motion_blur_globals_buffer is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.motion_blur_shader_id <= 0 {
    report_asset_error_once(
      state, "motion_blur_pipeline_missing_shader_id", "Motion-blur pipeline error: shader id not initialized",
    )
    return
  }
  let shader_source = get_shader_source(state, state.gpu.motion_blur_shader_id)
  if shader_source is None {
    report_asset_error_once(
      state, "motion_blur_pipeline_missing_shader_source", "Motion-blur pipeline error: shader source not loaded",
    )
    return
  }
  if state.gpu.device is Some(device) {
    let fragment_stage = @webgpu.shader_stage_fragment()
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
    if state.gpu.motion_blur_bind_layout is None {
      let bind_layout_desc = @js.from_entries([
        (
          "entries",
          @js.any([
            @js.from_entries([
              ("binding", @js.any(0)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                  ("multisampled", @js.any(false)),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(1)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("float")),
                  ("viewDimension", @js.any("2d")),
                  ("multisampled", @js.any(false)),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(2)),
              ("visibility", @js.any(fragment_stage)),
              (
                "texture",
                @js.from_entries([
                  ("sampleType", @js.any("depth")),
                  ("viewDimension", @js.any("2d")),
                  ("multisampled", @js.any(false)),
                ]),
              ),
            ]),
            @js.from_entries([
              ("binding", @js.any(3)),
              ("visibility", @js.any(fragment_stage)),
              ("sampler", @js.from_entries([("type", @js.any("filtering"))])),
            ]),
            @js.from_entries([
              ("binding", @js.any(4)),
              ("visibility", @js.any(fragment_stage)),
              ("buffer", @js.from_entries([("type", @js.any("uniform"))])),
            ]),
            @js.from_entries([
              ("binding", @js.any(5)),
              ("visibility", @js.any(fragment_stage)),
              ("buffer", @js.from_entries([("type", @js.any("uniform"))])),
            ]),
          ]),
        ),
      ])
      state.gpu.motion_blur_bind_layout = Some(
        device.create_bind_group_layout(bind_layout_desc),
      )
    }
    let uniform_usage = @webgpu.combine_flags(
      @webgpu.buffer_usage_uniform(),
      @webgpu.buffer_usage_copy_dst(),
    )
    if state.gpu.motion_blur_settings_buffer is None {
      let settings_desc = @webgpu.buffer_descriptor(16, uniform_usage)
      state.gpu.motion_blur_settings_buffer = Some(
        device.create_buffer(settings_desc.to_js()),
      )
    }
    if state.gpu.motion_blur_globals_buffer is None {
      let globals_desc = @webgpu.buffer_descriptor(16, uniform_usage)
      state.gpu.motion_blur_globals_buffer = Some(
        device.create_buffer(globals_desc.to_js()),
      )
    }
    guard state.gpu.motion_blur_bind_layout is Some(bind_layout) else { return }
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let pipeline_layout_desc = @js.from_entries([
      ("bindGroupLayouts", @js.any([bind_layout.as_any()])),
    ])
    let pipeline_layout = device.create_pipeline_layout(pipeline_layout_desc)
    let vertex_state = @webgpu.vertex_state(
      shader_module,
      "fullscreen_vertex_shader",
      [],
    )
    let color_target = @js.from_entries([
      ("format", @js.any(format.to_js_string())),
    ])
    let fragment_state = @js.from_entries([
      ("module", shader_module.as_any()),
      ("entryPoint", @js.any("fragment")),
      ("targets", @js.any([color_target])),
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @js.from_entries([
      ("layout", pipeline_layout.as_any()),
      ("vertex", vertex_state.to_js()),
      ("fragment", fragment_state),
      ("primitive", primitive_state.to_js()),
    ])
    device.push_error_scope("validation")
    let pipeline = device.create_render_pipeline(pipeline_desc)
    let pipeline_error_promise = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "motion_blur_pipeline_validation_error",
          "Motion-blur pipeline validation error: " + any_to_string(err_any),
        )
        state.gpu.motion_blur_pipeline = None
      }
    })
    state.gpu.motion_blur_pipeline = Some(pipeline)
  }
}

///|
fn clamp_double(
  value : Double,
  min_value : Double,
  max_value : Double,
) -> Double {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn bloom2d_ilog2_floor(value : Int) -> Int {
  let mut v = if value < 1 { 1 } else { value }
  let mut power = 0
  while v > 1 {
    v = v / 2
    power = power + 1
  }
  power
}

///|
fn bloom2d_effective_mip_count(max_mip_dimension : Int) -> Int {
  let safe_dimension = if max_mip_dimension < 4 { 4 } else { max_mip_dimension }
  let ilog2 = bloom2d_ilog2_floor(safe_dimension)
  let count = if ilog2 < 2 { 1 } else { ilog2 - 1 }
  if count < 1 {
    1
  } else {
    count
  }
}

///|
fn bloom2d_mip_dimension(base : Int, mip : Int) -> Int {
  let mut value = if base < 1 { 1 } else { base }
  for _ in 0..<mip {
    value = if value > 1 { value / 2 } else { 1 }
  }
  if value < 1 {
    1
  } else {
    value
  }
}

///|
fn bloom2d_compute_blend_factor(
  intensity : Double,
  low_frequency_boost : Double,
  low_frequency_boost_curvature : Double,
  high_pass_frequency : Double,
  composite_mode : Int,
  mip : Double,
  max_mip : Double,
) -> Double {
  let mip_ratio = mip / max_mip
  let mut lf_boost = (
      1.0 -
      math_pow(1.0 - mip_ratio, 1.0 / (1.0 - low_frequency_boost_curvature))
    ) *
    low_frequency_boost
  let high_pass_lq = 1.0 -
    clamp_double(
      (mip_ratio - high_pass_frequency) / high_pass_frequency,
      0.0,
      1.0,
    )
  let mode_factor = if composite_mode == 0 { 1.0 - intensity } else { 1.0 }
  lf_boost = lf_boost * mode_factor
  (intensity + lf_boost) * high_pass_lq
}

///|
fn bloom2d_make_uniform_data(
  source_width : Double,
  source_height : Double,
  source_viewport_x : Double,
  source_viewport_y : Double,
  source_viewport_width : Double,
  source_viewport_height : Double,
  threshold : Double,
  threshold_softness : Double,
  scale_x : Double,
  scale_y : Double,
  bloom_weight : Double,
  tonemapping_mode : Int,
  deband_dither_enabled : Int,
  upsample_blend : Double,
) -> @js.Any {
  let softness = threshold_softness
  let knee = threshold * softness
  let safe_source_width = if source_width > 0.0 { source_width } else { 1.0 }
  let safe_source_height = if source_height > 0.0 { source_height } else { 1.0 }
  let safe_viewport_width = if source_viewport_width > 0.0 {
    source_viewport_width
  } else {
    safe_source_width
  }
  let safe_viewport_height = if source_viewport_height > 0.0 {
    source_viewport_height
  } else {
    safe_source_height
  }
  let aspect = if safe_viewport_height > 0.0 {
    safe_viewport_width / safe_viewport_height
  } else {
    1.0
  }
  make_uniform_data([
    threshold,
    threshold - knee,
    2.0 * knee,
    0.25 / (knee + 0.00001),
    source_viewport_x / safe_source_width,
    source_viewport_y / safe_source_height,
    safe_viewport_width / safe_source_width,
    safe_viewport_height / safe_source_height,
    scale_x,
    scale_y,
    aspect,
    0.0,
    tonemapping_mode.to_double(),
    if deband_dither_enabled != 0 {
      1.0
    } else {
      0.0
    },
    bloom_weight,
    upsample_blend,
  ])
}

///|
fn bloom2d_create_pipeline(
  state : State,
  shader_source : String,
  bind_layout : @webgpu.GPUBindGroupLayout,
  entry_point : String,
  format : @webgpu.TextureFormat,
  blend_mode : Int,
) -> @webgpu.GPURenderPipeline? {
  guard state.gpu.device is Some(device) else { return None }
  let shader_desc = @webgpu.shader_module_descriptor(shader_source)
  let shader_module = device.create_shader_module(shader_desc.to_js())
  let pipeline_layout_desc = @js.from_entries([
    ("bindGroupLayouts", @js.any([bind_layout.as_any()])),
  ])
  let pipeline_layout = device.create_pipeline_layout(pipeline_layout_desc)
  let vertex_state = @webgpu.vertex_state(
    shader_module,
    "fullscreen_vertex_shader",
    [],
  )
  let color_target = if blend_mode == 1 {
    @js.from_entries([
      ("format", @js.any(format.to_js_string())),
      (
        "blend",
        @js.from_entries([
          (
            "color",
            @js.from_entries([
              ("srcFactor", @js.any("constant")),
              ("dstFactor", @js.any("one-minus-constant")),
              ("operation", @js.any("add")),
            ]),
          ),
          (
            "alpha",
            @js.from_entries([
              ("srcFactor", @js.any("zero")),
              ("dstFactor", @js.any("one")),
              ("operation", @js.any("add")),
            ]),
          ),
        ]),
      ),
    ])
  } else if blend_mode == 2 {
    @js.from_entries([
      ("format", @js.any(format.to_js_string())),
      (
        "blend",
        @js.from_entries([
          (
            "color",
            @js.from_entries([
              ("srcFactor", @js.any("constant")),
              ("dstFactor", @js.any("one")),
              ("operation", @js.any("add")),
            ]),
          ),
          (
            "alpha",
            @js.from_entries([
              ("srcFactor", @js.any("zero")),
              ("dstFactor", @js.any("one")),
              ("operation", @js.any("add")),
            ]),
          ),
        ]),
      ),
    ])
  } else {
    @js.from_entries([("format", @js.any(format.to_js_string()))])
  }
  let fragment_state = @js.from_entries([
    ("module", shader_module.as_any()),
    ("entryPoint", @js.any(entry_point)),
    ("targets", @js.any([color_target])),
  ])
  let primitive_state = @webgpu.primitive_state(
    @webgpu.PrimitiveTopology::TriangleList,
  )
  let pipeline_desc = @js.from_entries([
    ("layout", pipeline_layout.as_any()),
    ("vertex", vertex_state.to_js()),
    ("fragment", fragment_state),
    ("primitive", primitive_state.to_js()),
  ])
  let pipeline = device.create_render_pipeline(pipeline_desc)
  Some(pipeline)
}

///|
fn bloom2d_begin_pass_clear(
  encoder : @webgpu.GPUCommandEncoder,
  view : @webgpu.GPUTextureView,
) -> @webgpu.GPURenderPassEncoder {
  let attachment = @webgpu.color_attachment_clear(
    view,
    @webgpu.color(0.0, 0.0, 0.0, 1.0),
  )
  let descriptor = @webgpu.render_pass_descriptor([attachment]).to_js()
  encoder.begin_render_pass(descriptor)
}

///|
fn bloom2d_begin_pass_load(
  encoder : @webgpu.GPUCommandEncoder,
  view : @webgpu.GPUTextureView,
) -> @webgpu.GPURenderPassEncoder {
  let attachment = @webgpu.color_attachment_load(view)
  let descriptor = @webgpu.render_pass_descriptor([attachment]).to_js()
  encoder.begin_render_pass(descriptor)
}

///|
fn bloom2d_create_mip_view(
  texture : @webgpu.GPUTexture,
  mip : Int,
) -> @webgpu.GPUTextureView {
  let descriptor = @js.from_entries([
    ("baseMipLevel", @js.any(mip)),
    ("mipLevelCount", @js.any(1)),
  ])
  texture.create_view(descriptor~)
}

///|
fn bloom2d_ensure_compose_view(
  state : State,
  width : Int,
  height : Int,
) -> @webgpu.GPUTextureView? {
  guard state.gpu.device is Some(device) else { return None }
  let safe_width = if width < 1 { 1 } else { width }
  let safe_height = if height < 1 { 1 } else { height }
  let compose_format = @webgpu.TextureFormat::Other("rgba16float")
  let compose_format_key = compose_format.to_js_string()
  let rebuild = state.gpu.bloom2d_compose_texture is None ||
    state.gpu.bloom2d_compose_view is None ||
    state.gpu.bloom2d_compose_width != safe_width ||
    state.gpu.bloom2d_compose_height != safe_height ||
    state.gpu.bloom2d_compose_format != compose_format_key
  if rebuild {
    let usage = @webgpu.combine_flags(
      @webgpu.combine_flags(
        @webgpu.texture_usage_texture_binding(),
        @webgpu.texture_usage_render_attachment(),
      ),
      @webgpu.texture_usage_copy_dst(),
    )
    let descriptor = @js.from_entries([
      ("size", @webgpu.texture_size(safe_width, safe_height).to_js()),
      ("mipLevelCount", @js.any(1)),
      ("sampleCount", @js.any(1)),
      ("dimension", @js.any("2d")),
      ("format", @js.any(compose_format_key)),
      ("usage", @js.any(usage)),
    ])
    let texture = device.create_texture(descriptor)
    let view = texture.create_view()
    state.gpu.bloom2d_compose_texture = Some(texture)
    state.gpu.bloom2d_compose_view = Some(view)
    state.gpu.bloom2d_compose_width = safe_width
    state.gpu.bloom2d_compose_height = safe_height
    state.gpu.bloom2d_compose_format = compose_format_key
  }
  state.gpu.bloom2d_compose_view
}

///|
fn ensure_bloom2d_pipeline(
  state : State,
  format : @webgpu.TextureFormat,
) -> Unit {
  guard state.gpu.device is Some(device) else { return }
  let fragment_stage = @webgpu.shader_stage_fragment()
  let format_key = format.to_js_string()
  let bloom_mip_format = @webgpu.TextureFormat::Other("rgba16float")
  let bloom_mip_format_key = bloom_mip_format.to_js_string()
  if state.gpu.bloom2d_bind_layout is None {
    let bind_layout_desc = @js.from_entries([
      (
        "entries",
        @js.any([
          @js.from_entries([
            ("binding", @js.any(0)),
            ("visibility", @js.any(fragment_stage)),
            (
              "texture",
              @js.from_entries([
                ("sampleType", @js.any("float")),
                ("viewDimension", @js.any("2d")),
                ("multisampled", @js.any(false)),
              ]),
            ),
          ]),
          @js.from_entries([
            ("binding", @js.any(1)),
            ("visibility", @js.any(fragment_stage)),
            ("sampler", @js.from_entries([("type", @js.any("filtering"))])),
          ]),
          @js.from_entries([
            ("binding", @js.any(2)),
            ("visibility", @js.any(fragment_stage)),
            ("buffer", @js.from_entries([("type", @js.any("uniform"))])),
          ]),
          @js.from_entries([
            ("binding", @js.any(3)),
            ("visibility", @js.any(fragment_stage)),
            (
              "texture",
              @js.from_entries([
                ("sampleType", @js.any("float")),
                ("viewDimension", @js.any("2d")),
                ("multisampled", @js.any(false)),
              ]),
            ),
          ]),
          @js.from_entries([
            ("binding", @js.any(4)),
            ("visibility", @js.any(fragment_stage)),
            (
              "texture",
              @js.from_entries([
                ("sampleType", @js.any("float")),
                ("viewDimension", @js.any("2d")),
                ("multisampled", @js.any(false)),
              ]),
            ),
          ]),
        ]),
      ),
    ])
    state.gpu.bloom2d_bind_layout = Some(
      device.create_bind_group_layout(bind_layout_desc),
    )
  }
  let uniform_usage = @webgpu.combine_flags(
    @webgpu.buffer_usage_uniform(),
    @webgpu.buffer_usage_copy_dst(),
  )
  if state.gpu.bloom2d_settings_buffer is None {
    let settings_desc = @webgpu.buffer_descriptor(64, uniform_usage)
    state.gpu.bloom2d_settings_buffer = Some(
      device.create_buffer(settings_desc.to_js()),
    )
  }
  if state.gpu.bloom2d_sampler is None {
    state.gpu.bloom2d_sampler = create_sampler(
      state,
      sampler_kind_from_nearest(false),
    )
  }
  if state.gpu.bloom2d_downsample_first_pipeline is Some(_) &&
    state.gpu.bloom2d_downsample_first_no_threshold_pipeline is Some(_) &&
    state.gpu.bloom2d_downsample_first_uniform_pipeline is Some(_) &&
    state.gpu.bloom2d_downsample_first_no_threshold_uniform_pipeline is Some(_) &&
    state.gpu.bloom2d_downsample_pipeline is Some(_) &&
    state.gpu.bloom2d_downsample_uniform_pipeline is Some(_) &&
    state.gpu.bloom2d_upsample_pipeline_energy is Some(_) &&
    state.gpu.bloom2d_upsample_pipeline_additive is Some(_) &&
    state.gpu.bloom2d_final_pipeline_energy is Some(_) &&
    state.gpu.bloom2d_final_pipeline_additive is Some(_) &&
    state.gpu.bloom2d_mip_format == bloom_mip_format_key &&
    state.gpu.bloom2d_final_pipeline_format == format_key {
    if state.gpu.bloom2d_pipeline is Some(_) {
      ()
    }
    return
  }
  guard state.gpu.bloom2d_bind_layout is Some(bind_layout) else { return }
  if state.gpu.bloom2d_downsample_first_shader_id <= 0 ||
    state.gpu.bloom2d_downsample_first_no_threshold_shader_id <= 0 ||
    state.gpu.bloom2d_downsample_first_uniform_shader_id <= 0 ||
    state.gpu.bloom2d_downsample_first_no_threshold_uniform_shader_id <= 0 ||
    state.gpu.bloom2d_downsample_shader_id <= 0 ||
    state.gpu.bloom2d_downsample_uniform_shader_id <= 0 ||
    state.gpu.bloom2d_shader_id <= 0 ||
    state.gpu.bloom2d_final_shader_id <= 0 {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_shader_id", "Bloom2d pipeline error: shader id not initialized",
    )
    return
  }
  let downsample_first_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_downsample_first_shader_id,
  )
  if downsample_first_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_downsample_first_shader_source", "Bloom2d pipeline error: downsample-first shader source not loaded",
    )
    return
  }
  let downsample_first_no_threshold_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_downsample_first_no_threshold_shader_id,
  )
  if downsample_first_no_threshold_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_downsample_first_no_threshold_shader_source",
      "Bloom2d pipeline error: downsample-first-no-threshold shader source not loaded",
    )
    return
  }
  let downsample_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_downsample_shader_id,
  )
  if downsample_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_downsample_shader_source", "Bloom2d pipeline error: downsample shader source not loaded",
    )
    return
  }
  let upsample_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_shader_id,
  )
  if upsample_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_upsample_shader_source", "Bloom2d pipeline error: upsample shader source not loaded",
    )
    return
  }
  let final_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_final_shader_id,
  )
  if final_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_final_shader_source", "Bloom2d pipeline error: final shader source not loaded",
    )
    return
  }
  let downsample_first_uniform_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_downsample_first_uniform_shader_id,
  )
  if downsample_first_uniform_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_downsample_first_uniform_shader_source", "Bloom2d pipeline error: downsample-first-uniform shader source not loaded",
    )
    return
  }
  let downsample_first_no_threshold_uniform_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_downsample_first_no_threshold_uniform_shader_id,
  )
  if downsample_first_no_threshold_uniform_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_downsample_first_no_threshold_uniform_shader_source",
      "Bloom2d pipeline error: downsample-first-no-threshold-uniform shader source not loaded",
    )
    return
  }
  let downsample_uniform_source_opt = get_shader_source(
    state,
    state.gpu.bloom2d_downsample_uniform_shader_id,
  )
  if downsample_uniform_source_opt is None {
    report_asset_error_once(
      state, "bloom2d_pipeline_missing_downsample_uniform_shader_source", "Bloom2d pipeline error: downsample-uniform shader source not loaded",
    )
    return
  }
  let downsample_first_source = downsample_first_source_opt.unwrap()
  let downsample_first_no_threshold_source = downsample_first_no_threshold_source_opt.unwrap()
  let downsample_source = downsample_source_opt.unwrap()
  let downsample_first_uniform_source = downsample_first_uniform_source_opt.unwrap()
  let downsample_first_no_threshold_uniform_source = downsample_first_no_threshold_uniform_source_opt.unwrap()
  let downsample_uniform_source = downsample_uniform_source_opt.unwrap()
  let upsample_source = upsample_source_opt.unwrap()
  let final_source = final_source_opt.unwrap()
  state.gpu.bloom2d_downsample_first_pipeline = bloom2d_create_pipeline(
    state, downsample_first_source, bind_layout, "downsample_first", bloom_mip_format,
    0,
  )
  state.gpu.bloom2d_downsample_first_no_threshold_pipeline = bloom2d_create_pipeline(
    state, downsample_first_no_threshold_source, bind_layout, "downsample_first",
    bloom_mip_format, 0,
  )
  state.gpu.bloom2d_downsample_pipeline = bloom2d_create_pipeline(
    state, downsample_source, bind_layout, "downsample", bloom_mip_format, 0,
  )
  state.gpu.bloom2d_downsample_first_uniform_pipeline = bloom2d_create_pipeline(
    state, downsample_first_uniform_source, bind_layout, "downsample_first", bloom_mip_format,
    0,
  )
  state.gpu.bloom2d_downsample_first_no_threshold_uniform_pipeline = bloom2d_create_pipeline(
    state, downsample_first_no_threshold_uniform_source, bind_layout, "downsample_first",
    bloom_mip_format, 0,
  )
  state.gpu.bloom2d_downsample_uniform_pipeline = bloom2d_create_pipeline(
    state, downsample_uniform_source, bind_layout, "downsample", bloom_mip_format,
    0,
  )
  state.gpu.bloom2d_upsample_pipeline_energy = bloom2d_create_pipeline(
    state, upsample_source, bind_layout, "upsample", bloom_mip_format, 1,
  )
  state.gpu.bloom2d_upsample_pipeline_additive = bloom2d_create_pipeline(
    state, upsample_source, bind_layout, "upsample", bloom_mip_format, 2,
  )
  state.gpu.bloom2d_final_pipeline_energy = bloom2d_create_pipeline(
    state, final_source, bind_layout, "final_fragment", format, 0,
  )
  state.gpu.bloom2d_final_pipeline_additive = bloom2d_create_pipeline(
    state, final_source, bind_layout, "final_fragment", format, 0,
  )
  state.gpu.bloom2d_mip_format = bloom_mip_format_key
  state.gpu.bloom2d_final_pipeline_format = format_key
  state.gpu.bloom2d_pipeline = state.gpu.bloom2d_final_pipeline_energy
}

///|
fn ensure_gizmo_pipeline(state : State) -> Unit {
  active_color_pipeline_format(state) |> ignore
  if state.gpu.gizmo_pipeline is Some(_) {
    return
  }
  if state.gpu.device is None {
    return
  }
  if state.gpu.device is Some(device) {
    if state.gpu.gizmo_shader_id <= 0 {
      return
    }
    let shader_source = get_shader_source(state, state.gpu.gizmo_shader_id)
    if shader_source is None {
      return
    }
    let format = active_color_pipeline_format(state)
    let shader_desc = @webgpu.shader_module_descriptor(shader_source.unwrap())
    let shader_module = device.create_shader_module(shader_desc.to_js())
    let position_attr = @webgpu.vertex_attribute(
      shader_location=0,
      offset=0,
      format=@webgpu.VertexFormat::Float32x2,
    )
    let color_attr = @webgpu.vertex_attribute(
      shader_location=1,
      offset=8,
      format=@webgpu.VertexFormat::Float32x4,
    )
    let vertex_layout = @webgpu.vertex_buffer_layout(24, [
      position_attr, color_attr,
    ])
    let vertex_state = @webgpu.vertex_state(shader_module, "vs_main", [
      vertex_layout,
    ])
    let blend_component = @webgpu.blend_component(
      @webgpu.BlendFactor::SrcAlpha,
      @webgpu.BlendFactor::OneMinusSrcAlpha,
      @webgpu.BlendOperation::Add,
    )
    let blend_state = @webgpu.blend_state(blend_component, blend_component)
    let color_target = @webgpu.color_target_state(format, blend_state)
    let fragment_state = @webgpu.fragment_state(shader_module, "fs_main", [
      color_target,
    ])
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
    )
    let pipeline_desc = @webgpu.render_pipeline_descriptor(
      @webgpu.PipelineLayout::Auto,
      vertex_state,
      fragment_state,
      primitive_state,
    )
    let pipeline = device.create_render_pipeline(pipeline_desc.to_js())
    state.gpu.gizmo_pipeline = Some(pipeline)
  }
}

///|
fn report_missing_texture(state : State, id : Int, reason : String) -> Unit {
  if set_has(state.assets.loading_textures, @js.any(id)) {
    return
  }
  if set_has(state.assets.missing_texture_reported, @js.any(id)) {
    return
  }
  set_add(state.assets.missing_texture_reported, @js.any(id))
  let path_hint = map_get(state.assets.texture_paths, @js.any(id))
  let suffix = if host_is_nullish(path_hint) {
    ""
  } else {
    " (path: " + path_hint.cast() + ")"
  }
  let message = "Texture skipped for id " +
    id.to_string() +
    ": " +
    reason +
    suffix
  console_error(@js.any(message))
  dispatch_asset_error(message)
}

///|
fn report_asset_error_once(
  state : State,
  key : String,
  message : String,
) -> Unit {
  if set_has(state.assets.reported_errors, @js.any(key)) {
    return
  }
  set_add(state.assets.reported_errors, @js.any(key))
  console_error(@js.any(message))
  dispatch_asset_error(message)
}

///|
fn report_debug_once(state : State, key : String, message : String) -> Unit {
  let full_key = "debug/" + key
  if set_has(state.assets.reported_errors, @js.any(full_key)) {
    return
  }
  set_add(state.assets.reported_errors, @js.any(full_key))
  @js.log(@js.any(message))
}

///|
fn profile_div_safe(total : Double, count : Int) -> Double {
  if count <= 0 {
    0.0
  } else {
    total / Float::from_int(count).to_double()
  }
}

///|
fn profile_div_int_safe(total : Int, count : Int) -> Double {
  if count <= 0 {
    0.0
  } else {
    Float::from_int(total).to_double() / Float::from_int(count).to_double()
  }
}

///|
fn profile_reset_window(state : State, now_ms : Double) -> Unit {
  state.gpu.profile_last_log_ms = now_ms
  state.gpu.profile_frames_accum = 0
  state.gpu.profile_frame_cpu_ms_accum = 0.0
  state.gpu.profile_pass_calls_accum = 0
  state.gpu.profile_draw_sprite_uv_calls_accum = 0
  state.gpu.profile_api_draw_sprite_uv_ms_accum = 0.0
  state.gpu.profile_api_begin_pass_ms_accum = 0.0
  state.gpu.profile_api_end_pass_ms_accum = 0.0
  state.gpu.profile_api_end_frame_ms_accum = 0.0
  state.gpu.profile_draw_ui_rect_calls_accum = 0
  state.gpu.profile_draw_ui_texture_slice_calls_accum = 0
  state.gpu.profile_draw_ui_box_shadow_calls_accum = 0
  state.gpu.profile_draw_mesh_calls_accum = 0
  state.gpu.profile_draw_mesh3d_calls_accum = 0
  state.gpu.profile_draw_motion_blur_calls_accum = 0
  state.gpu.profile_draw_bloom2d_calls_accum = 0
  state.gpu.profile_scissor_set_calls_accum = 0
  state.gpu.profile_scissor_clear_calls_accum = 0
  state.gpu.profile_sprite_instances_accum = 0
  state.gpu.profile_sprite_batches_accum = 0
  state.gpu.profile_ui_instances_accum = 0
  state.gpu.profile_ui_batches_accum = 0
}

///|
fn profile_log_if_needed(state : State) -> Unit {
  if !state.gpu.profile_enabled {
    return
  }
  let now_ms = performance_now()
  if state.gpu.profile_last_log_ms <= 0.0 {
    profile_reset_window(state, now_ms)
    return
  }
  if now_ms - state.gpu.profile_last_log_ms < 1000.0 {
    return
  }
  let frames = state.gpu.profile_frames_accum
  let avg_frame_ms = profile_div_safe(
    state.gpu.profile_frame_cpu_ms_accum,
    frames,
  )
  let avg_fps = if avg_frame_ms > 0.0 { 1000.0 / avg_frame_ms } else { 0.0 }
  let avg_passes = profile_div_int_safe(
    state.gpu.profile_pass_calls_accum,
    frames,
  )
  let avg_sprite_calls = profile_div_int_safe(
    state.gpu.profile_draw_sprite_uv_calls_accum,
    frames,
  )
  let avg_sprite_api_ms = profile_div_safe(
    state.gpu.profile_api_draw_sprite_uv_ms_accum,
    frames,
  )
  let avg_sprite_api_ms_per_call = profile_div_safe(
    state.gpu.profile_api_draw_sprite_uv_ms_accum,
    state.gpu.profile_draw_sprite_uv_calls_accum,
  )
  let avg_begin_pass_api_ms = profile_div_safe(
    state.gpu.profile_api_begin_pass_ms_accum,
    frames,
  )
  let avg_end_pass_api_ms = profile_div_safe(
    state.gpu.profile_api_end_pass_ms_accum,
    frames,
  )
  let avg_end_frame_api_ms = profile_div_safe(
    state.gpu.profile_api_end_frame_ms_accum,
    frames,
  )
  let avg_ui_rect_calls = profile_div_int_safe(
    state.gpu.profile_draw_ui_rect_calls_accum,
    frames,
  )
  let avg_ui_slice_calls = profile_div_int_safe(
    state.gpu.profile_draw_ui_texture_slice_calls_accum,
    frames,
  )
  let avg_ui_shadow_calls = profile_div_int_safe(
    state.gpu.profile_draw_ui_box_shadow_calls_accum,
    frames,
  )
  let avg_mesh_calls = profile_div_int_safe(
    state.gpu.profile_draw_mesh_calls_accum,
    frames,
  )
  let avg_mesh3d_calls = profile_div_int_safe(
    state.gpu.profile_draw_mesh3d_calls_accum,
    frames,
  )
  let avg_motion_blur_calls = profile_div_int_safe(
    state.gpu.profile_draw_motion_blur_calls_accum,
    frames,
  )
  let avg_bloom2d_calls = profile_div_int_safe(
    state.gpu.profile_draw_bloom2d_calls_accum,
    frames,
  )
  let avg_scissor_set = profile_div_int_safe(
    state.gpu.profile_scissor_set_calls_accum,
    frames,
  )
  let avg_scissor_clear = profile_div_int_safe(
    state.gpu.profile_scissor_clear_calls_accum,
    frames,
  )
  let avg_sprite_instances = profile_div_int_safe(
    state.gpu.profile_sprite_instances_accum,
    frames,
  )
  let avg_sprite_batches = profile_div_int_safe(
    state.gpu.profile_sprite_batches_accum,
    frames,
  )
  let avg_ui_instances = profile_div_int_safe(
    state.gpu.profile_ui_instances_accum,
    frames,
  )
  let avg_ui_batches = profile_div_int_safe(
    state.gpu.profile_ui_batches_accum,
    frames,
  )
  let sprite_batch_eff = if avg_sprite_batches > 0.0 {
    avg_sprite_instances / avg_sprite_batches
  } else {
    0.0
  }
  let ui_batch_eff = if avg_ui_batches > 0.0 {
    avg_ui_instances / avg_ui_batches
  } else {
    0.0
  }
  console_error(
    @js.any(
      "[mg_profile] fps=" +
      avg_fps.to_string() +
      " frame_ms=" +
      avg_frame_ms.to_string() +
      " passes/frame=" +
      avg_passes.to_string() +
      " sprite_calls/frame=" +
      avg_sprite_calls.to_string() +
      " sprite_api_ms/frame=" +
      avg_sprite_api_ms.to_string() +
      " sprite_api_ms/call=" +
      avg_sprite_api_ms_per_call.to_string() +
      " begin_pass_api_ms/frame=" +
      avg_begin_pass_api_ms.to_string() +
      " end_pass_api_ms/frame=" +
      avg_end_pass_api_ms.to_string() +
      " end_frame_api_ms/frame=" +
      avg_end_frame_api_ms.to_string() +
      " mesh_calls/frame=" +
      avg_mesh_calls.to_string() +
      " mesh3d_calls/frame=" +
      avg_mesh3d_calls.to_string() +
      " motion_blur_calls/frame=" +
      avg_motion_blur_calls.to_string() +
      " bloom2d_calls/frame=" +
      avg_bloom2d_calls.to_string() +
      " ui_rect_calls/frame=" +
      avg_ui_rect_calls.to_string() +
      " ui_slice_calls/frame=" +
      avg_ui_slice_calls.to_string() +
      " ui_shadow_calls/frame=" +
      avg_ui_shadow_calls.to_string() +
      " scissor_set/frame=" +
      avg_scissor_set.to_string() +
      " scissor_clear/frame=" +
      avg_scissor_clear.to_string() +
      " sprite_instances/frame=" +
      avg_sprite_instances.to_string() +
      " sprite_batches/frame=" +
      avg_sprite_batches.to_string() +
      " sprite_inst_per_batch=" +
      sprite_batch_eff.to_string() +
      " ui_instances/frame=" +
      avg_ui_instances.to_string() +
      " ui_batches/frame=" +
      avg_ui_batches.to_string() +
      " ui_inst_per_batch=" +
      ui_batch_eff.to_string(),
    ),
  )
  profile_reset_window(state, now_ms)
}

///|
fn get_shader_source(state : State, id : Int) -> String? {
  let entry = map_get(state.assets.shader_sources, @js.any(id))
  if host_is_nullish(entry) {
    None
  } else {
    Some(entry.cast())
  }
}

///|
fn get_texture_entry(state : State, id : Int) -> @js.Any? {
  let entry = map_get(state.gpu.textures, @js.any(id))
  if !host_is_nullish(entry) {
    let view = entry._get("view")
    let sampler = entry._get("sampler")
    if !host_is_nullish(view) && !host_is_nullish(sampler) {
      return Some(entry)
    }
  }
  if set_has(state.assets.loading_textures, @js.any(id)) {
    // Skip drawing while the texture is still loading to avoid transient
    // missing-texture flashes (especially visible for atlas/rect sprites).
    return None
  }
  let reason = if host_is_nullish(entry) {
    "texture id not found"
  } else {
    "texture not ready"
  }
  report_missing_texture(state, id, reason)
  None
}

///|
fn get_texture_entry_strict(state : State, id : Int) -> @js.Any? {
  let entry = map_get(state.gpu.textures, @js.any(id))
  if host_is_nullish(entry) {
    return None
  }
  let view = entry._get("view")
  let sampler = entry._get("sampler")
  if host_is_nullish(view) || host_is_nullish(sampler) {
    None
  } else {
    Some(entry)
  }
}

///|
fn resolved_texture_sampler_kind(
  state : State,
  texture_id : Int,
  default_kind : Int,
) -> Int {
  let override_any = map_get(
    state.assets.texture_sampler_overrides,
    @js.any(texture_id),
  )
  if host_is_nullish(override_any) {
    default_kind
  } else {
    to_int(number_or(override_any, default_kind.to_double()))
  }
}

///|
fn insert_texture_entry(
  state : State,
  id : Int,
  texture : @webgpu.GPUTexture,
  width : Int,
  height : Int,
  nearest : Bool,
) -> Unit {
  let default_sampler_kind = sampler_kind_from_nearest(nearest)
  let sampler_kind = resolved_texture_sampler_kind(
    state, id, default_sampler_kind,
  )
  let sampler = create_sampler(state, sampler_kind)
  if sampler is Some(sampler_value) {
    let entry = @js.from_entries([
      ("id", @js.any(id)),
      ("texture", texture.as_any()),
      ("view", texture.create_view().as_any()),
      ("sampler", sampler_value.as_any()),
      ("bindGroup", js_null()),
      ("meshBindGroup", js_null()),
      ("mesh3dBindGroup", js_null()),
      ("uiBindGroup", js_null()),
      ("width", @js.any(width)),
      ("height", @js.any(height)),
      ("format", @js.any(@webgpu.TextureFormat::Rgba8UnormSrgb.to_js_string())),
    ])
    map_set(state.gpu.textures, @js.any(id), entry)
    let path_any = map_get(state.assets.texture_paths, @js.any(id))
    let path_text = if host_is_nullish(path_any) {
      "<unknown>"
    } else {
      any_to_string(path_any)
    }
    report_debug_once(
      state,
      "texture_loaded_" + id.to_string(),
      "texture loaded: id=" +
      id.to_string() +
      " size=" +
      width.to_string() +
      "x" +
      height.to_string() +
      " path=" +
      path_text,
    )
    ensure_bind_group_for_texture(state, entry)
  }
}

///|
async fn load_texture_from_ktx2_bytes(
  state : State,
  id : Int,
  bytes_data : @js.Any,
  nearest : Bool,
) -> Unit {
  ensure_pipeline_resources(state)
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let parsed = parse_ktx2_stacked_upload(bytes_data).wait()
    if host_is_nullish(parsed) {
      report_asset_error_once(
        state,
        "texture_ktx2_parse_" + id.to_string(),
        "Failed to parse KTX2 texture bytes",
      )
      return
    }
    let width = to_int(number_or(parsed._get("width"), 0))
    let height_per_slice = to_int(number_or(parsed._get("heightPerSlice"), 0))
    let slice_count = to_int(number_or(parsed._get("sliceCount"), 0))
    if width <= 0 || height_per_slice <= 0 || slice_count <= 0 {
      report_asset_error_once(
        state,
        "texture_ktx2_invalid_size_" + id.to_string(),
        "Invalid KTX2 texture dimensions",
      )
      return
    }
    let stacked_height = height_per_slice * slice_count
    if stacked_height <= 0 {
      report_asset_error_once(
        state,
        "texture_ktx2_stacked_height_" + id.to_string(),
        "Invalid stacked KTX2 texture height",
      )
      return
    }
    let levels = parsed._get("levels")
    let widths = parsed._get("widths")
    let heights = parsed._get("heights")
    let bytes_per_rows = parsed._get("bytesPerRows")
    let rows_per_images = parsed._get("rowsPerImages")
    let mip_count = array_len(levels)
    if mip_count <= 0 {
      report_asset_error_once(
        state,
        "texture_ktx2_mips_" + id.to_string(),
        "KTX2 texture has no mip levels",
      )
      return
    }
    let texture_usage = @webgpu.combine_flags(
      @webgpu.texture_usage_texture_binding(),
      @webgpu.texture_usage_copy_dst(),
    )
    let texture_desc = @js.from_entries([
      ("size", @js.any([width, stacked_height, 1])),
      ("format", parsed._get("format")),
      ("usage", @js.any(texture_usage)),
      ("mipLevelCount", @js.any(mip_count)),
      ("dimension", @js.any("2d")),
    ])
    let texture = device.create_texture(texture_desc)
    for mip in 0..<mip_count {
      let level_data = array_get(levels, mip)
      let mip_width = to_int(number_or(array_get(widths, mip), 0))
      let mip_height = to_int(number_or(array_get(heights, mip), 0))
      let bytes_per_row = to_int(number_or(array_get(bytes_per_rows, mip), 0))
      let rows_per_image = to_int(number_or(array_get(rows_per_images, mip), 0))
      if mip_width <= 0 ||
        mip_height <= 0 ||
        bytes_per_row <= 0 ||
        rows_per_image <= 0 {
        report_asset_error_once(
          state,
          "texture_ktx2_layout_" + id.to_string(),
          "Invalid KTX2 mip upload layout",
        )
        return
      }
      write_texture_mip(
        queue.as_any(),
        texture.as_any(),
        level_data,
        bytes_per_row,
        rows_per_image,
        mip_width,
        mip_height,
        mip,
      )
    }
    insert_texture_entry(state, id, texture, width, stacked_height, nearest)
    return
  }
}

///|
async fn load_texture_from_uint8array(
  state : State,
  id : Int,
  bytes_data : @js.Any,
  nearest : Bool,
) -> Unit {
  if is_ktx2_uint8array(bytes_data) {
    load_texture_from_ktx2_bytes(state, id, bytes_data, nearest)
    set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
    return
  }
  let blob = blob_from_uint8array(bytes_data)
  load_texture_from_blob(state, id, blob, nearest)
}

///|
async fn load_texture_from_path(
  state : State,
  id : Int,
  path : @js.Any,
  nearest : Bool,
) -> Unit {
  if state.gpu.device is None || state.gpu.queue is None {
    state.assets.pending_textures.push(PendingTexture::{
      id,
      path,
      bytes_id: 0,
      nearest,
    })
    return
  }
  let url = resolve_asset_url(state, path)
  let response = @http.fetch(url, method_="GET")
  if !response.ok {
    fail(
      "Failed to load texture: " +
      url +
      " (" +
      response.status.to_string() +
      ")",
    )
  }
  let bytes_data = uint8array_from_array_buffer(
    response_array_buffer(response.as_any()).wait(),
  )
  load_texture_from_uint8array(state, id, bytes_data, nearest)
}

///|
async fn load_texture_from_blob_id(
  state : State,
  id : Int,
  blob_id : Int,
  nearest : Bool,
) -> Unit {
  if state.gpu.device is None || state.gpu.queue is None {
    state.assets.pending_textures.push(PendingTexture::{
      id,
      path: js_null(),
      bytes_id: blob_id,
      nearest,
    })
    return
  }
  let blob_bytes = map_get(state.assets.blobs, @js.any(blob_id))
  if host_is_nullish(blob_bytes) {
    fail("Failed to load texture bytes: bytes id not found")
  }
  load_texture_from_uint8array(state, id, blob_bytes, nearest)
}

///|
async fn load_texture_from_blob(
  state : State,
  id : Int,
  blob : @js.Any,
  nearest : Bool,
) -> Unit {
  let image = create_image_bitmap(blob).wait()
  ensure_pipeline_resources(state)
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let width : Int = image._get("width").cast()
    let height : Int = image._get("height").cast()
    let texture_usage = @webgpu.combine_flags(
      @webgpu.combine_flags(
        @webgpu.combine_flags(
          @webgpu.texture_usage_texture_binding(),
          @webgpu.texture_usage_copy_dst(),
        ),
        @webgpu.texture_usage_copy_src(),
      ),
      @webgpu.texture_usage_render_attachment(),
    )
    let texture_desc = @webgpu.texture_descriptor(
      @webgpu.texture_size(width, height),
      @webgpu.TextureFormat::Rgba8UnormSrgb,
      texture_usage,
    )
    let texture = device.create_texture(texture_desc.to_js())
    copy_external_image_to_texture(
      queue.as_any(),
      image,
      texture.as_any(),
      width,
      height,
    )
    insert_texture_entry(state, id, texture, width, height, nearest)
  }
  set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
}

///|
async fn load_wgsl_preprocessed(
  state : State,
  rel_path : String,
  defines : Array[String],
  visited : @js.Any,
) -> String {
  let normalized = normalize_shader_rel_path_for_runtime(rel_path)
  if normalized == "" {
    return ""
  }
  if set_has(visited, @js.any(normalized)) {
    return ""
  }
  set_add(visited, @js.any(normalized))
  let source = fetch_text_from_url(
    resolve_asset_url(state, @js.any(normalized)),
  )
  let import_specs = wgsl_extract_import_specs(source)
  let mut expanded = ""
  let aliases : Array[String] = []
  for spec in import_specs {
    let module_rel = wgsl_import_spec_to_rel_path(spec).trim().to_string()
    let module_alias = wgsl_import_spec_to_alias(spec).trim().to_string()
    if module_alias != "" {
      aliases.push(module_alias)
    }
    if module_rel == "" {
      continue
    }
    let module_source = load_wgsl_preprocessed(
      state, module_rel, defines, visited,
    )
    if module_source != "" {
      expanded = expanded + module_source + "\n"
    }
  }
  let stripped = wgsl_strip_import_define_lines(source)
  wgsl_strip_module_aliases(
    wgsl_apply_ifdefs(expanded + stripped, defines),
    aliases,
  )
}

///|
fn normalize_shader_rel_path_for_runtime(path : String) -> String {
  let mut normalized = strip_leading_slashes(path.trim().to_string())
  while normalized.length() >= 2 && (try! normalized[:2].to_string()) == "./" {
    normalized = try! normalized[2:normalized.length()].to_string()
  }
  if normalized.length() >= 7 && (try! normalized[:7].to_string()) == "assets/" {
    normalized = try! normalized[7:normalized.length()].to_string()
  }
  normalized
}

///|
fn is_motion_blur_shader_path(path : String) -> Bool {
  normalize_shader_rel_path_for_runtime(path) ==
  "shaders/mgstudio/3d/motion_blur.wgsl"
}

///|
async fn load_wgsl_from_path(state : State, id : Int, path : String) -> String {
  let visited = new_set()
  let defines : Array[String] = []
  let normalized = normalize_shader_rel_path_for_runtime(path)
  let source_raw = load_wgsl_preprocessed(state, normalized, defines, visited)
  let source = if is_motion_blur_shader_path(normalized) {
    wgsl_lower_motion_blur_texture_samples_for_webgpu(source_raw)
  } else {
    source_raw
  }
  map_set(state.assets.shader_sources, @js.any(id), @js.any(source))
  source
}

///|
async fn fetch_text_from_url(url : String) -> String {
  let response = @http.fetch(url, method_="GET", cache="no-store")
  if !response.ok {
    fail("Failed to fetch: " + url + " (" + response.status.to_string() + ")")
  }
  response_text(response.as_any()).wait()
}

///|
fn make_uniform_data(values : Array[Double]) -> @js.Any {
  float32array_from_array(values)
}

///|
fn arg_any(args : Array[@js.Any], index : Int) -> @js.Any {
  if index < args.length() {
    args[index]
  } else {
    js_undefined()
  }
}

///|
fn arg_number(
  args : Array[@js.Any],
  index : Int,
  default_value : Double,
) -> Double {
  number_or(arg_any(args, index), default_value)
}

///|
fn ensure_pass_ready(state : State) -> Bool {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return false
  }
  if state.gpu.pipeline is None {
    return false
  }
  if state.gpu.uniform_buffer is None {
    return false
  }
  true
}

///|
fn create_transient_uniform_bind_group(
  state : State,
  pipeline : @webgpu.GPURenderPipeline,
  values : Array[Double],
) -> @webgpu.GPUBindGroup? {
  guard state.gpu.device is Some(device) else { return None }
  guard state.gpu.queue is Some(queue) else { return None }
  let data = make_uniform_data(values)
  let byte_length_raw : Int = data._get("byteLength").cast()
  if byte_length_raw <= 0 {
    return None
  }
  let uniform_usage = @webgpu.combine_flags(
    @webgpu.buffer_usage_uniform(),
    @webgpu.buffer_usage_copy_dst(),
  )
  let uniform_desc = @webgpu.buffer_descriptor(byte_length_raw, uniform_usage)
  let uniform_buffer = device.create_buffer(uniform_desc.to_js())
  queue.write_buffer(uniform_buffer, 0, data)
  let layout = pipeline.get_bind_group_layout(0)
  let entries = [@webgpu.bind_group_entry_buffer(0, uniform_buffer)]
  let bind_group_desc = @webgpu.bind_group_descriptor(layout, entries)
  Some(device.create_bind_group(bind_group_desc.to_js()))
}

///|
fn begin_frame(state : State) -> Int {
  if state.gpu.context is None || state.gpu.device is None {
    return 0
  }
  if state.gpu.context is Some(context) && state.gpu.device is Some(device) {
    if state.gpu.profile_enabled {
      let now_ms = performance_now()
      if state.gpu.profile_last_log_ms <= 0.0 {
        profile_reset_window(state, now_ms)
      }
      state.gpu.profile_frame_begin_ms = now_ms
    }
    let next_frame = state.gpu.frame_count + 1
    let max_counter : Int = 2147483647
    state.gpu.frame_count = if next_frame < 0 || next_frame > max_counter {
      0
    } else {
      next_frame
    }
    update_window_size(state)
    ensure_pipeline_resources(state)
    // Capture per-frame validation errors (including draw command issues) that
    // might otherwise fail silently in some browsers.
    //
    // We pop this scope in `gpu_end_frame` after submitting the command buffer.
    device.push_error_scope("validation")
    state.gpu.encoder = Some(device.create_command_encoder())
    state.gpu.current_texture = Some(context.get_current_texture())
    return 1
  }
  0
}

///|
fn current_surface_view_descriptor(state : State) -> @js.Any? {
  let surface_format = state.gpu.surface_format.unwrap_or(
    state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm),
  )
  let view_format = state.gpu.format.unwrap_or(surface_format)
  if state.gpu.surface_view_format_enabled &&
    view_format.to_js_string() != surface_format.to_js_string() {
    Some(@js.from_entries([("format", @js.any(view_format.to_js_string()))]))
  } else {
    None
  }
}

///|
fn begin_pass(
  state : State,
  target_id : Int,
  width : Double,
  height : Double,
  clear_r : Double,
  clear_g : Double,
  clear_b : Double,
  clear_a : Double,
  cam_x : Double,
  cam_y : Double,
  cam_rotation : Double,
  cam_scale : Double,
  is_3d : Bool,
  cam_z : Double,
  cam_rot_x : Double,
  cam_rot_y : Double,
  cam_rot_z : Double,
  cam_rot_w : Double,
  cam_fov_y : Double,
  cam_near : Double,
  cam_far : Double,
  viewport_x : Double,
  viewport_y : Double,
  viewport_width : Double,
  viewport_height : Double,
  viewport_depth_min : Double,
  viewport_depth_max : Double,
  ambient_r : Double,
  ambient_g : Double,
  ambient_b : Double,
  ambient_brightness : Double,
  directional_dir_x : Double,
  directional_dir_y : Double,
  directional_dir_z : Double,
  directional_color_r : Double,
  directional_color_g : Double,
  directional_color_b : Double,
  directional_illuminance : Double,
  point_pos_x : Double,
  point_pos_y : Double,
  point_pos_z : Double,
  point_color_r : Double,
  point_color_g : Double,
  point_color_b : Double,
  point_intensity : Double,
  point_range : Double,
  spot_pos_x : Double,
  spot_pos_y : Double,
  spot_pos_z : Double,
  spot_dir_x : Double,
  spot_dir_y : Double,
  spot_dir_z : Double,
  spot_color_r : Double,
  spot_color_g : Double,
  spot_color_b : Double,
  spot_intensity : Double,
  spot_range : Double,
  spot_inner_angle : Double,
  spot_outer_angle : Double,
  sub_camera_view_scale_x : Double,
  sub_camera_view_scale_y : Double,
  sub_camera_view_bias_x : Double,
  sub_camera_view_bias_y : Double,
  previous_camera_x : Double,
  previous_camera_y : Double,
  previous_camera_z : Double,
  previous_camera_rot_x : Double,
  previous_camera_rot_y : Double,
  previous_camera_rot_z : Double,
  previous_camera_rot_w : Double,
  pass_kind : Double,
  clear_enabled : Double,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_pass_calls_accum = state.gpu.profile_pass_calls_accum + 1
  }
  if state.gpu.encoder is None {
    return
  }
  if state.gpu.encoder is Some(encoder) {
    let mut view : @webgpu.GPUTextureView? = None
    let mut target_width = if width > 0 { to_int(width) } else { 1 }
    let mut target_height = if height > 0 { to_int(height) } else { 1 }
    if target_id < 0 {
      if state.gpu.current_texture is Some(current_texture) {
        view = Some(
          match current_surface_view_descriptor(state) {
            Some(descriptor) => current_texture.create_view(descriptor~)
            None => current_texture.create_view()
          },
        )
      }
      if state.window is Some(window_state) {
        target_width = window_state.width
        target_height = window_state.height
      }
    } else {
      let target_entry = map_get(state.gpu.textures, @js.any(target_id))
      if !host_is_nullish(target_entry) {
        let view_any = target_entry._get("view")
        if !host_is_nullish(view_any) {
          view = Some(view_any.cast())
        }
        target_width = to_int(number_or(target_entry._get("width"), width))
        target_height = to_int(number_or(target_entry._get("height"), height))
      }
    }
    if view is None {
      return
    }
    if view is Some(view_value) {
      let attachment = if clear_enabled == 0.0 {
        @webgpu.color_attachment_load(view_value)
      } else {
        let clear_color = @webgpu.color(clear_r, clear_g, clear_b, clear_a)
        @webgpu.color_attachment_clear(view_value, clear_color)
      }
      let vp_width = if viewport_width > 0 { viewport_width } else { width }
      let vp_height = if viewport_height > 0 { viewport_height } else { height }
      let vp_x = if viewport_width > 0 { viewport_x } else { 0 }
      let vp_y = if viewport_height > 0 { viewport_y } else { 0 }
      if is_3d {
        ensure_depth_texture(state, target_width, target_height)
      }
      let descriptor_any = if is_3d {
        if state.gpu.depth_view is Some(depth_view) {
          let depth_attachment = @js.from_entries([
            ("view", depth_view.as_any()),
            ("depthClearValue", @js.any(1.0)),
            ("depthLoadOp", @js.any("clear")),
            ("depthStoreOp", @js.any("store")),
          ])
          @js.from_entries([
            ("colorAttachments", @js.any([attachment.to_js()])),
            ("depthStencilAttachment", depth_attachment),
          ])
        } else {
          @webgpu.render_pass_descriptor([attachment]).to_js()
        }
      } else {
        @webgpu.render_pass_descriptor([attachment]).to_js()
      }
      let pass = encoder.begin_render_pass(descriptor_any)
      pass.set_viewport(
        vp_x, vp_y, vp_width, vp_height, viewport_depth_min, viewport_depth_max,
      )
      pass.set_scissor_rect(
        to_int(vp_x),
        to_int(vp_y),
        to_int(vp_width),
        to_int(vp_height),
      )
      state.gpu.current_pass = Some(pass)
      state.gpu.current_pass_info = Some(PassInfo::{
        target_id,
        width: if width > 0 {
          width
        } else {
          1
        },
        height: if height > 0 {
          height
        } else {
          1
        },
        cam_x,
        cam_y,
        cam_rotation,
        cam_scale,
        cam_z,
        cam_rot_x,
        cam_rot_y,
        cam_rot_z,
        cam_rot_w,
        cam_fov_y,
        cam_near,
        cam_far,
        sub_camera_view_scale_x,
        sub_camera_view_scale_y,
        sub_camera_view_bias_x,
        sub_camera_view_bias_y,
        previous_camera_x,
        previous_camera_y,
        previous_camera_z,
        previous_camera_rot_x,
        previous_camera_rot_y,
        previous_camera_rot_z,
        previous_camera_rot_w,
        pass_kind,
        viewport_x: vp_x,
        viewport_y: vp_y,
        viewport_width: vp_width,
        viewport_height: vp_height,
        viewport_depth_min,
        viewport_depth_max,
        ambient_r,
        ambient_g,
        ambient_b,
        ambient_brightness,
        directional_dir_x,
        directional_dir_y,
        directional_dir_z,
        directional_color_r,
        directional_color_g,
        directional_color_b,
        directional_illuminance,
        point_pos_x,
        point_pos_y,
        point_pos_z,
        point_color_r,
        point_color_g,
        point_color_b,
        point_intensity,
        point_range,
        spot_pos_x,
        spot_pos_y,
        spot_pos_z,
        spot_dir_x,
        spot_dir_y,
        spot_dir_z,
        spot_color_r,
        spot_color_g,
        spot_color_b,
        spot_intensity,
        spot_range,
        spot_inner_angle,
        spot_outer_angle,
      })
      state.gpu.gizmo_lines = new_array()
      state.gpu.sprite_instance_data.clear()
      state.gpu.sprite_batches.clear()
      state.gpu.sprite_instance_count = 0
      state.gpu.sprite_instance_buffer_write_offset = 0
      state.gpu.ui_instance_data.clear()
      state.gpu.ui_batches.clear()
      state.gpu.ui_instance_count = 0
      ensure_pipeline_resources(state)
      if state.gpu.queue is Some(queue) &&
        state.gpu.sprite_uniform_buffer is Some(sprite_uniform_buffer) {
        let safe_scale = if cam_scale == 0 { 1.0 } else { cam_scale }
        let scale_x_base = if width > 0 {
          2.0 / width / safe_scale
        } else {
          0.0
        }
        let scale_y_base = if height > 0 {
          2.0 / height / safe_scale
        } else {
          0.0
        }
        let cam_cos : Double = math_cos(-cam_rotation)
        let cam_sin : Double = math_sin(-cam_rotation)
        // Globals: view(x,y,cos,sin) + ndc_scale(x,y,_,_)
        let globals = make_uniform_data([
          cam_x, cam_y, cam_cos, cam_sin, scale_x_base, scale_y_base, 0.0, 0.0,
        ])
        queue.write_buffer(sprite_uniform_buffer, 0, globals)
      }
    }
  }
}

///|
fn flush_sprite_batches(state : State) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  if state.gpu.sprite_instance_count <= 0 {
    return
  }
  if state.gpu.device is None || state.gpu.queue is None {
    return
  }
  ensure_pipeline_resources(state)
  if state.gpu.pipeline is None ||
    state.gpu.sprite_instance_buffer is None ||
    state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let write_offset_floats = state.gpu.sprite_instance_buffer_write_offset
    let write_offset_bytes = write_offset_floats * 4
    let write_bytes = state.gpu.sprite_instance_data.length() * 4
    if write_bytes <= 0 {
      return
    }
    let required_bytes = write_offset_bytes + write_bytes
    if required_bytes > state.gpu.sprite_instance_capacity {
      let capacity = if required_bytes < 256 { 256 } else { required_bytes }
      let usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_storage(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let desc = @webgpu.buffer_descriptor(capacity, usage)
      let buffer = device.create_buffer(desc.to_js())
      state.gpu.sprite_instance_buffer = Some(buffer)
      state.gpu.sprite_instance_capacity = capacity
      state.gpu.sprite_globals_bind_group = None
    }
    ensure_sprite_globals_bind_group(state)
    if state.gpu.sprite_instance_buffer is Some(instance_buffer) &&
      state.gpu.sprite_globals_bind_group is Some(globals_bind_group) &&
      state.gpu.pipeline is Some(pipeline) &&
      state.gpu.current_pass is Some(pass) {
      let mut batch_summary = ""
      for batch in state.gpu.sprite_batches {
        let entry_opt = get_texture_entry(state, batch.texture_id)
        let mut status = "missing-entry"
        let mut path_text = "<unknown>"
        if entry_opt is Some(entry_value) {
          let bind_group_any = entry_value._get("bindGroup")
          let path_any = map_get(
            state.assets.texture_paths,
            @js.any(batch.texture_id),
          )
          path_text = if host_is_nullish(path_any) {
            "<unknown>"
          } else {
            any_to_string(path_any)
          }
          status = if host_is_nullish(bind_group_any) {
            "missing-bind-group"
          } else {
            "ready"
          }
        }
        batch_summary = batch_summary +
          " [tex=" +
          batch.texture_id.to_string() +
          " first=" +
          batch.first_instance.to_string() +
          " count=" +
          batch.instance_count.to_string() +
          " status=" +
          status +
          " path=" +
          path_text +
          "]"
      }
      let pass_target_text = match state.gpu.current_pass_info {
        Some(info) => info.target_id.to_string()
        None => "<none>"
      }
      report_debug_once(
        state,
        "flush_sprite_batches_summary",
        "flush_sprite_batches: instances=" +
        state.gpu.sprite_instance_count.to_string() +
        " batches=" +
        state.gpu.sprite_batches.length().to_string() +
        " target_id=" +
        pass_target_text +
        batch_summary,
      )
      if state.gpu.profile_enabled {
        state.gpu.profile_sprite_instances_accum = state.gpu.profile_sprite_instances_accum +
          state.gpu.sprite_instance_count
        state.gpu.profile_sprite_batches_accum = state.gpu.profile_sprite_batches_accum +
          state.gpu.sprite_batches.length()
      }
      let instance_base = write_offset_floats / 16
      let instance_data = float32array_from_array(
        state.gpu.sprite_instance_data,
      )
      queue.write_buffer(instance_buffer, write_offset_bytes, instance_data)
      pass.set_pipeline(pipeline)
      pass.set_bind_group(1, globals_bind_group)
      for batch in state.gpu.sprite_batches {
        let entry = get_texture_entry(state, batch.texture_id)
        if entry is None {
          report_asset_error_once(
            state,
            "sprite_batch_missing_entry_" + batch.texture_id.to_string(),
            "sprite batch skipped: missing texture entry for tex=" +
            batch.texture_id.to_string(),
          )
          continue
        }
        if entry is Some(entry_value) {
          ensure_bind_group_for_texture(state, entry_value)
          let bind_group_any = entry_value._get("bindGroup")
          if host_is_nullish(bind_group_any) {
            let path_any = map_get(
              state.assets.texture_paths,
              @js.any(batch.texture_id),
            )
            let path_text = if host_is_nullish(path_any) {
              "<unknown>"
            } else {
              any_to_string(path_any)
            }
            report_asset_error_once(
              state,
              "sprite_batch_missing_bind_group_" + batch.texture_id.to_string(),
              "sprite batch skipped: missing bind group for tex=" +
              batch.texture_id.to_string() +
              " path=" +
              path_text,
            )
            continue
          }
          pass.set_bind_group(0, bind_group_any.cast())
          pass.draw(
            state.gpu.vertex_count,
            batch.instance_count,
            0,
            batch.first_instance + instance_base,
          )
          let pass_target_text = match state.gpu.current_pass_info {
            Some(info) => info.target_id.to_string()
            None => "<none>"
          }
          report_debug_once(
            state,
            "sprite_batch_drawn_tex_" + batch.texture_id.to_string(),
            "sprite batch drawn: tex=" +
            batch.texture_id.to_string() +
            " first=" +
            (batch.first_instance + instance_base).to_string() +
            " count=" +
            batch.instance_count.to_string() +
            " target_id=" +
            pass_target_text,
          )
        }
      }
      state.gpu.sprite_instance_buffer_write_offset = write_offset_floats +
        state.gpu.sprite_instance_data.length()
      state.gpu.sprite_instance_data.clear()
      state.gpu.sprite_batches.clear()
      state.gpu.sprite_instance_count = 0
    }
  }
}

///|
fn flush_ui_batches(state : State) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  if state.gpu.ui_instance_count <= 0 {
    return
  }
  if state.gpu.device is None || state.gpu.queue is None {
    return
  }
  ensure_ui_pipeline_resources(state)
  if state.gpu.ui_pipeline is None ||
    state.gpu.ui_instance_buffer is None ||
    state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let required_bytes = state.gpu.ui_instance_data.length() * 4
    if required_bytes <= 0 {
      return
    }
    if required_bytes > state.gpu.ui_instance_capacity {
      let capacity = if required_bytes < 256 { 256 } else { required_bytes }
      let usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_storage(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let desc = @webgpu.buffer_descriptor(capacity, usage)
      let buffer = device.create_buffer(desc.to_js())
      state.gpu.ui_instance_buffer = Some(buffer)
      state.gpu.ui_instance_capacity = capacity
      state.gpu.ui_globals_bind_group = None
    }
    ensure_ui_globals_bind_group(state)
    if state.gpu.ui_instance_buffer is Some(instance_buffer) &&
      state.gpu.ui_globals_bind_group is Some(globals_bind_group) &&
      state.gpu.ui_pipeline is Some(pipeline) &&
      state.gpu.current_pass is Some(pass) {
      if state.gpu.profile_enabled {
        state.gpu.profile_ui_instances_accum = state.gpu.profile_ui_instances_accum +
          state.gpu.ui_instance_count
        state.gpu.profile_ui_batches_accum = state.gpu.profile_ui_batches_accum +
          state.gpu.ui_batches.length()
      }
      let instance_data = float32array_from_array(state.gpu.ui_instance_data)
      queue.write_buffer(instance_buffer, 0, instance_data)
      pass.set_pipeline(pipeline)
      pass.set_bind_group(1, globals_bind_group)
      for batch in state.gpu.ui_batches {
        let entry = get_texture_entry(state, batch.texture_id)
        if entry is None {
          continue
        }
        if entry is Some(entry_value) {
          ensure_ui_bind_group_for_texture(state, entry_value)
          let bind_group_any = entry_value._get("uiBindGroup")
          if host_is_nullish(bind_group_any) {
            continue
          }
          pass.set_bind_group(0, bind_group_any.cast())
          pass.draw(
            state.gpu.vertex_count,
            batch.instance_count,
            0,
            batch.first_instance,
          )
        }
      }
      state.gpu.ui_instance_data.clear()
      state.gpu.ui_batches.clear()
      state.gpu.ui_instance_count = 0
    }
  }
}

///|
fn flush_ui_shadow_batches(state : State) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  if state.gpu.ui_shadow_instance_count <= 0 {
    return
  }
  if state.gpu.device is None || state.gpu.queue is None {
    return
  }
  ensure_ui_shadow_pipeline_resources(state)
  if state.gpu.ui_shadow_pipeline is None ||
    state.gpu.ui_shadow_instance_buffer is None ||
    state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let required_bytes = state.gpu.ui_shadow_instance_data.length() * 4
    if required_bytes <= 0 {
      return
    }
    if required_bytes > state.gpu.ui_shadow_instance_capacity {
      let capacity = if required_bytes < 256 { 256 } else { required_bytes }
      let usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_storage(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let desc = @webgpu.buffer_descriptor(capacity, usage)
      let buffer = device.create_buffer(desc.to_js())
      state.gpu.ui_shadow_instance_buffer = Some(buffer)
      state.gpu.ui_shadow_instance_capacity = capacity
      state.gpu.ui_shadow_globals_bind_group = None
    }
    ensure_ui_shadow_globals_bind_group(state)
    if state.gpu.ui_shadow_instance_buffer is Some(instance_buffer) &&
      state.gpu.ui_shadow_globals_bind_group is Some(globals_bind_group) &&
      state.gpu.ui_shadow_pipeline is Some(pipeline) &&
      state.gpu.current_pass is Some(pass) {
      if state.gpu.profile_enabled {
        state.gpu.profile_ui_instances_accum = state.gpu.profile_ui_instances_accum +
          state.gpu.ui_shadow_instance_count
        state.gpu.profile_ui_batches_accum = state.gpu.profile_ui_batches_accum +
          state.gpu.ui_shadow_batches.length()
      }
      let instance_data = float32array_from_array(
        state.gpu.ui_shadow_instance_data,
      )
      queue.write_buffer(instance_buffer, 0, instance_data)
      pass.set_pipeline(pipeline)
      pass.set_bind_group(1, globals_bind_group)
      for batch in state.gpu.ui_shadow_batches {
        let entry = get_texture_entry(state, batch.texture_id)
        if entry is None {
          continue
        }
        if entry is Some(entry_value) {
          ensure_ui_shadow_bind_group_for_texture(state, entry_value)
          let bind_group_any = entry_value._get("uiShadowBindGroup")
          if host_is_nullish(bind_group_any) {
            continue
          }
          pass.set_bind_group(0, bind_group_any.cast())
          pass.draw(
            state.gpu.vertex_count,
            batch.instance_count,
            0,
            batch.first_instance,
          )
        }
      }
      state.gpu.ui_shadow_instance_data.clear()
      state.gpu.ui_shadow_batches.clear()
      state.gpu.ui_shadow_instance_count = 0
    }
  }
}

///|
fn flush_ui_slice_batches(state : State) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  if state.gpu.ui_slice_instance_count <= 0 {
    return
  }
  if state.gpu.device is None || state.gpu.queue is None {
    return
  }
  ensure_ui_slice_pipeline_resources(state)
  if state.gpu.ui_slice_pipeline is None ||
    state.gpu.ui_slice_instance_buffer is None ||
    state.gpu.sprite_uniform_buffer is None {
    return
  }
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let required_bytes = state.gpu.ui_slice_instance_data.length() * 4
    if required_bytes <= 0 {
      return
    }
    if required_bytes > state.gpu.ui_slice_instance_capacity {
      let capacity = if required_bytes < 256 { 256 } else { required_bytes }
      let usage = @webgpu.combine_flags(
        @webgpu.buffer_usage_storage(),
        @webgpu.buffer_usage_copy_dst(),
      )
      let desc = @webgpu.buffer_descriptor(capacity, usage)
      let buffer = device.create_buffer(desc.to_js())
      state.gpu.ui_slice_instance_buffer = Some(buffer)
      state.gpu.ui_slice_instance_capacity = capacity
      state.gpu.ui_slice_globals_bind_group = None
    }
    ensure_ui_slice_globals_bind_group(state)
    if state.gpu.ui_slice_instance_buffer is Some(instance_buffer) &&
      state.gpu.ui_slice_globals_bind_group is Some(globals_bind_group) &&
      state.gpu.ui_slice_pipeline is Some(pipeline) &&
      state.gpu.current_pass is Some(pass) {
      if state.gpu.profile_enabled {
        state.gpu.profile_ui_instances_accum = state.gpu.profile_ui_instances_accum +
          state.gpu.ui_slice_instance_count
        state.gpu.profile_ui_batches_accum = state.gpu.profile_ui_batches_accum +
          state.gpu.ui_slice_batches.length()
      }
      let instance_data = float32array_from_array(
        state.gpu.ui_slice_instance_data,
      )
      queue.write_buffer(instance_buffer, 0, instance_data)
      pass.set_pipeline(pipeline)
      pass.set_bind_group(1, globals_bind_group)
      for batch in state.gpu.ui_slice_batches {
        let entry = get_texture_entry(state, batch.texture_id)
        if entry is None {
          continue
        }
        if entry is Some(entry_value) {
          ensure_ui_slice_bind_group_for_texture(state, entry_value)
          let bind_group_any = entry_value._get("uiSliceBindGroup")
          if host_is_nullish(bind_group_any) {
            continue
          }
          pass.set_bind_group(0, bind_group_any.cast())
          pass.draw(
            state.gpu.vertex_count,
            batch.instance_count,
            0,
            batch.first_instance,
          )
        }
      }
      state.gpu.ui_slice_instance_data.clear()
      state.gpu.ui_slice_batches.clear()
      state.gpu.ui_slice_instance_count = 0
    }
  }
}

///|
fn draw_sprite(
  state : State,
  texture_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
) -> Unit {
  draw_sprite_uv(
    state, texture_id, x, y, rotation, scale_x, scale_y, r, g, b, a, 0.0, 0.0, 1.0,
    1.0,
  )
}

///|
fn draw_sprite_uv(
  state : State,
  texture_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
  uv_min_x : Double,
  uv_min_y : Double,
  uv_max_x : Double,
  uv_max_y : Double,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_sprite_uv_calls_accum = state.gpu.profile_draw_sprite_uv_calls_accum +
      1
  }
  if !ensure_pass_ready(state) {
    return
  }
  flush_ui_shadow_batches(state)
  flush_ui_slice_batches(state)
  flush_ui_batches(state)
  let entry = get_texture_entry(state, texture_id)
  if entry is None {
    return
  }
  if entry is Some(entry_value) {
    let tex_width : Double = entry_value._get("width").cast()
    let tex_height : Double = entry_value._get("height").cast()
    let raw_uv_scale_x = uv_max_x - uv_min_x
    let raw_uv_scale_y = uv_max_y - uv_min_y
    // Preserve negative uv_scale for sprite flipping; only treat zero-sized ranges as invalid.
    let uv_scale_x = if raw_uv_scale_x == 0 { 1.0 } else { raw_uv_scale_x }
    let uv_scale_y = if raw_uv_scale_y == 0 { 1.0 } else { raw_uv_scale_y }
    let uv_scale_abs_x = if uv_scale_x < 0 { -uv_scale_x } else { uv_scale_x }
    let uv_scale_abs_y = if uv_scale_y < 0 { -uv_scale_y } else { uv_scale_y }
    let region_width = tex_width * uv_scale_abs_x
    let region_height = tex_height * uv_scale_abs_y
    let base_size = 128.0
    let tex_scale_x = if region_width > 0 {
      region_width / base_size
    } else {
      1
    }
    let tex_scale_y = if region_height > 0 {
      region_height / base_size
    } else {
      1
    }
    let sprite_scale_x = scale_x * tex_scale_x
    let sprite_scale_y = scale_y * tex_scale_y
    let cos_value : Double = math_cos(rotation)
    let sin_value : Double = math_sin(rotation)
    let actual_texture_id : Int = entry_value._get("id").cast()
    let path_any = map_get(
      state.assets.texture_paths,
      @js.any(actual_texture_id),
    )
    let path_text = if host_is_nullish(path_any) {
      "<unknown>"
    } else {
      any_to_string(path_any)
    }
    report_debug_once(
      state,
      "sprite_draw_tex_" + actual_texture_id.to_string(),
      "draw_sprite_uv: requested_tex=" +
      texture_id.to_string() +
      " actual_tex=" +
      actual_texture_id.to_string() +
      " tex_size=" +
      to_int(number_or(entry_value._get("width"), 0)).to_string() +
      "x" +
      to_int(number_or(entry_value._get("height"), 0)).to_string() +
      " path=" +
      path_text +
      " pos=" +
      x.to_string() +
      "," +
      y.to_string() +
      " scale=" +
      scale_x.to_string() +
      "," +
      scale_y.to_string() +
      " color=" +
      r.to_string() +
      "," +
      g.to_string() +
      "," +
      b.to_string() +
      "," +
      a.to_string() +
      " uv=[" +
      uv_min_x.to_string() +
      "," +
      uv_min_y.to_string() +
      " -> " +
      uv_max_x.to_string() +
      "," +
      uv_max_y.to_string() +
      "]",
    )
    let first_instance = state.gpu.sprite_instance_count
    state.gpu.sprite_instance_count = first_instance + 1

    // Instance layout: model(x,y,cos,sin), scale(x,y,_,_), color, uv(min_x,min_y,scale_x,scale_y)
    state.gpu.sprite_instance_data.push(x)
    state.gpu.sprite_instance_data.push(y)
    state.gpu.sprite_instance_data.push(cos_value)
    state.gpu.sprite_instance_data.push(sin_value)
    state.gpu.sprite_instance_data.push(sprite_scale_x)
    state.gpu.sprite_instance_data.push(sprite_scale_y)
    state.gpu.sprite_instance_data.push(0.0)
    state.gpu.sprite_instance_data.push(0.0)
    state.gpu.sprite_instance_data.push(r)
    state.gpu.sprite_instance_data.push(g)
    state.gpu.sprite_instance_data.push(b)
    state.gpu.sprite_instance_data.push(a)
    state.gpu.sprite_instance_data.push(uv_min_x)
    state.gpu.sprite_instance_data.push(uv_min_y)
    state.gpu.sprite_instance_data.push(uv_scale_x)
    state.gpu.sprite_instance_data.push(uv_scale_y)
    let batch_count = state.gpu.sprite_batches.length()
    if batch_count > 0 &&
      state.gpu.sprite_batches[batch_count - 1].texture_id == actual_texture_id {
      state.gpu.sprite_batches[batch_count - 1].instance_count = state.gpu.sprite_batches[batch_count -
        1].instance_count +
        1
    } else {
      state.gpu.sprite_batches.push(SpriteBatch::{
        texture_id: actual_texture_id,
        first_instance,
        instance_count: 1,
      })
    }
  }
}

///|
fn draw_ui_rect(
  state : State,
  texture_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
  uv_min_x : Double,
  uv_min_y : Double,
  uv_max_x : Double,
  uv_max_y : Double,
  flags : Double,
  radius_tl : Double,
  radius_tr : Double,
  radius_br : Double,
  radius_bl : Double,
  border_left : Double,
  border_top : Double,
  border_right : Double,
  border_bottom : Double,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_ui_rect_calls_accum = state.gpu.profile_draw_ui_rect_calls_accum +
      1
  }
  if !ensure_pass_ready(state) {
    return
  }
  flush_sprite_batches(state)
  flush_ui_shadow_batches(state)
  flush_ui_slice_batches(state)
  ensure_ui_pipeline_resources(state)
  let entry = get_texture_entry(state, texture_id)
  if entry is None {
    return
  }
  if entry is Some(entry_value) {
    let raw_uv_scale_x = uv_max_x - uv_min_x
    let raw_uv_scale_y = uv_max_y - uv_min_y
    let uv_scale_x = if raw_uv_scale_x == 0 { 1.0 } else { raw_uv_scale_x }
    let uv_scale_y = if raw_uv_scale_y == 0 { 1.0 } else { raw_uv_scale_y }
    let base_size = 128.0
    let ui_scale_x = scale_x / base_size
    let ui_scale_y = scale_y / base_size
    let cos_value : Double = math_cos(rotation)
    let sin_value : Double = math_sin(rotation)
    let actual_texture_id : Int = entry_value._get("id").cast()
    let first_instance = state.gpu.ui_instance_count
    state.gpu.ui_instance_count = first_instance + 1

    // Instance layout:
    // model, scale, color, uv, flags(f32 + padding), radius, border
    state.gpu.ui_instance_data.push(x)
    state.gpu.ui_instance_data.push(y)
    state.gpu.ui_instance_data.push(cos_value)
    state.gpu.ui_instance_data.push(sin_value)
    state.gpu.ui_instance_data.push(ui_scale_x)
    state.gpu.ui_instance_data.push(ui_scale_y)
    state.gpu.ui_instance_data.push(0.0)
    state.gpu.ui_instance_data.push(0.0)
    state.gpu.ui_instance_data.push(r)
    state.gpu.ui_instance_data.push(g)
    state.gpu.ui_instance_data.push(b)
    state.gpu.ui_instance_data.push(a)
    state.gpu.ui_instance_data.push(uv_min_x)
    state.gpu.ui_instance_data.push(uv_min_y)
    state.gpu.ui_instance_data.push(uv_scale_x)
    state.gpu.ui_instance_data.push(uv_scale_y)
    state.gpu.ui_instance_data.push(flags)
    state.gpu.ui_instance_data.push(0.0)
    state.gpu.ui_instance_data.push(0.0)
    state.gpu.ui_instance_data.push(0.0)
    state.gpu.ui_instance_data.push(radius_tl)
    state.gpu.ui_instance_data.push(radius_tr)
    state.gpu.ui_instance_data.push(radius_br)
    state.gpu.ui_instance_data.push(radius_bl)
    state.gpu.ui_instance_data.push(border_left)
    state.gpu.ui_instance_data.push(border_top)
    state.gpu.ui_instance_data.push(border_right)
    state.gpu.ui_instance_data.push(border_bottom)
    let batch_count = state.gpu.ui_batches.length()
    if batch_count > 0 &&
      state.gpu.ui_batches[batch_count - 1].texture_id == actual_texture_id {
      state.gpu.ui_batches[batch_count - 1].instance_count = state.gpu.ui_batches[batch_count -
        1].instance_count +
        1
    } else {
      state.gpu.ui_batches.push(UiBatch::{
        texture_id: actual_texture_id,
        first_instance,
        instance_count: 1,
      })
    }
  }
}

///|
fn draw_ui_texture_slice(
  state : State,
  texture_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
  texture_slice_l : Double,
  texture_slice_t : Double,
  texture_slice_r : Double,
  texture_slice_b : Double,
  target_slice_l : Double,
  target_slice_t : Double,
  target_slice_r : Double,
  target_slice_b : Double,
  repeat_side_x : Double,
  repeat_side_y : Double,
  repeat_center_x : Double,
  repeat_center_y : Double,
  atlas_l : Double,
  atlas_t : Double,
  atlas_r : Double,
  atlas_b : Double,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_ui_texture_slice_calls_accum = state.gpu.profile_draw_ui_texture_slice_calls_accum +
      1
  }
  if !ensure_pass_ready(state) {
    return
  }
  flush_ui_shadow_batches(state)
  flush_sprite_batches(state)
  flush_ui_batches(state)
  ensure_ui_slice_pipeline_resources(state)
  let entry = get_texture_entry(state, texture_id)
  if entry is None {
    return
  }
  if entry is Some(entry_value) {
    let base_size = 128.0
    let ui_scale_x = scale_x / base_size
    let ui_scale_y = scale_y / base_size
    let cos_value : Double = math_cos(rotation)
    let sin_value : Double = math_sin(rotation)
    let actual_texture_id : Int = entry_value._get("id").cast()
    let first_instance = state.gpu.ui_slice_instance_count
    state.gpu.ui_slice_instance_count = first_instance + 1

    // Instance layout:
    // model, scale, color, texture_slices, target_slices, repeat, atlas_rect
    state.gpu.ui_slice_instance_data.push(x)
    state.gpu.ui_slice_instance_data.push(y)
    state.gpu.ui_slice_instance_data.push(cos_value)
    state.gpu.ui_slice_instance_data.push(sin_value)
    state.gpu.ui_slice_instance_data.push(ui_scale_x)
    state.gpu.ui_slice_instance_data.push(ui_scale_y)
    state.gpu.ui_slice_instance_data.push(0.0)
    state.gpu.ui_slice_instance_data.push(0.0)
    state.gpu.ui_slice_instance_data.push(r)
    state.gpu.ui_slice_instance_data.push(g)
    state.gpu.ui_slice_instance_data.push(b)
    state.gpu.ui_slice_instance_data.push(a)
    state.gpu.ui_slice_instance_data.push(texture_slice_l)
    state.gpu.ui_slice_instance_data.push(texture_slice_t)
    state.gpu.ui_slice_instance_data.push(texture_slice_r)
    state.gpu.ui_slice_instance_data.push(texture_slice_b)
    state.gpu.ui_slice_instance_data.push(target_slice_l)
    state.gpu.ui_slice_instance_data.push(target_slice_t)
    state.gpu.ui_slice_instance_data.push(target_slice_r)
    state.gpu.ui_slice_instance_data.push(target_slice_b)
    state.gpu.ui_slice_instance_data.push(repeat_side_x)
    state.gpu.ui_slice_instance_data.push(repeat_side_y)
    state.gpu.ui_slice_instance_data.push(repeat_center_x)
    state.gpu.ui_slice_instance_data.push(repeat_center_y)
    state.gpu.ui_slice_instance_data.push(atlas_l)
    state.gpu.ui_slice_instance_data.push(atlas_t)
    state.gpu.ui_slice_instance_data.push(atlas_r)
    state.gpu.ui_slice_instance_data.push(atlas_b)
    let batch_count = state.gpu.ui_slice_batches.length()
    if batch_count > 0 &&
      state.gpu.ui_slice_batches[batch_count - 1].texture_id ==
      actual_texture_id {
      state.gpu.ui_slice_batches[batch_count - 1].instance_count = state.gpu.ui_slice_batches[batch_count -
        1].instance_count +
        1
    } else {
      state.gpu.ui_slice_batches.push(UiBatch::{
        texture_id: actual_texture_id,
        first_instance,
        instance_count: 1,
      })
    }
  }
}

///|
fn draw_ui_box_shadow(
  state : State,
  texture_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
  size_x : Double,
  size_y : Double,
  radius_tl : Double,
  radius_tr : Double,
  radius_br : Double,
  radius_bl : Double,
  blur : Double,
  samples : Double,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_ui_box_shadow_calls_accum = state.gpu.profile_draw_ui_box_shadow_calls_accum +
      1
  }
  if !ensure_pass_ready(state) {
    return
  }
  flush_ui_slice_batches(state)
  flush_ui_batches(state)
  flush_sprite_batches(state)
  ensure_ui_shadow_pipeline_resources(state)
  let entry = get_texture_entry(state, texture_id)
  if entry is None {
    return
  }
  if entry is Some(entry_value) {
    let base_size = 128.0
    let shadow_scale_x = scale_x / base_size
    let shadow_scale_y = scale_y / base_size
    let cos_value : Double = math_cos(rotation)
    let sin_value : Double = math_sin(rotation)
    let actual_texture_id : Int = entry_value._get("id").cast()
    let first_instance = state.gpu.ui_shadow_instance_count
    state.gpu.ui_shadow_instance_count = first_instance + 1

    // Instance layout:
    // model, scale(bounds/128), color, size(x,y,blur,samples), radius(tl,tr,br,bl)
    state.gpu.ui_shadow_instance_data.push(x)
    state.gpu.ui_shadow_instance_data.push(y)
    state.gpu.ui_shadow_instance_data.push(cos_value)
    state.gpu.ui_shadow_instance_data.push(sin_value)
    state.gpu.ui_shadow_instance_data.push(shadow_scale_x)
    state.gpu.ui_shadow_instance_data.push(shadow_scale_y)
    state.gpu.ui_shadow_instance_data.push(0.0)
    state.gpu.ui_shadow_instance_data.push(0.0)
    state.gpu.ui_shadow_instance_data.push(r)
    state.gpu.ui_shadow_instance_data.push(g)
    state.gpu.ui_shadow_instance_data.push(b)
    state.gpu.ui_shadow_instance_data.push(a)
    state.gpu.ui_shadow_instance_data.push(size_x)
    state.gpu.ui_shadow_instance_data.push(size_y)
    state.gpu.ui_shadow_instance_data.push(blur)
    state.gpu.ui_shadow_instance_data.push(samples)
    state.gpu.ui_shadow_instance_data.push(radius_tl)
    state.gpu.ui_shadow_instance_data.push(radius_tr)
    state.gpu.ui_shadow_instance_data.push(radius_br)
    state.gpu.ui_shadow_instance_data.push(radius_bl)
    let batch_count = state.gpu.ui_shadow_batches.length()
    if batch_count > 0 &&
      state.gpu.ui_shadow_batches[batch_count - 1].texture_id ==
      actual_texture_id {
      state.gpu.ui_shadow_batches[batch_count - 1].instance_count = state.gpu.ui_shadow_batches[batch_count -
        1].instance_count +
        1
    } else {
      state.gpu.ui_shadow_batches.push(UiBatch::{
        texture_id: actual_texture_id,
        first_instance,
        instance_count: 1,
      })
    }
  }
}

///|
fn draw_mesh(
  state : State,
  mesh_id : Int,
  x : Double,
  y : Double,
  rotation : Double,
  scale_x : Double,
  scale_y : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
  texture_id : Int,
  uv_offset_x : Double,
  uv_offset_y : Double,
  uv_scale_x : Double,
  uv_scale_y : Double,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_mesh_calls_accum = state.gpu.profile_draw_mesh_calls_accum +
      1
  }
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  flush_ui_shadow_batches(state)
  flush_ui_slice_batches(state)
  flush_ui_batches(state)
  flush_sprite_batches(state)
  ensure_mesh_pipeline(state)
  if state.gpu.mesh_pipeline is None {
    report_asset_error_once(
      state, "mesh_draw_pipeline_not_ready", "Mesh draw skipped: mesh pipeline not ready",
    )
    return
  }
  let mesh_entry = map_get(state.gpu.meshes, @js.any(mesh_id))
  if host_is_nullish(mesh_entry) {
    report_asset_error_once(
      state,
      "mesh_draw_missing_mesh_" + mesh_id.to_string(),
      "Mesh draw skipped: mesh id not found (" + mesh_id.to_string() + ")",
    )
    return
  }
  let vertex_layout_kind : Int = mesh_entry._get("vertexLayoutKind").cast()
  if vertex_layout_kind != 1 {
    report_asset_error_once(
      state,
      "mesh_draw_layout_mismatch_" + mesh_id.to_string(),
      "Mesh draw skipped: vertex layout is not 2D-compatible (" +
      mesh_id.to_string() +
      ")",
    )
    return
  }
  let textured = texture_id >= 0
  let mesh_texture_id = if textured {
    texture_id
  } else {
    state.gpu.default_texture_id
  }
  let texture_entry = get_texture_entry(state, mesh_texture_id)
  if texture_entry is None {
    return
  }
  if state.gpu.current_pass is Some(pass) &&
    state.gpu.current_pass_info is Some(info) &&
    state.gpu.mesh_pipeline is Some(mesh_pipeline) &&
    texture_entry is Some(texture_entry_value) {
    let safe_scale = if info.cam_scale == 0 { 1.0 } else { info.cam_scale }
    let scale_x_base = if info.width > 0 {
      2.0 / info.width / safe_scale
    } else {
      0.0
    }
    let scale_y_base = if info.height > 0 {
      2.0 / info.height / safe_scale
    } else {
      0.0
    }
    let cos_value : Double = math_cos(rotation)
    let sin_value : Double = math_sin(rotation)
    let cam_cos : Double = math_cos(-info.cam_rotation)
    let cam_sin : Double = math_sin(-info.cam_rotation)
    let uv0_x = if textured { uv_offset_x } else { 0.0 }
    let uv0_y = if textured { uv_offset_y } else { 0.0 }
    let uvs_x = if textured { uv_scale_x } else { -1.0 }
    let uvs_y = if textured { uv_scale_y } else { -1.0 }
    let uniform_values = [
      x,
      y,
      cos_value,
      sin_value,
      info.cam_x,
      info.cam_y,
      cam_cos,
      cam_sin,
      scale_x_base,
      scale_y_base,
      scale_x,
      scale_y,
      r,
      g,
      b,
      a,
      uv0_x,
      uv0_y,
      uvs_x,
      uvs_y,
    ]
    guard create_transient_uniform_bind_group(
        state, mesh_pipeline, uniform_values,
      )
      is Some(mesh_bind_group) else {
      return
    }
    ensure_mesh_bind_group_for_texture(state, texture_entry_value)
    let texture_bind_group_any = texture_entry_value._get("meshBindGroup")
    if host_is_nullish(texture_bind_group_any) {
      return
    }
    let texture_bind_group : @webgpu.GPUBindGroup = texture_bind_group_any.cast()
    pass.set_pipeline(mesh_pipeline)
    pass.set_bind_group(0, mesh_bind_group)
    pass.set_bind_group(1, texture_bind_group)
    let vertex_buffer : @webgpu.GPUBuffer = mesh_entry
      ._get("vertexBuffer")
      .cast()
    let vertex_count : Int = mesh_entry._get("vertexCount").cast()
    if vertex_count <= 0 {
      report_asset_error_once(
        state,
        "mesh_draw_empty_vertices_" + mesh_id.to_string(),
        "Mesh draw skipped: empty vertex buffer (" + mesh_id.to_string() + ")",
      )
      return
    }
    pass.set_vertex_buffer(0, vertex_buffer)
    pass.draw(vertex_count, 1, 0, 0)
  }
}

///|
fn draw_mesh3d(
  state : State,
  mesh_id : Int,
  x : Double,
  y : Double,
  z : Double,
  rotation_x : Double,
  rotation_y : Double,
  rotation_z : Double,
  rotation_w : Double,
  scale_x : Double,
  scale_y : Double,
  scale_z : Double,
  previous_x : Double,
  previous_y : Double,
  previous_z : Double,
  previous_rotation_x : Double,
  previous_rotation_y : Double,
  previous_rotation_z : Double,
  previous_rotation_w : Double,
  previous_scale_x : Double,
  previous_scale_y : Double,
  previous_scale_z : Double,
  r : Double,
  g : Double,
  b : Double,
  a : Double,
  texture_id : Int,
  uv_offset_x : Double,
  uv_offset_y : Double,
  uv_scale_x : Double,
  uv_scale_y : Double,
  normal_texture_id : Int,
  emissive_texture_id : Int,
  metallic_roughness_texture_id : Int,
  occlusion_texture_id : Int,
  depth_texture_id : Int,
  emissive_r : Double,
  emissive_g : Double,
  emissive_b : Double,
  unlit : Double,
  metallic : Double,
  roughness : Double,
  reflectance : Double,
  parallax_depth_scale : Double,
  max_parallax_layer_count : Double,
  max_relief_mapping_search_steps : Double,
  anisotropy_texture_id : Int,
  anisotropy_strength : Double,
  anisotropy_rotation : Double,
  specular_tint_texture_id : Int,
  specular_tint_r : Double,
  specular_tint_g : Double,
  specular_tint_b : Double,
  diffuse_transmission : Double,
  specular_transmission : Double,
  thickness : Double,
  ior : Double,
  transmission_source_texture_id : Int,
  transmission_blur_taps : Double,
  transmission_steps : Double,
  cull_mode : Int,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_mesh3d_calls_accum = state.gpu.profile_draw_mesh3d_calls_accum +
      1
  }
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  flush_ui_shadow_batches(state)
  flush_ui_slice_batches(state)
  flush_ui_batches(state)
  flush_sprite_batches(state)
  let pass_kind_raw = if state.gpu.current_pass_info is Some(info) {
    to_int(info.pass_kind)
  } else {
    0
  }
  let pass_kind_value = pass_kind_base_kind(pass_kind_raw)
  let pass_postprocess_enabled = pass_kind_postprocess_enabled(pass_kind_raw)
  let pass_fog_enabled = pass_kind_fog_enabled(pass_kind_raw)
  let pass_decal_enabled = pass_kind_decal_enabled(pass_kind_raw)
  let use_motion_vector_pipeline = pass_kind_value == 1
  if use_motion_vector_pipeline && !pass_postprocess_enabled {
    return
  }
  if !pass_decal_enabled && mesh3d_draw_is_decal(cull_mode) {
    return
  }
  if !pass_fog_enabled && mesh3d_draw_is_fog(cull_mode) {
    return
  }
  if !pass_postprocess_enabled && mesh3d_draw_is_postprocess_proxy(cull_mode) {
    return
  }
  let mesh_entry = map_get(state.gpu.meshes, @js.any(mesh_id))
  if host_is_nullish(mesh_entry) {
    report_asset_error_once(
      state,
      "mesh3d_draw_missing_mesh_" + mesh_id.to_string(),
      "Mesh3d draw skipped: mesh id not found (" + mesh_id.to_string() + ")",
    )
    return
  }
  let vertex_layout_kind : Int = mesh_entry._get("vertexLayoutKind").cast()
  if vertex_layout_kind != 2 {
    report_asset_error_once(
      state,
      "mesh3d_draw_layout_mismatch_" + mesh_id.to_string(),
      "Mesh3d draw skipped: vertex layout is not 3D-compatible (" +
      mesh_id.to_string() +
      ")",
    )
    return
  }
  let primitive_topology_kind = mesh3d_topology_kind_from_entry(mesh_entry)
  let resolved_cull_mode = mesh3d_cull_mode_sanitize(cull_mode)
  let use_transparent_pipeline = a < 0.999
  if use_motion_vector_pipeline {
    ensure_motion_vector_pipeline(state)
  } else {
    ensure_mesh3d_pipeline(state, primitive_topology_kind, resolved_cull_mode)
  }
  let mesh3d_pipeline_opt = if use_motion_vector_pipeline {
    None
  } else {
    mesh3d_pipeline_get(
      state, primitive_topology_kind, use_transparent_pipeline, resolved_cull_mode,
    )
  }
  if !use_motion_vector_pipeline && mesh3d_pipeline_opt is None {
    report_asset_error_once(
      state, "mesh3d_draw_pipeline_not_ready", "Mesh3d draw skipped: mesh3d pipeline not ready",
    )
    return
  }
  if use_motion_vector_pipeline {
    if primitive_topology_kind != 0 {
      return
    }
    if a < 0.999 {
      return
    }
    if state.gpu.motion_vector_pipeline is None {
      report_asset_error_once(
        state, "motion_vector_draw_pipeline_not_ready", "Motion-vector draw skipped: pipeline not ready",
      )
      return
    }
    if state.gpu.current_pass is Some(pass) &&
      state.gpu.current_pass_info is Some(info) &&
      state.gpu.motion_vector_pipeline is Some(motion_vector_pipeline) {
      let aspect = if info.height > 0 { info.width / info.height } else { 1.0 }
      let uniform_values = [
        x,
        y,
        z,
        1.0,
        rotation_x,
        rotation_y,
        rotation_z,
        rotation_w,
        scale_x,
        scale_y,
        scale_z,
        1.0,
        previous_x,
        previous_y,
        previous_z,
        1.0,
        previous_rotation_x,
        previous_rotation_y,
        previous_rotation_z,
        previous_rotation_w,
        previous_scale_x,
        previous_scale_y,
        previous_scale_z,
        1.0,
        info.cam_x,
        info.cam_y,
        info.cam_z,
        1.0,
        info.cam_rot_x,
        info.cam_rot_y,
        info.cam_rot_z,
        info.cam_rot_w,
        info.previous_camera_x,
        info.previous_camera_y,
        info.previous_camera_z,
        1.0,
        info.previous_camera_rot_x,
        info.previous_camera_rot_y,
        info.previous_camera_rot_z,
        info.previous_camera_rot_w,
        info.cam_fov_y,
        aspect,
        info.cam_near,
        info.cam_far,
        info.sub_camera_view_scale_x,
        info.sub_camera_view_scale_y,
        info.sub_camera_view_bias_x,
        info.sub_camera_view_bias_y,
      ]
      guard create_transient_uniform_bind_group(
          state, motion_vector_pipeline, uniform_values,
        )
        is Some(motion_vector_bind_group) else {
        return
      }
      let vertex_buffer : @webgpu.GPUBuffer = mesh_entry
        ._get("vertexBuffer")
        .cast()
      let vertex_count : Int = mesh_entry._get("vertexCount").cast()
      if vertex_count <= 0 {
        report_asset_error_once(
          state,
          "motion_vector_draw_empty_vertices_" + mesh_id.to_string(),
          "Motion-vector draw skipped: empty vertex buffer (" +
          mesh_id.to_string() +
          ")",
        )
        return
      }
      pass.set_pipeline(motion_vector_pipeline)
      pass.set_bind_group(0, motion_vector_bind_group)
      pass.set_vertex_buffer(0, vertex_buffer)
      pass.draw(vertex_count, 1, 0, 0)
    }
    return
  }
  let textured = texture_id >= 0
  let base_texture_id = if textured {
    texture_id
  } else {
    state.gpu.default_texture_id
  }
  let emissive_textured = emissive_texture_id >= 0
  let normal_textured = normal_texture_id >= 0
  let resolved_normal_texture_id = if normal_textured {
    normal_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let resolved_emissive_texture_id = if emissive_textured {
    emissive_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let metallic_roughness_textured = metallic_roughness_texture_id >= 0
  let resolved_metallic_roughness_texture_id = if metallic_roughness_textured {
    metallic_roughness_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let occlusion_textured = occlusion_texture_id >= 0
  let resolved_occlusion_texture_id = if occlusion_textured {
    occlusion_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let depth_textured = depth_texture_id >= 0
  let resolved_depth_texture_id = if depth_textured {
    depth_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let anisotropy_textured = anisotropy_texture_id >= 0
  let resolved_anisotropy_texture_id = if anisotropy_textured {
    anisotropy_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let specular_tint_textured = specular_tint_texture_id >= 0
  let resolved_specular_tint_texture_id = if specular_tint_textured {
    specular_tint_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let base_texture_entry = get_texture_entry_strict(state, base_texture_id)
  let normal_texture_entry = get_texture_entry_strict(
    state, resolved_normal_texture_id,
  )
  let emissive_texture_entry = get_texture_entry_strict(
    state, resolved_emissive_texture_id,
  )
  let metallic_roughness_texture_entry = get_texture_entry_strict(
    state, resolved_metallic_roughness_texture_id,
  )
  let occlusion_texture_entry = get_texture_entry_strict(
    state, resolved_occlusion_texture_id,
  )
  let depth_texture_entry = get_texture_entry_strict(
    state, resolved_depth_texture_id,
  )
  let anisotropy_texture_entry = get_texture_entry_strict(
    state, resolved_anisotropy_texture_id,
  )
  let specular_tint_texture_entry = get_texture_entry_strict(
    state, resolved_specular_tint_texture_id,
  )
  let resolved_transmission_source_texture_id = if transmission_source_texture_id >=
    0 {
    transmission_source_texture_id
  } else {
    state.gpu.default_texture_id
  }
  let transmission_source_texture_entry = get_texture_entry_strict(
    state, resolved_transmission_source_texture_id,
  )
  if base_texture_entry is None ||
    normal_texture_entry is None ||
    emissive_texture_entry is None ||
    metallic_roughness_texture_entry is None ||
    occlusion_texture_entry is None ||
    depth_texture_entry is None ||
    anisotropy_texture_entry is None ||
    specular_tint_texture_entry is None ||
    transmission_source_texture_entry is None {
    return
  }
  if state.gpu.current_pass is Some(pass) &&
    state.gpu.current_pass_info is Some(info) &&
    mesh3d_pipeline_opt is Some(mesh3d_pipeline) &&
    base_texture_entry is Some(base_texture_entry_value) &&
    normal_texture_entry is Some(normal_texture_entry_value) &&
    emissive_texture_entry is Some(emissive_texture_entry_value) &&
    metallic_roughness_texture_entry
    is Some(metallic_roughness_texture_entry_value) &&
    occlusion_texture_entry is Some(occlusion_texture_entry_value) &&
    depth_texture_entry is Some(depth_texture_entry_value) &&
    anisotropy_texture_entry is Some(anisotropy_texture_entry_value) &&
    specular_tint_texture_entry is Some(specular_tint_texture_entry_value) &&
    transmission_source_texture_entry
    is Some(transmission_source_texture_entry_value) {
    let aspect = if info.height > 0 { info.width / info.height } else { 1.0 }
    let uv0_x = if textured { uv_offset_x } else { 0.0 }
    let uv0_y = if textured { uv_offset_y } else { 0.0 }
    let uvs_x = if textured { uv_scale_x } else { -1.0 }
    let uvs_y = if textured { uv_scale_y } else { -1.0 }
    let uniform_values = [
      x,
      y,
      z,
      1.0,
      rotation_x,
      rotation_y,
      rotation_z,
      rotation_w,
      scale_x,
      scale_y,
      scale_z,
      1.0,
      info.cam_x,
      info.cam_y,
      info.cam_z,
      1.0,
      info.cam_rot_x,
      info.cam_rot_y,
      info.cam_rot_z,
      info.cam_rot_w,
      info.cam_fov_y,
      aspect,
      info.cam_near,
      info.cam_far,
      info.sub_camera_view_scale_x,
      info.sub_camera_view_scale_y,
      info.sub_camera_view_bias_x,
      info.sub_camera_view_bias_y,
      r,
      g,
      b,
      a,
      uv0_x,
      uv0_y,
      uvs_x,
      uvs_y,
      info.ambient_r,
      info.ambient_g,
      info.ambient_b,
      info.ambient_brightness,
      info.directional_dir_x,
      info.directional_dir_y,
      info.directional_dir_z,
      info.directional_illuminance,
      info.directional_color_r,
      info.directional_color_g,
      info.directional_color_b,
      1.0,
      info.point_pos_x,
      info.point_pos_y,
      info.point_pos_z,
      info.point_range,
      info.point_color_r,
      info.point_color_g,
      info.point_color_b,
      info.point_intensity,
      info.spot_pos_x,
      info.spot_pos_y,
      info.spot_pos_z,
      info.spot_range,
      info.spot_dir_x,
      info.spot_dir_y,
      info.spot_dir_z,
      info.spot_inner_angle,
      info.spot_color_r,
      info.spot_color_g,
      info.spot_color_b,
      info.spot_intensity,
      info.spot_outer_angle,
      transmission_blur_taps,
      transmission_steps,
      0.0,
      emissive_r,
      emissive_g,
      emissive_b,
      unlit,
      metallic,
      roughness,
      reflectance,
      if normal_textured {
        1.0
      } else {
        0.0
      },
      if textured {
        1.0
      } else {
        0.0
      },
      if emissive_textured {
        1.0
      } else {
        0.0
      },
      if metallic_roughness_textured {
        1.0
      } else {
        0.0
      },
      if occlusion_textured {
        1.0
      } else {
        0.0
      },
      parallax_depth_scale,
      max_parallax_layer_count,
      max_relief_mapping_search_steps,
      if depth_textured {
        1.0
      } else {
        0.0
      },
      anisotropy_strength,
      @coremath.cos(anisotropy_rotation),
      @coremath.sin(anisotropy_rotation),
      if anisotropy_textured {
        1.0
      } else {
        0.0
      },
      specular_tint_r,
      specular_tint_g,
      specular_tint_b,
      if specular_tint_textured {
        1.0
      } else {
        0.0
      },
      diffuse_transmission,
      specular_transmission,
      thickness,
      ior,
    ]
    guard create_transient_uniform_bind_group(
        state, mesh3d_pipeline, uniform_values,
      )
      is Some(mesh3d_bind_group) else {
      return
    }
    if state.gpu.device is Some(device) {
      let base_sampler : @webgpu.GPUSampler = base_texture_entry_value
        ._get("sampler")
        .cast()
      let base_view : @webgpu.GPUTextureView = base_texture_entry_value
        ._get("view")
        .cast()
      let normal_view : @webgpu.GPUTextureView = normal_texture_entry_value
        ._get("view")
        .cast()
      let emissive_view : @webgpu.GPUTextureView = emissive_texture_entry_value
        ._get("view")
        .cast()
      let metallic_roughness_view : @webgpu.GPUTextureView = metallic_roughness_texture_entry_value
        ._get("view")
        .cast()
      let occlusion_view : @webgpu.GPUTextureView = occlusion_texture_entry_value
        ._get("view")
        .cast()
      let depth_view : @webgpu.GPUTextureView = depth_texture_entry_value
        ._get("view")
        .cast()
      let anisotropy_view : @webgpu.GPUTextureView = anisotropy_texture_entry_value
        ._get("view")
        .cast()
      let specular_tint_view : @webgpu.GPUTextureView = specular_tint_texture_entry_value
        ._get("view")
        .cast()
      let transmission_source_view : @webgpu.GPUTextureView = transmission_source_texture_entry_value
        ._get("view")
        .cast()
      guard state.gpu.mesh3d_material_layout is Some(material_layout) else {
        return
      }
      let material_entries = [
        @webgpu.bind_group_entry_sampler(0, base_sampler),
        @webgpu.bind_group_entry_texture(1, base_view),
        @webgpu.bind_group_entry_texture(2, normal_view),
        @webgpu.bind_group_entry_texture(3, emissive_view),
        @webgpu.bind_group_entry_texture(4, metallic_roughness_view),
        @webgpu.bind_group_entry_texture(5, occlusion_view),
        @webgpu.bind_group_entry_texture(6, depth_view),
        @webgpu.bind_group_entry_texture(7, anisotropy_view),
        @webgpu.bind_group_entry_texture(8, specular_tint_view),
        @webgpu.bind_group_entry_texture(9, transmission_source_view),
      ]
      let material_desc = @webgpu.bind_group_descriptor(
        material_layout, material_entries,
      )
      let material_bg = device.create_bind_group(material_desc.to_js())
      pass.set_pipeline(mesh3d_pipeline)
      pass.set_bind_group(0, mesh3d_bind_group)
      pass.set_bind_group(1, material_bg)
      let vertex_buffer : @webgpu.GPUBuffer = mesh_entry
        ._get("vertexBuffer")
        .cast()
      let vertex_count : Int = mesh_entry._get("vertexCount").cast()
      if vertex_count <= 0 {
        report_asset_error_once(
          state,
          "mesh3d_draw_empty_vertices_" + mesh_id.to_string(),
          "Mesh3d draw skipped: empty vertex buffer (" +
          mesh_id.to_string() +
          ")",
        )
        return
      }
      pass.set_vertex_buffer(0, vertex_buffer)
      pass.draw(vertex_count, 1, 0, 0)
    }
  }
}

///|
fn blit_scene_texture_to_current_pass(
  state : State,
  scene_texture_id : Int,
) -> Unit {
  guard state.gpu.current_pass_info is Some(info) else { return }
  let viewport_width = if info.viewport_width > 0.0 {
    info.viewport_width
  } else if info.width > 0.0 {
    info.width
  } else {
    1.0
  }
  let viewport_height = if info.viewport_height > 0.0 {
    info.viewport_height
  } else if info.height > 0.0 {
    info.height
  } else {
    1.0
  }
  draw_sprite_uv(
    state,
    scene_texture_id,
    0.0,
    0.0,
    0.0,
    viewport_width / 128.0,
    viewport_height / 128.0,
    1.0,
    1.0,
    1.0,
    1.0,
    0.0,
    0.0,
    1.0,
    1.0,
  )
  flush_sprite_batches(state)
}

///|
fn draw_motion_blur(
  state : State,
  scene_texture_id : Int,
  velocity_texture_id : Int,
  shutter_angle : Double,
  samples : Int,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_motion_blur_calls_accum = state.gpu.profile_draw_motion_blur_calls_accum +
      1
  }
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  flush_ui_shadow_batches(state)
  flush_ui_slice_batches(state)
  flush_ui_batches(state)
  flush_sprite_batches(state)
  let pass_kind_raw = if state.gpu.current_pass_info is Some(info) {
    to_int(info.pass_kind)
  } else {
    0
  }
  if scene_texture_id < 0 {
    report_asset_error_once(
      state, "motion_blur_draw_invalid_scene_texture", "Motion-blur draw skipped: scene texture id is invalid",
    )
    return
  }
  guard get_texture_entry_strict(state, scene_texture_id)
    is Some(scene_texture_entry) else {
    report_asset_error_once(
      state, "motion_blur_draw_scene_texture_not_ready", "Motion-blur draw skipped: scene texture is not ready",
    )
    return
  }
  let motion_blur_enabled = pass_kind_postprocess_enabled(pass_kind_raw) &&
    samples > 0 &&
    shutter_angle > 0.0
  if !motion_blur_enabled {
    blit_scene_texture_to_current_pass(state, scene_texture_id)
    return
  }
  if velocity_texture_id < 0 {
    report_asset_error_once(
      state, "motion_blur_draw_invalid_velocity_texture", "Motion-blur draw skipped: velocity texture id is invalid",
    )
    return
  }
  guard get_texture_entry_strict(state, velocity_texture_id)
    is Some(velocity_texture_entry) else {
    report_asset_error_once(
      state, "motion_blur_draw_velocity_texture_not_ready", "Motion-blur draw skipped: velocity texture is not ready",
    )
    return
  }
  ensure_motion_blur_pipeline(state)
  if state.gpu.motion_blur_pipeline is None {
    report_asset_error_once(
      state, "motion_blur_draw_pipeline_not_ready", "Motion-blur draw skipped: pipeline not ready",
    )
    return
  }
  let clamped_samples = if samples < 0 {
    0
  } else if samples > 64 {
    64
  } else {
    samples
  }
  guard state.gpu.current_pass is Some(pass) else { return }
  guard state.gpu.motion_blur_pipeline is Some(motion_blur_pipeline) else {
    return
  }
  guard state.gpu.motion_blur_bind_layout is Some(bind_layout) else { return }
  guard state.gpu.motion_blur_settings_buffer is Some(settings_buffer) else {
    return
  }
  guard state.gpu.motion_blur_globals_buffer is Some(globals_buffer) else {
    return
  }
  guard state.gpu.device is Some(device) else { return }
  guard state.gpu.queue is Some(queue) else { return }
  let settings_data = motion_blur_settings_uniform_bytes(
    shutter_angle, clamped_samples,
  )
  let globals_data = motion_blur_globals_uniform_bytes(state.gpu.frame_count)
  queue.write_buffer(settings_buffer, 0, settings_data)
  queue.write_buffer(globals_buffer, 0, globals_data)
  guard state.gpu.depth_view is Some(depth_view) else {
    report_asset_error_once(
      state, "motion_blur_draw_depth_not_ready", "Motion-blur draw skipped: depth texture is not ready",
    )
    return
  }
  let scene_sampler : @webgpu.GPUSampler = scene_texture_entry
    ._get("sampler")
    .cast()
  let scene_view : @webgpu.GPUTextureView = scene_texture_entry
    ._get("view")
    .cast()
  let velocity_view : @webgpu.GPUTextureView = velocity_texture_entry
    ._get("view")
    .cast()
  let material_entries = [
    @webgpu.bind_group_entry_texture(0, scene_view),
    @webgpu.bind_group_entry_texture(1, velocity_view),
    @webgpu.bind_group_entry_texture(2, depth_view),
    @webgpu.bind_group_entry_sampler(3, scene_sampler),
    @webgpu.bind_group_entry_buffer(4, settings_buffer),
    @webgpu.bind_group_entry_buffer(5, globals_buffer),
  ]
  let material_desc = @webgpu.bind_group_descriptor(
    bind_layout, material_entries,
  )
  let material_bind_group = device.create_bind_group(material_desc.to_js())
  if state.gpu.current_pass_info is Some(info) {
    pass.set_scissor_rect(
      to_int(info.viewport_x),
      to_int(info.viewport_y),
      to_int(info.viewport_width),
      to_int(info.viewport_height),
    )
  }
  pass.set_pipeline(motion_blur_pipeline)
  pass.set_bind_group(0, material_bind_group)
  pass.draw(3, 1, 0, 0)
}

///|
fn draw_bloom2d(
  state : State,
  scene_texture_id : Int,
  enabled : Int,
  intensity : Double,
  low_frequency_boost : Double,
  low_frequency_boost_curvature : Double,
  high_pass_frequency : Double,
  threshold : Double,
  threshold_softness : Double,
  composite_mode : Int,
  max_mip_dimension : Int,
  scale_x : Double,
  scale_y : Double,
  tonemapping_mode : Int,
  deband_dither_enabled : Int,
  view_width : Int,
  view_height : Int,
  agx_lut_texture_id : Int,
  tony_lut_texture_id : Int,
  blender_lut_texture_id : Int,
) -> Unit {
  if state.gpu.profile_enabled {
    state.gpu.profile_draw_bloom2d_calls_accum = state.gpu.profile_draw_bloom2d_calls_accum +
      1
  }
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  let bloom_enabled = enabled != 0
  flush_ui_shadow_batches(state)
  flush_ui_slice_batches(state)
  flush_ui_batches(state)
  flush_sprite_batches(state)
  if scene_texture_id < 0 {
    report_asset_error_once(
      state, "bloom2d_draw_invalid_scene_texture", "Bloom2d draw skipped: scene texture id is invalid",
    )
    return
  }
  guard get_texture_entry_strict(state, scene_texture_id)
    is Some(scene_texture_entry) else {
    report_asset_error_once(
      state, "bloom2d_draw_scene_texture_not_ready", "Bloom2d draw skipped: scene texture is not ready",
    )
    return
  }
  guard state.gpu.current_pass_info is Some(info) else { return }
  let pass_kind_raw = to_int(info.pass_kind)
  if !pass_kind_postprocess_enabled(pass_kind_raw) {
    blit_scene_texture_to_current_pass(state, scene_texture_id)
    return
  }
  guard state.gpu.current_pass is Some(active_pass) else { return }
  guard state.gpu.encoder is Some(encoder) else { return }
  guard state.gpu.device is Some(device) else { return }
  guard state.gpu.queue is Some(queue) else { return }
  let mut target_format = state.gpu.format.unwrap_or(
    @webgpu.TextureFormat::Bgra8Unorm,
  )
  let mut target_width = if info.width > 0.0 { to_int(info.width) } else { 1 }
  let mut target_height = if info.height > 0.0 {
    to_int(info.height)
  } else {
    1
  }
  let target_view = if info.target_id < 0 {
    guard state.gpu.current_texture is Some(current_texture) else { return }
    match current_surface_view_descriptor(state) {
      Some(descriptor) => current_texture.create_view(descriptor~)
      None => current_texture.create_view()
    }
  } else {
    let target_entry = map_get(state.gpu.textures, @js.any(info.target_id))
    if host_is_nullish(target_entry) {
      report_asset_error_once(
        state, "bloom2d_draw_target_texture_not_ready", "Bloom2d draw skipped: target texture is not ready",
      )
      return
    }
    let target_width_any = target_entry._get("width")
    let target_height_any = target_entry._get("height")
    target_width = if host_is_nullish(target_width_any) {
      target_width
    } else {
      to_int(number_or(target_width_any, target_width.to_double()))
    }
    target_height = if host_is_nullish(target_height_any) {
      target_height
    } else {
      to_int(number_or(target_height_any, target_height.to_double()))
    }
    let target_format_any = target_entry._get("format")
    if !host_is_nullish(target_format_any) {
      target_format = @webgpu.texture_format_from_string(
        any_to_string(target_format_any),
      )
    }
    let target_view_any = target_entry._get("view")
    if host_is_nullish(target_view_any) {
      report_asset_error_once(
        state, "bloom2d_draw_target_view_not_ready", "Bloom2d draw skipped: target texture view is not ready",
      )
      return
    }
    target_view_any.cast()
  }
  let scale_x_value = scale_x
  let scale_y_value = scale_y
  let use_uniform_scale = scale_x_value == 1.0 && scale_y_value == 1.0
  let use_prefilter = threshold > 0.0
  ensure_bloom2d_pipeline(state, target_format)
  let downsample_first_pipeline = if use_uniform_scale {
    if use_prefilter {
      guard state.gpu.bloom2d_downsample_first_uniform_pipeline
        is Some(pipeline) else {
        report_asset_error_once(
          state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: downsample-first-uniform pipeline not ready",
        )
        return
      }
      pipeline
    } else {
      guard state.gpu.bloom2d_downsample_first_no_threshold_uniform_pipeline
        is Some(pipeline) else {
        report_asset_error_once(
          state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: downsample-first-no-threshold-uniform pipeline not ready",
        )
        return
      }
      pipeline
    }
  } else if use_prefilter {
    guard state.gpu.bloom2d_downsample_first_pipeline is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: downsample-first pipeline not ready",
      )
      return
    }
    pipeline
  } else {
    guard state.gpu.bloom2d_downsample_first_no_threshold_pipeline
      is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: downsample-first-no-threshold pipeline not ready",
      )
      return
    }
    pipeline
  }
  let downsample_pipeline = if use_uniform_scale {
    guard state.gpu.bloom2d_downsample_uniform_pipeline is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: downsample-uniform pipeline not ready",
      )
      return
    }
    pipeline
  } else {
    guard state.gpu.bloom2d_downsample_pipeline is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: downsample pipeline not ready",
      )
      return
    }
    pipeline
  }
  let upsample_pipeline = if composite_mode == 0 {
    guard state.gpu.bloom2d_upsample_pipeline_energy is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: upsample pipeline not ready",
      )
      return
    }
    pipeline
  } else {
    guard state.gpu.bloom2d_upsample_pipeline_additive is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: upsample pipeline not ready",
      )
      return
    }
    pipeline
  }
  let final_pipeline = if composite_mode == 0 {
    guard state.gpu.bloom2d_final_pipeline_energy is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: final pipeline not ready",
      )
      return
    }
    pipeline
  } else {
    guard state.gpu.bloom2d_final_pipeline_additive is Some(pipeline) else {
      report_asset_error_once(
        state, "bloom2d_draw_pipeline_not_ready", "Bloom2d draw skipped: final pipeline not ready",
      )
      return
    }
    pipeline
  }
  guard state.gpu.bloom2d_bind_layout is Some(bind_layout) else { return }
  guard state.gpu.bloom2d_settings_buffer is Some(settings_buffer) else {
    return
  }
  guard state.gpu.bloom2d_sampler is Some(bloom_sampler) else { return }
  let viewport_width = if info.viewport_width > 0.0 {
    to_int(info.viewport_width)
  } else if view_width > 0 {
    view_width
  } else {
    target_width
  }
  let viewport_height = if info.viewport_height > 0.0 {
    to_int(info.viewport_height)
  } else if view_height > 0 {
    view_height
  } else {
    target_height
  }
  let safe_viewport_width = if viewport_width > 0 { viewport_width } else { 1 }
  let safe_viewport_height = if viewport_height > 0 {
    viewport_height
  } else {
    1
  }
  let scene_width = to_int(number_or(scene_texture_entry._get("width"), 0.0))
  let scene_height = to_int(number_or(scene_texture_entry._get("height"), 0.0))
  let scene_format_text = {
    let scene_format_any = scene_texture_entry._get("format")
    if host_is_nullish(scene_format_any) {
      "<unknown>"
    } else {
      any_to_string(scene_format_any)
    }
  }
  report_debug_once(
    state,
    "bloom2d_scene_target",
    "bloom2d pass: scene_tex=" +
    scene_texture_id.to_string() +
    " scene_format=" +
    scene_format_text +
    " scene_size=" +
    scene_width.to_string() +
    "x" +
    scene_height.to_string() +
    " target_id=" +
    info.target_id.to_string() +
    " target_format=" +
    target_format.to_js_string() +
    " target_size=" +
    target_width.to_string() +
    "x" +
    target_height.to_string(),
  )
  let safe_scene_width = if scene_width > 0 { scene_width } else { 1 }
  let safe_scene_height = if scene_height > 0 { scene_height } else { 1 }
  let source_viewport_width = {
    let raw = if view_width > 0 { view_width } else { safe_scene_width }
    if raw > safe_scene_width {
      safe_scene_width
    } else {
      raw
    }
  }
  let source_viewport_height = {
    let raw = if view_height > 0 { view_height } else { safe_scene_height }
    if raw > safe_scene_height {
      safe_scene_height
    } else {
      raw
    }
  }
  let safe_max_mip_dimension = if max_mip_dimension < 4 {
    4
  } else {
    max_mip_dimension
  }
  let mip_count = bloom2d_effective_mip_count(safe_max_mip_dimension)
  let mip_height_ratio = safe_max_mip_dimension.to_double() /
    safe_viewport_height.to_double()
  let bloom_width_est = safe_viewport_width.to_double() * mip_height_ratio + 0.5
  let bloom_height_est = safe_viewport_height.to_double() * mip_height_ratio +
    0.5
  let bloom_width = {
    let raw = to_int(bloom_width_est)
    if raw < 1 {
      1
    } else {
      raw
    }
  }
  let bloom_height = {
    let raw = to_int(bloom_height_est)
    if raw < 1 {
      1
    } else {
      raw
    }
  }
  let bloom_mip_format = @webgpu.TextureFormat::Other("rgba16float")
  let bloom_mip_format_key = bloom_mip_format.to_js_string()
  let rebuild_mips = state.gpu.bloom2d_mip_texture is None ||
    state.gpu.bloom2d_mip_count != mip_count ||
    state.gpu.bloom2d_mip_width != bloom_width ||
    state.gpu.bloom2d_mip_height != bloom_height ||
    state.gpu.bloom2d_mip_format != bloom_mip_format_key
  if rebuild_mips {
    let usage = @webgpu.combine_flags(
      @webgpu.texture_usage_texture_binding(),
      @webgpu.texture_usage_render_attachment(),
    )
    let texture_desc = @js.from_entries([
      ("size", @webgpu.texture_size(bloom_width, bloom_height).to_js()),
      ("mipLevelCount", @js.any(mip_count)),
      ("sampleCount", @js.any(1)),
      ("dimension", @js.any("2d")),
      ("format", @js.any(bloom_mip_format_key)),
      ("usage", @js.any(usage)),
    ])
    let texture = device.create_texture(texture_desc)
    state.gpu.bloom2d_mip_texture = Some(texture)
    state.gpu.bloom2d_mip_views.clear()
    for mip in 0..<mip_count {
      state.gpu.bloom2d_mip_views.push(bloom2d_create_mip_view(texture, mip))
    }
    state.gpu.bloom2d_mip_count = mip_count
    state.gpu.bloom2d_mip_width = bloom_width
    state.gpu.bloom2d_mip_height = bloom_height
    state.gpu.bloom2d_mip_format = bloom_mip_format_key
  }
  if state.gpu.bloom2d_mip_views.length() < mip_count {
    report_asset_error_once(
      state, "bloom2d_draw_mip_views_not_ready", "Bloom2d draw skipped: bloom mip views are not ready",
    )
    return
  }
  let intensity_value = intensity
  let low_frequency_boost_value = low_frequency_boost
  let low_frequency_boost_curvature_value = low_frequency_boost_curvature
  let high_pass_frequency_value = high_pass_frequency
  let threshold_value = threshold
  let threshold_softness_value = threshold_softness
  let bloom_weight_value = if bloom_enabled { intensity_value } else { 0.0 }
  let tonemapping_mode_value = tonemapping_mode
  let deband_dither_enabled_value = deband_dither_enabled
  let bloom_settings_data = bloom2d_make_uniform_data(
    safe_scene_width.to_double(),
    safe_scene_height.to_double(),
    0.0,
    0.0,
    source_viewport_width.to_double(),
    source_viewport_height.to_double(),
    threshold_value,
    threshold_softness_value,
    scale_x_value,
    scale_y_value,
    bloom_weight_value,
    tonemapping_mode_value,
    deband_dither_enabled_value,
    0.0,
  )
  queue.write_buffer(settings_buffer, 0, bloom_settings_data)
  let scene_view : @webgpu.GPUTextureView = scene_texture_entry
    ._get("view")
    .cast()
  let selected_lut_texture_id = if tonemapping_mode == 4 {
    agx_lut_texture_id
  } else if tonemapping_mode == 6 {
    tony_lut_texture_id
  } else if tonemapping_mode == 7 {
    blender_lut_texture_id
  } else {
    -1
  }
  let lut_view = if selected_lut_texture_id >= 0 {
    match get_texture_entry(state, selected_lut_texture_id) {
      Some(lut_entry) => lut_entry._get("view").cast()
      None => scene_view
    }
  } else {
    scene_view
  }
  let scene_texture_raw = scene_texture_entry._get("texture")
  if host_is_nullish(scene_texture_raw) {
    report_asset_error_once(
      state, "bloom2d_draw_scene_texture_object_not_ready", "Bloom2d draw skipped: scene texture object is not ready",
    )
    return
  }
  let material_entries = [
    @webgpu.bind_group_entry_texture(0, scene_view),
    @webgpu.bind_group_entry_sampler(1, bloom_sampler),
    @webgpu.bind_group_entry_buffer(2, settings_buffer),
    @webgpu.bind_group_entry_texture(3, scene_view),
    @webgpu.bind_group_entry_texture(4, lut_view),
  ]
  let material_desc = @webgpu.bind_group_descriptor(
    bind_layout, material_entries,
  )
  let first_bind_group = device.create_bind_group(material_desc.to_js())
  active_pass.end()
  state.gpu.current_pass = None

  let mut mip_size_w = bloom_width
  let mut mip_size_h = bloom_height
  {
    let pass = bloom2d_begin_pass_clear(encoder, state.gpu.bloom2d_mip_views[0])
    pass.set_viewport(
      0.0,
      0.0,
      mip_size_w.to_double(),
      mip_size_h.to_double(),
      0.0,
      1.0,
    )
    pass.set_scissor_rect(0, 0, mip_size_w, mip_size_h)
    pass.set_pipeline(downsample_first_pipeline)
    pass.set_bind_group(0, first_bind_group)
    pass.draw(3, 1, 0, 0)
    pass.end()
  }

  for mip in 1..<mip_count {
    let src_view = state.gpu.bloom2d_mip_views[mip - 1]
    let dst_view = state.gpu.bloom2d_mip_views[mip]
    let entries = [
      @webgpu.bind_group_entry_texture(0, src_view),
      @webgpu.bind_group_entry_sampler(1, bloom_sampler),
      @webgpu.bind_group_entry_buffer(2, settings_buffer),
      @webgpu.bind_group_entry_texture(3, scene_view),
      @webgpu.bind_group_entry_texture(4, lut_view),
    ]
    let bind_group = device.create_bind_group(
      @webgpu.bind_group_descriptor(bind_layout, entries).to_js(),
    )
    mip_size_w = if mip_size_w > 1 { mip_size_w / 2 } else { 1 }
    mip_size_h = if mip_size_h > 1 { mip_size_h / 2 } else { 1 }
    let pass = bloom2d_begin_pass_clear(encoder, dst_view)
    pass.set_viewport(
      0.0,
      0.0,
      mip_size_w.to_double(),
      mip_size_h.to_double(),
      0.0,
      1.0,
    )
    pass.set_scissor_rect(0, 0, mip_size_w, mip_size_h)
    pass.set_pipeline(downsample_pipeline)
    pass.set_bind_group(0, bind_group)
    pass.draw(3, 1, 0, 0)
    pass.end()
  }

  let max_mip = if mip_count > 1 { mip_count - 1 } else { 1 }
  let max_mip_f = max_mip.to_double()
  let mut upsample_mip = mip_count - 1
  while upsample_mip >= 1 {
    let src_view = state.gpu.bloom2d_mip_views[upsample_mip]
    let dst_view = state.gpu.bloom2d_mip_views[upsample_mip - 1]
    let blend = bloom2d_compute_blend_factor(
      intensity_value,
      low_frequency_boost_value,
      low_frequency_boost_curvature_value,
      high_pass_frequency_value,
      composite_mode,
      upsample_mip.to_double(),
      max_mip_f,
    )
    let upsample_settings_data = bloom2d_make_uniform_data(
      safe_scene_width.to_double(),
      safe_scene_height.to_double(),
      0.0,
      0.0,
      source_viewport_width.to_double(),
      source_viewport_height.to_double(),
      threshold_value,
      threshold_softness_value,
      scale_x_value,
      scale_y_value,
      bloom_weight_value,
      tonemapping_mode_value,
      deband_dither_enabled_value,
      blend,
    )
    queue.write_buffer(settings_buffer, 0, upsample_settings_data)
    let entries = [
      @webgpu.bind_group_entry_texture(0, src_view),
      @webgpu.bind_group_entry_sampler(1, bloom_sampler),
      @webgpu.bind_group_entry_buffer(2, settings_buffer),
      @webgpu.bind_group_entry_texture(3, scene_view),
      @webgpu.bind_group_entry_texture(4, lut_view),
    ]
    let bind_group = device.create_bind_group(
      @webgpu.bind_group_descriptor(bind_layout, entries).to_js(),
    )
    let size_w = bloom2d_mip_dimension(bloom_width, upsample_mip - 1)
    let size_h = bloom2d_mip_dimension(bloom_height, upsample_mip - 1)
    let pass = bloom2d_begin_pass_load(encoder, dst_view)
    pass.set_viewport(
      0.0,
      0.0,
      size_w.to_double(),
      size_h.to_double(),
      0.0,
      1.0,
    )
    pass.set_scissor_rect(0, 0, size_w, size_h)
    pass.set_pipeline(upsample_pipeline)
    pass
    .as_any()
    ._call("setBlendConstant", [
      @webgpu.color(blend, blend, blend, blend).to_js(),
    ])
    |> ignore
    pass.set_bind_group(0, bind_group)
    pass.draw(3, 1, 0, 0)
    pass.end()
    upsample_mip = upsample_mip - 1
  }

  let final_blend = bloom2d_compute_blend_factor(
    intensity_value, low_frequency_boost_value, low_frequency_boost_curvature_value,
    high_pass_frequency_value, composite_mode, 0.0, max_mip_f,
  )
  guard bloom2d_ensure_compose_view(state, safe_scene_width, safe_scene_height)
    is Some(compose_view) else {
    report_asset_error_once(
      state, "bloom2d_draw_compose_texture_not_ready", "Bloom2d draw skipped: compose texture is not ready",
    )
    return
  }
  guard state.gpu.bloom2d_compose_texture is Some(compose_texture) else {
    return
  }
  copy_texture_to_texture_region_on_encoder(
    encoder.as_any(),
    scene_texture_raw,
    compose_texture.as_any(),
    source_viewport_width,
    source_viewport_height,
    0,
    0,
  )

  let compose_entries = [
    @webgpu.bind_group_entry_texture(0, state.gpu.bloom2d_mip_views[0]),
    @webgpu.bind_group_entry_sampler(1, bloom_sampler),
    @webgpu.bind_group_entry_buffer(2, settings_buffer),
    @webgpu.bind_group_entry_texture(3, scene_view),
    @webgpu.bind_group_entry_texture(4, lut_view),
  ]
  let compose_settings_data = bloom2d_make_uniform_data(
    safe_scene_width.to_double(),
    safe_scene_height.to_double(),
    0.0,
    0.0,
    source_viewport_width.to_double(),
    source_viewport_height.to_double(),
    threshold_value,
    threshold_softness_value,
    scale_x_value,
    scale_y_value,
    bloom_weight_value,
    tonemapping_mode_value,
    deband_dither_enabled_value,
    final_blend,
  )
  queue.write_buffer(settings_buffer, 0, compose_settings_data)
  let compose_bind_group = device.create_bind_group(
    @webgpu.bind_group_descriptor(bind_layout, compose_entries).to_js(),
  )
  {
    let pass = bloom2d_begin_pass_load(encoder, compose_view)
    pass.set_viewport(
      0.0,
      0.0,
      source_viewport_width.to_double(),
      source_viewport_height.to_double(),
      0.0,
      1.0,
    )
    pass.set_scissor_rect(0, 0, source_viewport_width, source_viewport_height)
    pass.set_pipeline(upsample_pipeline)
    pass
    .as_any()
    ._call("setBlendConstant", [
      @webgpu.color(final_blend, final_blend, final_blend, final_blend).to_js(),
    ])
    |> ignore
    pass.set_bind_group(0, compose_bind_group)
    pass.draw(3, 1, 0, 0)
    pass.end()
  }

  let tonemap_settings_data = bloom2d_make_uniform_data(
    safe_scene_width.to_double(),
    safe_scene_height.to_double(),
    0.0,
    0.0,
    source_viewport_width.to_double(),
    source_viewport_height.to_double(),
    0.0,
    0.0,
    1.0,
    1.0,
    0.0,
    tonemapping_mode_value,
    deband_dither_enabled_value,
    0.0,
  )
  queue.write_buffer(settings_buffer, 0, tonemap_settings_data)
  let tonemap_entries = [
    @webgpu.bind_group_entry_texture(0, compose_view),
    @webgpu.bind_group_entry_sampler(1, bloom_sampler),
    @webgpu.bind_group_entry_buffer(2, settings_buffer),
    @webgpu.bind_group_entry_texture(3, compose_view),
    @webgpu.bind_group_entry_texture(4, lut_view),
  ]
  let tonemap_bind_group = device.create_bind_group(
    @webgpu.bind_group_descriptor(bind_layout, tonemap_entries).to_js(),
  )
  {
    let pass = bloom2d_begin_pass_load(encoder, target_view)
    pass.set_viewport(
      info.viewport_x,
      info.viewport_y,
      info.viewport_width,
      info.viewport_height,
      info.viewport_depth_min,
      info.viewport_depth_max,
    )
    pass.set_scissor_rect(
      to_int(info.viewport_x),
      to_int(info.viewport_y),
      to_int(info.viewport_width),
      to_int(info.viewport_height),
    )
    pass.set_pipeline(final_pipeline)
    pass.set_bind_group(0, tonemap_bind_group)
    pass.draw(3, 1, 0, 0)
    pass.end()
  }

  begin_pass(
    state,
    info.target_id,
    info.width,
    info.height,
    0.0,
    0.0,
    0.0,
    0.0,
    info.cam_x,
    info.cam_y,
    info.cam_rotation,
    info.cam_scale,
    false,
    info.cam_z,
    info.cam_rot_x,
    info.cam_rot_y,
    info.cam_rot_z,
    info.cam_rot_w,
    info.cam_fov_y,
    info.cam_near,
    info.cam_far,
    info.viewport_x,
    info.viewport_y,
    info.viewport_width,
    info.viewport_height,
    info.viewport_depth_min,
    info.viewport_depth_max,
    info.ambient_r,
    info.ambient_g,
    info.ambient_b,
    info.ambient_brightness,
    info.directional_dir_x,
    info.directional_dir_y,
    info.directional_dir_z,
    info.directional_color_r,
    info.directional_color_g,
    info.directional_color_b,
    info.directional_illuminance,
    info.point_pos_x,
    info.point_pos_y,
    info.point_pos_z,
    info.point_color_r,
    info.point_color_g,
    info.point_color_b,
    info.point_intensity,
    info.point_range,
    info.spot_pos_x,
    info.spot_pos_y,
    info.spot_pos_z,
    info.spot_dir_x,
    info.spot_dir_y,
    info.spot_dir_z,
    info.spot_color_r,
    info.spot_color_g,
    info.spot_color_b,
    info.spot_intensity,
    info.spot_range,
    info.spot_inner_angle,
    info.spot_outer_angle,
    info.sub_camera_view_scale_x,
    info.sub_camera_view_scale_y,
    info.sub_camera_view_bias_x,
    info.sub_camera_view_bias_y,
    info.previous_camera_x,
    info.previous_camera_y,
    info.previous_camera_z,
    info.previous_camera_rot_x,
    info.previous_camera_rot_y,
    info.previous_camera_rot_z,
    info.previous_camera_rot_w,
    info.pass_kind,
    0.0,
  )
}

///|
fn draw_gizmo_lines(state : State, data : @js.Any) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  if state.gpu.queue is None || state.gpu.device is None {
    return
  }
  ensure_gizmo_pipeline(state)
  if state.gpu.gizmo_pipeline is None {
    return
  }
  if state.gpu.current_pass is Some(pass) &&
    state.gpu.current_pass_info is Some(info) &&
    state.gpu.queue is Some(queue) {
    let vertex_data = build_gizmo_vertices(
      data,
      info.cam_x,
      info.cam_y,
      info.cam_rotation,
      info.cam_scale,
      info.width,
      info.height,
      2.0,
    )
    let vertex_len : Double = vertex_data._get("length").cast()
    if vertex_len <= 0 {
      return
    }
    let vertex_count = to_int(vertex_len / 6.0)
    if vertex_count <= 0 {
      return
    }
    let vertex_size : Int = vertex_data._get("byteLength").cast()
    let mut buffer_opt = state.gpu.gizmo_vertex_buffer
    if buffer_opt is None || vertex_size > state.gpu.gizmo_vertex_capacity {
      if state.gpu.device is Some(device) {
        let capacity = if vertex_size < 256 { 256 } else { vertex_size }
        let usage = @webgpu.combine_flags(
          @webgpu.buffer_usage_vertex(),
          @webgpu.buffer_usage_copy_dst(),
        )
        let desc = @webgpu.buffer_descriptor(capacity, usage)
        let buffer = device.create_buffer(desc.to_js())
        state.gpu.gizmo_vertex_buffer = Some(buffer)
        state.gpu.gizmo_vertex_capacity = capacity
        buffer_opt = Some(buffer)
      }
    }
    if buffer_opt is Some(buffer) && state.gpu.gizmo_pipeline is Some(pipeline) {
      queue.write_buffer(buffer, 0, vertex_data)
      pass.set_pipeline(pipeline)
      pass.set_vertex_buffer(0, buffer)
      pass.draw(vertex_count, 1, 0, 0)
    }
  }
}

///|
