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
fn ensure_pipeline_resources(state : State) -> Unit {
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
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
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
    let fallback_size = 64
    let texture_usage = @webgpu.combine_flags(
      @webgpu.combine_flags(
        @webgpu.texture_usage_texture_binding(),
        @webgpu.texture_usage_copy_dst(),
      ),
      @webgpu.texture_usage_render_attachment(),
    )
    let texture_desc = @webgpu.texture_descriptor(
      @webgpu.texture_size(fallback_size, fallback_size),
      @webgpu.TextureFormat::Rgba8Unorm,
      texture_usage,
    )
    let texture = device.create_texture(texture_desc.to_js())
    let pixel_data = create_checkerboard_data(fallback_size)
    write_texture(
      device.queue().as_any(),
      texture.as_any(),
      pixel_data,
      fallback_size * 4,
      fallback_size,
      fallback_size,
    )
    let sampler = create_sampler(state, sampler_kind_from_nearest(true))
    if sampler is Some(sampler_value) {
      let entry = @js.from_entries([
        ("id", @js.any(state.gpu.fallback_texture_id)),
        ("texture", texture.as_any()),
        ("view", texture.create_view().as_any()),
        ("sampler", sampler_value.as_any()),
        ("bindGroup", js_null()),
        ("meshBindGroup", js_null()),
        ("mesh3dBindGroup", js_null()),
        ("uiBindGroup", js_null()),
        ("width", @js.any(fallback_size)),
        ("height", @js.any(fallback_size)),
      ])
      map_set(state.gpu.textures, @js.any(state.gpu.fallback_texture_id), entry)
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
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
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
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
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
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
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
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
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
    let usage = @webgpu.texture_usage_render_attachment()
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
fn ensure_mesh3d_pipeline(state : State) -> Unit {
  if state.gpu.mesh3d_pipeline is Some(_) &&
    state.gpu.mesh3d_pipeline_transparent is Some(_) {
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
    let primitive_state = @webgpu.primitive_state(
      @webgpu.PrimitiveTopology::TriangleList,
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
      ("primitive", primitive_state.to_js()),
      ("depthStencil", depth_state_opaque),
    ])
    device.push_error_scope("validation")
    let pipeline_opaque = device.create_render_pipeline(pipeline_desc_opaque)
    let pipeline_error_promise_opaque = device.pop_error_scope()
    @js.run_async(async fn() noraise {
      let err_any : @js.Any = pipeline_error_promise_opaque.wait() catch {
        _ => js_null()
      }
      if !host_is_nullish(err_any) {
        report_asset_error_once(
          state,
          "mesh3d_pipeline_validation_error",
          "Mesh3d pipeline validation error: " + any_to_string(err_any),
        )
        state.gpu.mesh3d_pipeline = None
      }
    })
    state.gpu.mesh3d_pipeline = Some(pipeline_opaque)

    let depth_state_transparent = @js.from_entries([
      ("format", @js.any("depth24plus")),
      ("depthWriteEnabled", @js.any(false)),
      ("depthCompare", @js.any("less-equal")),
    ])
    let pipeline_desc_transparent = @js.from_entries([
      ("layout", pipeline_layout.as_any()),
      ("vertex", vertex_state.to_js()),
      ("fragment", fragment_state.to_js()),
      ("primitive", primitive_state.to_js()),
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
          "mesh3d_pipeline_transparent_validation_error",
          "Mesh3d transparent pipeline validation error: " +
          any_to_string(err_any),
        )
        state.gpu.mesh3d_pipeline_transparent = None
      }
    })
    state.gpu.mesh3d_pipeline_transparent = Some(pipeline_transparent)
  }
}

