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
fn skybox_test_abs(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn skybox_test_approx(a : Float, b : Float) -> Bool {
  skybox_test_abs(a - b) < 0.0001F
}

///|
test "skybox: render sub app configuration installs Bevy-shaped resources" {
  let render_sub_app = @app.SubApp::new(@ecs.World::new()).set_update_schedule(
    Some(@render.render_schedule_stage()),
  )
  let render_sub_app = configure_skybox_render_sub_app(render_sub_app)
  let world = render_sub_app.world()

  debug_inspect(
    world.resource(SkyboxPipelineState::resource()).is_present(),
    content="true",
  )
  debug_inspect(
    world.resource(ExtractedSkyboxes::resource()).is_present(),
    content="true",
  )
}

///|
test "skybox: plugin installs Bevy-shaped uniform component preparation" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(SkyboxPlugin::SkyboxPlugin())
  let settings = @app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
      name : String,
    ) {
      name.has_prefix("mgstudio_render::uniform::")
    },
  )
  let render_dot = app
    .sub_app(@app.RenderApp)
    .schedule_graph_dot(@render.render_schedule_stage(), settings~)
  debug_inspect(
    render_dot.contains(
      "\"mgstudio_render::uniform::prepare_uniform_components<mgstudio_core_pipeline::SkyboxUniforms>\"",
    ),
    content="true",
  )
}

///|
test "skybox: uniforms match Bevy brightness and inverse-rotation transform" {
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(7)
  let skybox = @light.Skybox::new(image, -2.0F).with_rotation(
    @math.Quat::identity(),
  )
  let uniforms = SkyboxUniforms::from_skybox(skybox, 3.0F)

  debug_inspect(skybox_test_approx(uniforms.brightness, -6.0F), content="true")
  debug_inspect(uniforms.is_ready_for_bind_group(), content="true")
  debug_inspect(uniforms.transform.length(), content="16")
  debug_inspect(
    skybox_test_approx(uniforms.transform[0], 1.0F) &&
    skybox_test_approx(uniforms.transform[5], 1.0F) &&
    skybox_test_approx(uniforms.transform[10], 1.0F) &&
    skybox_test_approx(uniforms.transform[15], 1.0F),
    content="true",
  )
}

///|
test "skybox: default exposure fallback scales brightness like Bevy extract" {
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(9)
  let skybox = @light.Skybox::new(image, 1000.0F)
  let exposure = @camera_camera.Exposure::Exposure().exposure()
  let uniforms = SkyboxUniforms::from_skybox(skybox, exposure)

  debug_inspect(
    skybox_test_approx(uniforms.brightness, 1000.0F * exposure),
    content="true",
  )
  debug_inspect(
    skybox_test_approx(uniforms.transform[0], 1.0F) &&
    skybox_test_approx(uniforms.transform[5], 1.0F) &&
    skybox_test_approx(uniforms.transform[10], 1.0F) &&
    skybox_test_approx(uniforms.transform[15], 1.0F),
    content="true",
  )
}

///|
test "skybox: draw params come from extracted uniforms and inverse rotation" {
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(11)
  let skybox = @light.Skybox::new(image, 4.0F).with_rotation(
    @math.Quat::new(0.25F, 0.0F, 0.0F, 1.0F),
  )
  let entry = ExtractedSkybox::new(
    render_entity=@core.Entity::new(2, 1),
    skybox~,
    uniforms=SkyboxUniforms::from_skybox(skybox, 0.5F),
  )
  guard skybox_draw_params_from_extracted(entry) is Some(params) else {
    abort("expected skybox draw params")
  }

  debug_inspect(params.texture_id, content="11")
  debug_inspect(skybox_test_approx(params.brightness, 2.0F), content="true")
  debug_inspect(skybox_test_approx(params.rotation.x, -0.25F), content="true")
  debug_inspect(skybox_test_approx(params.rotation.w, 1.0F), content="true")
}

///|
test "skybox: embedded wgsl preserves Bevy sampling anchors" {
  debug_inspect(
    skybox_wgsl_source.contains(
      "@group(0) @binding(0) var skybox: texture_cube<f32>;",
    ),
    content="true",
  )
  debug_inspect(
    skybox_wgsl_source.contains(
      "@group(0) @binding(1) var skybox_sampler: sampler;",
    ),
    content="true",
  )
  debug_inspect(
    skybox_wgsl_source.contains(
      "@group(0) @binding(2) var<uniform> view: View;",
    ),
    content="true",
  )
  debug_inspect(
    skybox_wgsl_source.contains(
      "@group(0) @binding(3) var<uniform> uniforms: SkyboxUniforms;",
    ),
    content="true",
  )
  debug_inspect(
    skybox_wgsl_source.contains(
      "textureSample(skybox, skybox_sampler, ray_direction * vec3(1.0, 1.0, -1.0))",
    ),
    content="true",
  )
}

