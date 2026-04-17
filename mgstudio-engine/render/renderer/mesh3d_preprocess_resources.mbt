// Copyright 2026 International Digital Economy Academy
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
fn ensure_mesh3d_preprocess_indirect_resources(
  backend : GpuBackend,
) -> Unit raise GpuBackendError {
  let compute = ss(@wgpu.SHADER_STAGE_COMPUTE)
  if backend.mesh3d_preprocess_direct_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal("wgpu: failed to build mesh3d preprocess direct bind group layout")
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_direct_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label("mgstudio_mesh3d_preprocess_direct_pipeline_layout")
    backend.mesh3d_preprocess_direct_bgl = Some(bgl)
    backend.mesh3d_preprocess_direct_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_indirect_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=8UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        7U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        9U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      )
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indirect bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_indirect_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label("mgstudio_mesh3d_preprocess_indirect_pipeline_layout")
    backend.mesh3d_preprocess_indirect_bgl = Some(bgl)
    backend.mesh3d_preprocess_indirect_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_indirect_early_occlusion_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=12UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        7U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        9U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_texture(
        10U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_buffer(11U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(12U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indirect early occlusion bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_indirect_early_occlusion_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_indirect_early_occlusion_pipeline_layout",
    )
    backend.mesh3d_preprocess_indirect_early_occlusion_bgl = Some(bgl)
    backend.mesh3d_preprocess_indirect_early_occlusion_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_indirect_late_occlusion_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=11UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPROCESS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_UNIFORM,
        min_binding_size=MESH3D_PREPASS_PREVIOUS_VIEW_BUFFER_SIZE,
      ) &&
      builder.add_buffer(
        3U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        4U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        5U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(6U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        7U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(8U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(
        9U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_texture(
        10U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_UNFILTERABLE_FLOAT,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_buffer(
        12U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      )
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indirect late occlusion bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_indirect_late_occlusion_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_indirect_late_occlusion_pipeline_layout",
    )
    backend.mesh3d_preprocess_indirect_late_occlusion_bgl = Some(bgl)
    backend.mesh3d_preprocess_indirect_late_occlusion_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_reset_batch_sets_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=1UL)
    let ok = builder.add_buffer(0U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess reset batch sets bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_reset_batch_sets_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_reset_batch_sets_pipeline_layout",
    )
    backend.mesh3d_preprocess_reset_batch_sets_bgl = Some(bgl)
    backend.mesh3d_preprocess_reset_batch_sets_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        1U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess indexed indirect bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_build_indexed_indirect_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_build_indexed_indirect_pipeline_layout",
    )
    backend.mesh3d_preprocess_build_indexed_indirect_bgl = Some(bgl)
    backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=5UL)
    let ok = builder.add_buffer(
        0U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        1U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(
        2U,
        compute,
        @wgpu.BUFFER_BINDING_TYPE_READ_ONLY_STORAGE,
      ) &&
      builder.add_buffer(3U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE) &&
      builder.add_buffer(4U, compute, @wgpu.BUFFER_BINDING_TYPE_STORAGE)
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess non-indexed indirect bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_build_non_indexed_indirect_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout",
    )
    backend.mesh3d_preprocess_build_non_indexed_indirect_bgl = Some(bgl)
    backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout = Some(
      layout,
    )
  }
  if backend.mesh3d_preprocess_downsample_depth_bgl is None {
    let builder = @wgpu.BindGroupLayoutBuilder::new(max_entries=14UL)
    let ok = builder.add_texture(
        0U,
        compute,
        @wgpu.TEXTURE_SAMPLE_TYPE_DEPTH,
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        1U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        2U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        3U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        4U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        5U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        6U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_READ_WRITE,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        7U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        8U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        9U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        10U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        11U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_storage_texture(
        12U,
        compute,
        @wgpu.STORAGE_TEXTURE_ACCESS_WRITE_ONLY,
        tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
        @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      ) &&
      builder.add_sampler(
        13U,
        compute,
        @wgpu.SAMPLER_BINDING_TYPE_NON_FILTERING,
      )
    if !ok {
      builder.free()
      fatal(
        "wgpu: failed to build mesh3d preprocess downsample depth bind group layout",
      )
    }
    let bgl = builder.finish(
      backend.device,
      label="mgstudio_mesh3d_preprocess_downsample_depth_bgl",
    )
    let layout = backend.device.create_pipeline_layout_1(bgl)
    layout.set_label(
      "mgstudio_mesh3d_preprocess_downsample_depth_pipeline_layout",
    )
    backend.mesh3d_preprocess_downsample_depth_bgl = Some(bgl)
    backend.mesh3d_preprocess_downsample_depth_pipeline_layout = Some(layout)
  }
  if backend.mesh3d_preprocess_depth_pyramid_dummy_texture is None {
    let usage = @wgpu.TextureUsage::from_u64(
      @wgpu.TEXTURE_USAGE_TEXTURE_BINDING | @wgpu.TEXTURE_USAGE_STORAGE_BINDING,
    )
    let texture = backend.device.create_texture_u32(
      1U,
      1U,
      1U,
      usage,
      @wgpu.TextureDimension::from_u32(@wgpu.TEXTURE_DIMENSION_2D),
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
    )
    let view = texture.create_view_u32(
      tf(@wgpu.TEXTURE_FORMAT_R32_FLOAT),
      @wgpu.TEXTURE_VIEW_DIMENSION_2D,
      @wgpu.TEXTURE_ASPECT_ALL,
      0U,
      1U,
      0U,
      1U,
    )
    backend.mesh3d_preprocess_depth_pyramid_dummy_texture = Some(texture)
    backend.mesh3d_preprocess_depth_pyramid_dummy_view = Some(view)
  }
  if backend.mesh3d_preprocess_depth_pyramid_sampler is None {
    backend.mesh3d_preprocess_depth_pyramid_sampler = Some(
      backend.device.create_sampler_nearest_clamp(),
    )
  }
  if backend.mesh3d_preprocess_reset_batch_sets_pipeline is None {
    guard backend.mesh3d_preprocess_reset_batch_sets_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_from_assets_required(
      backend, "pbr/render/reset_indirect_batch_sets.wgsl",
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess reset batch sets pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_reset_batch_sets")
    backend.mesh3d_preprocess_reset_batch_sets_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_direct_pipeline is None {
    guard backend.mesh3d_preprocess_direct_pipeline_layout is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_direct(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess direct pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_direct")
    backend.mesh3d_preprocess_direct_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_indirect_pipeline is None {
    guard backend.mesh3d_preprocess_indirect_pipeline_layout is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_indirect(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indirect pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_indirect")
    backend.mesh3d_preprocess_indirect_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_indirect_early_occlusion_pipeline is None {
    guard backend.mesh3d_preprocess_indirect_early_occlusion_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_indirect_early_occlusion(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indirect early occlusion pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_indirect_early_occlusion")
    backend.mesh3d_preprocess_indirect_early_occlusion_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_indirect_late_occlusion_pipeline is None {
    guard backend.mesh3d_preprocess_indirect_late_occlusion_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_preprocess_indirect_late_occlusion(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indirect late occlusion pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_indirect_late_occlusion")
    backend.mesh3d_preprocess_indirect_late_occlusion_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_pipeline is None {
    guard backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_indexed_indirect_params(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indexed indirect pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_build_indexed_indirect")
    backend.mesh3d_preprocess_build_indexed_indirect_pipeline = Some(pipeline)
    shader.release()
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_early_pipeline is None {
    guard backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_indexed_indirect_params_early(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indexed indirect early pipeline: \{err.message()}",
        )
    }
    pipeline.set_label(
      "mgstudio_mesh3d_preprocess_build_indexed_indirect_early",
    )
    backend.mesh3d_preprocess_build_indexed_indirect_early_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_late_pipeline is None {
    guard backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_indexed_indirect_params_late(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indexed indirect late pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_build_indexed_indirect_late")
    backend.mesh3d_preprocess_build_indexed_indirect_late_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_indexed_indirect_main_pipeline is None {
    guard backend.mesh3d_preprocess_build_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_indexed_indirect_params_main(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess indexed indirect main pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_build_indexed_indirect_main")
    backend.mesh3d_preprocess_build_indexed_indirect_main_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline is None {
    guard backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_non_indexed_indirect_params(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess non-indexed indirect pipeline: \{err.message()}",
        )
    }
    pipeline.set_label("mgstudio_mesh3d_preprocess_build_non_indexed_indirect")
    backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_early_pipeline is None {
    guard backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_non_indexed_indirect_params_early(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess non-indexed indirect early pipeline: \{err.message()}",
        )
    }
    pipeline.set_label(
      "mgstudio_mesh3d_preprocess_build_non_indexed_indirect_early",
    )
    backend.mesh3d_preprocess_build_non_indexed_indirect_early_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_late_pipeline is None {
    guard backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_non_indexed_indirect_params_late(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess non-indexed indirect late pipeline: \{err.message()}",
        )
    }
    pipeline.set_label(
      "mgstudio_mesh3d_preprocess_build_non_indexed_indirect_late",
    )
    backend.mesh3d_preprocess_build_non_indexed_indirect_late_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_build_non_indexed_indirect_main_pipeline is None {
    guard backend.mesh3d_preprocess_build_non_indexed_indirect_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_build_non_indexed_indirect_params_main(
      backend.assets_base,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "main",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess non-indexed indirect main pipeline: \{err.message()}",
        )
    }
    pipeline.set_label(
      "mgstudio_mesh3d_preprocess_build_non_indexed_indirect_main",
    )
    backend.mesh3d_preprocess_build_non_indexed_indirect_main_pipeline = Some(
      pipeline,
    )
    shader.release()
  }
  if backend.mesh3d_preprocess_downsample_depth_first_pipeline is None {
    guard backend.mesh3d_preprocess_downsample_depth_pipeline_layout
      is Some(layout) else {
      return
    }
    let source = load_wgsl_required_mesh3d_downsample_depth(
      backend.assets_base,
      12,
    )
    let shader = backend.device.create_shader_module_wgsl(source)
    let first_pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "downsample_depth_first",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess downsample depth first pipeline: \{err.message()}",
        )
    }
    let second_pipeline = backend.device.create_compute_pipeline_with_layout_entry(
      layout, shader, "downsample_depth_second",
    ) catch {
      err =>
        fatal(
          "wgpu: failed to create mesh3d preprocess downsample depth second pipeline: \{err.message()}",
        )
    }
    first_pipeline.set_label(
      "mgstudio_mesh3d_preprocess_downsample_depth_first",
    )
    second_pipeline.set_label(
      "mgstudio_mesh3d_preprocess_downsample_depth_second",
    )
    backend.mesh3d_preprocess_downsample_depth_first_pipeline = Some(
      first_pipeline,
    )
    backend.mesh3d_preprocess_downsample_depth_second_pipeline = Some(
      second_pipeline,
    )
    shader.release()
  }
}