///|
fn ensure_gizmo_pipeline(state : State) -> Unit {
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
    let format = state.gpu.format.unwrap_or(@webgpu.TextureFormat::Bgra8Unorm)
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
fn report_fallback_usage(state : State, id : Int, reason : String) -> Unit {
  if set_has(state.assets.loading_textures, @js.any(id)) {
    return
  }
  if set_has(state.assets.fallback_reported, @js.any(id)) {
    return
  }
  set_add(state.assets.fallback_reported, @js.any(id))
  let path_hint = map_get(state.assets.texture_paths, @js.any(id))
  let suffix = if host_is_nullish(path_hint) {
    ""
  } else {
    " (path: " + path_hint.cast() + ")"
  }
  let message = "Fallback texture used for id " +
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
    // fallback flashes (especially visible for atlas/rect sprites).
    return None
  }
  let reason = if host_is_nullish(entry) {
    "texture id not found"
  } else {
    "texture not ready"
  }
  report_fallback_usage(state, id, reason)
  let fallback_entry = map_get(
    state.gpu.textures,
    @js.any(state.gpu.fallback_texture_id),
  )
  if host_is_nullish(fallback_entry) {
    None
  } else {
    Some(fallback_entry)
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
  let blob : @js.Any = response_blob(response.as_any()).wait()
  load_texture_from_blob(state, id, blob, nearest)
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
  let blob = blob_from_uint8array(blob_bytes)
  load_texture_from_blob(state, id, blob, nearest)
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
      @webgpu.TextureFormat::Rgba8Unorm,
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
      ])
      map_set(state.gpu.textures, @js.any(id), entry)
      ensure_bind_group_for_texture(state, entry)
    }
  }
  set_delete(state.assets.loading_textures, @js.any(id)) |> ignore
}

///|
async fn load_wgsl_from_path(state : State, id : Int, path : String) -> String {
  let url = resolve_asset_url(state, @js.any(path))
  let response = @http.fetch(url, method_="GET")
  if !response.ok {
    fail(
      "Failed to load shader: " + url + " (" + response.status.to_string() + ")",
    )
  }
  let source = response_text(response.as_any()).wait()
  map_set(state.assets.shader_sources, @js.any(id), @js.any(source))
  source
}