///|
test "skybox: pipeline descriptor matches Bevy layout and depth anchors" {
  let key = SkyboxPipelineKey::new(
    target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    samples=4,
    depth_format_raw=@wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
  )
  let descriptor = skybox_render_pipeline_descriptor(key)
  debug_inspect(descriptor.label(), content="Some(\"skybox_pipeline\")")
  debug_inspect(
    descriptor.vertex().shader(),
    content="Some(\"core_pipeline/skybox/skybox.wgsl\")",
  )
  debug_inspect(
    descriptor.vertex().entry_point(),
    content="Some(\"skybox_vertex\")",
  )
  guard descriptor.fragment() is Some(fragment) else {
    abort("expected skybox fragment state")
  }
  debug_inspect(
    fragment.shader(),
    content="Some(\"core_pipeline/skybox/skybox.wgsl\")",
  )
  debug_inspect(fragment.entry_point(), content="Some(\"skybox_fragment\")")
  let targets = fragment.targets()
  debug_inspect(targets.length(), content="1")
  guard targets[0] is Some(target) else {
    abort("expected skybox color target")
  }
  debug_inspect(
    target.format() == @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    content="true",
  )
  debug_inspect(target.blend() is None, content="true")
  debug_inspect(
    target.write_mask() == @wgpu.COLOR_WRITE_MASK_ALL,
    content="true",
  )

  let layouts = descriptor.layout()
  debug_inspect(layouts.length(), content="1")
  let entries = layouts[0].entries()
  debug_inspect(layouts[0].label(), content="\"skybox_bind_group_layout\"")
  debug_inspect(entries.length(), content="4")
  match entries[0].kind() {
    @render_resource.BindingType::TextureBinding(
      sample_type,
      view_dimension,
      multisampled
    ) => {
      let sample_type_ok = match sample_type {
        @render_resource.TextureSampleType::Float(filterable) => filterable
        _ => false
      }
      let view_dimension_ok = match view_dimension {
        @render_resource.TextureViewDimension::Cube => true
        _ => false
      }
      debug_inspect(sample_type_ok, content="true")
      debug_inspect(view_dimension_ok, content="true")
      debug_inspect(multisampled, content="false")
    }
    _ => abort("expected skybox cube texture binding")
  }
  match entries[1].kind() {
    @render_resource.BindingType::SamplerBinding(kind) => {
      let filtering = match kind {
        @render_resource.SamplerBindingType::Filtering => true
        _ => false
      }
      debug_inspect(filtering, content="true")
    }
    _ => abort("expected skybox filtering sampler")
  }
  match entries[2].kind() {
    @render_resource.BindingType::BufferBinding(
      kind,
      has_dynamic_offset,
      min_size
    ) => {
      let uniform = match kind {
        @render_resource.BufferBindingType::Uniform => true
        _ => false
      }
      debug_inspect(uniform, content="true")
      debug_inspect(has_dynamic_offset, content="true")
      debug_inspect(
        min_size == @render_view.VIEW_UNIFORM_SIZE_BYTES.to_uint64(),
        content="true",
      )
    }
    _ => abort("expected view uniform binding")
  }
  match entries[3].kind() {
    @render_resource.BindingType::BufferBinding(
      kind,
      has_dynamic_offset,
      min_size
    ) => {
      let uniform = match kind {
        @render_resource.BufferBindingType::Uniform => true
        _ => false
      }
      debug_inspect(uniform, content="true")
      debug_inspect(has_dynamic_offset, content="true")
      debug_inspect(min_size, content="80")
    }
    _ => abort("expected skybox uniform binding")
  }
  guard descriptor.depth_stencil is Some(depth) else {
    abort("expected skybox depth state")
  }
  debug_inspect(
    depth.format == @wgpu.TEXTURE_FORMAT_DEPTH32_FLOAT,
    content="true",
  )
  debug_inspect(depth.depth_write_enabled, content="false")
  debug_inspect(
    depth.depth_compare == @wgpu.COMPARE_FUNCTION_GREATER_EQUAL,
    content="true",
  )
  debug_inspect(descriptor.multisample.count(), content="4")
}