///|
async fn fetch_text_from_url(url : String) -> String {
  let response = @http.fetch(url, method_="GET")
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
fn arg_number(args : Array[@js.Any], index : Int, fallback : Double) -> Double {
  number_or(arg_any(args, index), fallback)
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
  clear_enabled : Double,
) -> Unit {
  report_debug_once(
    state,
    "begin_pass_clear",
    "begin_pass clear=(" +
    clear_r.to_string() +
    "," +
    clear_g.to_string() +
    "," +
    clear_b.to_string() +
    "," +
    clear_a.to_string() +
    ") size=(" +
    width.to_string() +
    "," +
    height.to_string() +
    ") viewport=(" +
    viewport_width.to_string() +
    "," +
    viewport_height.to_string() +
    ")",
  )
  if state.gpu.encoder is None {
    return
  }
  if state.gpu.encoder is Some(encoder) {
    let mut view : @webgpu.GPUTextureView? = None
    let mut target_width = if width > 0 { to_int(width) } else { 1 }
    let mut target_height = if height > 0 { to_int(height) } else { 1 }
    if target_id < 0 {
      if state.gpu.current_texture is Some(current_texture) {
        view = Some(current_texture.create_view())
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
      pass.set_viewport(vp_x, vp_y, vp_width, vp_height, 0, 1)
      pass.set_scissor_rect(
        to_int(vp_x),
        to_int(vp_y),
        to_int(vp_width),
        to_int(vp_height),
      )
      state.gpu.current_pass = Some(pass)
      state.gpu.current_pass_info = Some(PassInfo::{
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
        viewport_x: vp_x,
        viewport_y: vp_y,
        viewport_width: vp_width,
        viewport_height: vp_height,
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
  report_debug_once(
    state,
    "flush_sprite_batches",
    "flush_sprite_batches: instances=" +
    state.gpu.sprite_instance_count.to_string() +
    " batches=" +
    state.gpu.sprite_batches.length().to_string(),
  )
  if state.gpu.device is Some(device) && state.gpu.queue is Some(queue) {
    let required_bytes = state.gpu.sprite_instance_data.length() * 4
    if required_bytes <= 0 {
      return
    }
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
      let instance_data = float32array_from_array(
        state.gpu.sprite_instance_data,
      )
      queue.write_buffer(instance_buffer, 0, instance_data)
      pass.set_pipeline(pipeline)
      pass.set_bind_group(1, globals_bind_group)
      for batch in state.gpu.sprite_batches {
        let entry = get_texture_entry(state, batch.texture_id)
        if entry is None {
          continue
        }
        if entry is Some(entry_value) {
          ensure_bind_group_for_texture(state, entry_value)
          let bind_group_any = entry_value._get("bindGroup")
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
  report_debug_once(
    state,
    "flush_ui_batches",
    "flush_ui_batches: instances=" +
    state.gpu.ui_instance_count.to_string() +
    " batches=" +
    state.gpu.ui_batches.length().to_string(),
  )
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
  report_debug_once(
    state,
    "flush_ui_shadow_batches",
    "flush_ui_shadow_batches: instances=" +
    state.gpu.ui_shadow_instance_count.to_string() +
    " batches=" +
    state.gpu.ui_shadow_batches.length().to_string(),
  )
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
  report_debug_once(
    state,
    "flush_ui_slice_batches",
    "flush_ui_slice_batches: instances=" +
    state.gpu.ui_slice_instance_count.to_string() +
    " batches=" +
    state.gpu.ui_slice_batches.length().to_string(),
  )
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
  report_debug_once(
    state,
    "draw_sprite_uv_called",
    "draw_sprite_uv called: tex_id=" +
    texture_id.to_string() +
    " pos=(" +
    x.to_string() +
    "," +
    y.to_string() +
    ") scale=(" +
    scale_x.to_string() +
    "," +
    scale_y.to_string() +
    ") color=(" +
    r.to_string() +
    "," +
    g.to_string() +
    "," +
    b.to_string() +
    "," +
    a.to_string() +
    ") uv=(" +
    uv_min_x.to_string() +
    "," +
    uv_min_y.to_string() +
    ")-(" +
    uv_max_x.to_string() +
    "," +
    uv_max_y.to_string() +
    ")",
  )
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
    // Preserve negative uv_scale for sprite flipping; only treat "zero-sized" as fallback.
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
  report_debug_once(
    state,
    "draw_ui_rect_called",
    "draw_ui_rect called: tex_id=" +
    texture_id.to_string() +
    " pos=(" +
    x.to_string() +
    "," +
    y.to_string() +
    ") scale=(" +
    scale_x.to_string() +
    "," +
    scale_y.to_string() +
    ") flags=" +
    flags.to_string(),
  )
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
  report_debug_once(
    state,
    "draw_ui_texture_slice_called",
    "draw_ui_texture_slice called: tex_id=" +
    texture_id.to_string() +
    " pos=(" +
    x.to_string() +
    "," +
    y.to_string() +
    ") scale=(" +
    scale_x.to_string() +
    "," +
    scale_y.to_string() +
    ")",
  )
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
  report_debug_once(
    state,
    "draw_ui_box_shadow_called",
    "draw_ui_box_shadow called: tex_id=" +
    texture_id.to_string() +
    " pos=(" +
    x.to_string() +
    "," +
    y.to_string() +
    ") scale=(" +
    scale_x.to_string() +
    "," +
    scale_y.to_string() +
    ") size=(" +
    size_x.to_string() +
    "," +
    size_y.to_string() +
    ") blur=" +
    blur.to_string() +
    " samples=" +
    samples.to_string(),
  )
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
  report_debug_once(
    state,
    "draw_mesh_called",
    "draw_mesh called: mesh_id=" +
    mesh_id.to_string() +
    " pos=(" +
    x.to_string() +
    "," +
    y.to_string() +
    ") scale=(" +
    scale_x.to_string() +
    "," +
    scale_y.to_string() +
    ") color=(" +
    r.to_string() +
    "," +
    g.to_string() +
    "," +
    b.to_string() +
    "," +
    a.to_string() +
    ") texture=" +
    texture_id.to_string() +
    " uv_offset=(" +
    uv_offset_x.to_string() +
    "," +
    uv_offset_y.to_string() +
    ") uv_scale=(" +
    uv_scale_x.to_string() +
    "," +
    uv_scale_y.to_string() +
    ")",
  )
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
    state.gpu.fallback_texture_id
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
    report_debug_once(
      state,
      "mesh_ndc_scale",
      "mesh ndc_scale=(" +
      scale_x_base.to_string() +
      "," +
      scale_y_base.to_string() +
      ")",
    )
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
    report_debug_once(
      state,
      "mesh_vertex_count",
      "draw_mesh vertex_count=" + vertex_count.to_string(),
    )
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
) -> Unit {
  if state.gpu.current_pass is None || state.gpu.current_pass_info is None {
    return
  }
  flush_ui_shadow_batches(state)
  flush_ui_slice_batches(state)
  flush_ui_batches(state)
  flush_sprite_batches(state)
  ensure_mesh3d_pipeline(state)
  let use_transparent_pipeline = a < 0.999
  let mesh3d_pipeline_opt = if use_transparent_pipeline {
    state.gpu.mesh3d_pipeline_transparent
  } else {
    state.gpu.mesh3d_pipeline
  }
  if mesh3d_pipeline_opt is None {
    report_asset_error_once(
      state, "mesh3d_draw_pipeline_not_ready", "Mesh3d draw skipped: mesh3d pipeline not ready",
    )
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
  let textured = texture_id >= 0
  let base_texture_id = if textured {
    texture_id
  } else {
    state.gpu.fallback_texture_id
  }
  let emissive_textured = emissive_texture_id >= 0
  let normal_textured = normal_texture_id >= 0
  let resolved_normal_texture_id = if normal_textured {
    normal_texture_id
  } else {
    state.gpu.fallback_texture_id
  }
  let resolved_emissive_texture_id = if emissive_textured {
    emissive_texture_id
  } else {
    state.gpu.fallback_texture_id
  }
  let metallic_roughness_textured = metallic_roughness_texture_id >= 0
  let resolved_metallic_roughness_texture_id = if metallic_roughness_textured {
    metallic_roughness_texture_id
  } else {
    state.gpu.fallback_texture_id
  }
  let occlusion_textured = occlusion_texture_id >= 0
  let resolved_occlusion_texture_id = if occlusion_textured {
    occlusion_texture_id
  } else {
    state.gpu.fallback_texture_id
  }
  let depth_textured = depth_texture_id >= 0
  let resolved_depth_texture_id = if depth_textured {
    depth_texture_id
  } else {
    state.gpu.fallback_texture_id
  }
  let anisotropy_textured = anisotropy_texture_id >= 0
  let resolved_anisotropy_texture_id = if anisotropy_textured {
    anisotropy_texture_id
  } else {
    state.gpu.fallback_texture_id
  }
  let base_texture_entry = get_texture_entry(state, base_texture_id)
  let normal_texture_entry = get_texture_entry(
    state, resolved_normal_texture_id,
  )
  let emissive_texture_entry = get_texture_entry(
    state, resolved_emissive_texture_id,
  )
  let metallic_roughness_texture_entry = get_texture_entry(
    state, resolved_metallic_roughness_texture_id,
  )
  let occlusion_texture_entry = get_texture_entry(
    state, resolved_occlusion_texture_id,
  )
  let depth_texture_entry = get_texture_entry(state, resolved_depth_texture_id)
  let anisotropy_texture_entry = get_texture_entry(
    state, resolved_anisotropy_texture_id,
  )
  if base_texture_entry is None ||
    normal_texture_entry is None ||
    emissive_texture_entry is None ||
    metallic_roughness_texture_entry is None ||
    occlusion_texture_entry is None ||
    depth_texture_entry is None ||
    anisotropy_texture_entry is None {
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
    anisotropy_texture_entry is Some(anisotropy_texture_entry_value) {
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
      0.0,
      0.0,
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