///|
test "skybox: prepare pipelines writes render-world view component" {
  let world = @ecs.World::new()
  defer world.close()
  let render_entity = world.spawn()
  try! world.set_by_key(
    render_entity,
    @render_view.ExtractedView::component(),
    @render_view.ExtractedView::new(
      @render_view.RetainedViewEntity::new(render_entity),
      target_format_raw=@wgpu.TEXTURE_FORMAT_RGBA16_FLOAT,
    ),
  )
  try! world.set_by_key(
    render_entity,
    @render_view.Msaa::component(),
    @render_view.Msaa::Sample4,
  )
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(17)
  let skybox = @light.Skybox::new(image, 1.0F)
  let extracted = ExtractedSkyboxes::ExtractedSkyboxes()
  extracted.push(
    ExtractedSkybox::new(
      render_entity~,
      skybox~,
      uniforms=SkyboxUniforms::from_skybox(skybox, 1.0F),
    ),
  )
  world.insert_resource(ExtractedSkyboxes::resource(), extracted)
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )

  prepare_skybox_pipelines(world)

  debug_inspect(view_has_skybox_pipeline(world, render_entity), content="true")
  guard (try! world.get_by_key(render_entity, ecs_key_skybox_pipeline_id))
    is Some(pipeline_id) else {
    abort("expected SkyboxPipelineId")
  }
  debug_inspect(pipeline_id.pipeline_id().id(), content="0")
  let pipeline_cache = world
    .get_resource(@render.pipeline_cache_resource_key)
    .unwrap()
  debug_inspect(pipeline_cache.queued_pipeline_count(), content="1")
}

///|
test "skybox: prepare pipelines requires Bevy render-view components" {
  let world = @ecs.World::new()
  defer world.close()
  let render_entity = world.spawn()
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(19)
  let skybox = @light.Skybox::new(image, 1.0F)
  let extracted = ExtractedSkyboxes::ExtractedSkyboxes()
  extracted.push(
    ExtractedSkybox::new(
      render_entity~,
      skybox~,
      uniforms=SkyboxUniforms::from_skybox(skybox, 1.0F),
    ),
  )
  world.insert_resource(ExtractedSkyboxes::resource(), extracted)
  world.insert_resource(
    @render.pipeline_cache_resource_key,
    @render_resource.PipelineCache::new(),
  )

  prepare_skybox_pipelines(world)

  debug_inspect(view_has_skybox_pipeline(world, render_entity), content="false")
  let pipeline_cache = world
    .get_resource(@render.pipeline_cache_resource_key)
    .unwrap()
  debug_inspect(pipeline_cache.queued_pipeline_count(), content="0")
}

///|
test "skybox: extract_skybox writes Bevy component and uniform payload to render entity" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(SkyboxPlugin::SkyboxPlugin())
  let source_world = app.world()
  let source_entity = source_world.spawn()
  let image : @asset.Handle[@asset.Image] = @asset.Handle::new(23)
  let skybox = @light.Skybox::new(image, 5.0F)
  try! source_world.set_by_key(
    source_entity,
    @render.SyncToRenderWorld::component(),
    @render.SyncToRenderWorld::SyncToRenderWorld(),
  )
  try! source_world.set_by_key(
    source_entity,
    @light.Skybox::component(),
    skybox,
  )
  try! source_world.set_by_key(
    source_entity,
    @camera_camera.Exposure::component(),
    @camera_camera.Exposure::from_physical_camera(
      @camera_camera.PhysicalCameraParameters::PhysicalCameraParameters(),
    ),
  )

  @render.mark_renderer_ready(app.sub_app(@app.RenderApp).world())
  let app = app.run_once()
  let source_world = app.world()
  let render_entity = (try! source_world.get_by_key(
      source_entity,
      @render.RenderEntity::component(),
    ))
    .unwrap()
    .id()
  let render_world = app.sub_app(@app.RenderApp).world()

  debug_inspect(
    (try! render_world.get_by_key(render_entity, @light.Skybox::component()))
    is Some(_),
    content="true",
  )
  guard (try! render_world.get_by_key(
      render_entity,
      SkyboxUniforms::component(),
    ))
    is Some(uniforms) else {
    abort("expected SkyboxUniforms on render entity")
  }
  debug_inspect(uniforms.is_ready_for_bind_group(), content="true")
  debug_inspect(
    skybox_test_approx(
      uniforms.brightness,
      5.0F *
      @camera_camera.Exposure::from_physical_camera(
        @camera_camera.PhysicalCameraParameters::PhysicalCameraParameters(),
      ).exposure(),
    ),
    content="true",
  )
}
