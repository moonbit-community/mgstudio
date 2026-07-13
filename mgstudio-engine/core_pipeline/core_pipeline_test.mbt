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
test "core_pipeline boundary re-exports prepass markers and msaa" {
  let depth = @core_pipeline.DepthPrepass::DepthPrepass()
  let normal = @core_pipeline.NormalPrepass::NormalPrepass()
  let motion = @core_pipeline.MotionVectorPrepass::MotionVectorPrepass()
  let deferred = @core_pipeline.DeferredPrepass::DeferredPrepass()
  let hdr = @core_pipeline.Hdr::Hdr()
  debug_inspect(depth.to_json(), content="Object({})")
  debug_inspect(normal.to_json(), content="Object({})")
  debug_inspect(motion.to_json(), content="Object({})")
  debug_inspect(deferred.to_json(), content="Object({})")
  debug_inspect(hdr.to_json(), content="Object({})")
  debug_inspect(@core_pipeline.Msaa::from_samples(4).samples(), content="4")
}

///|
test "mip_generation plugin initializes downsample shader registry resource" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@mip_generation.MipGenerationPlugin::MipGenerationPlugin())
  app = app.update()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let shaders = render_world
    .get_resource(@mip_generation.ecs_key_downsample_shaders)
    .unwrap()
  debug_inspect(shaders.depth().id() >= 0, content="true")
  debug_inspect(shaders.general_shader_count(), content="40")
  let rgba8 = shaders.general_shader("Rgba8Unorm").unwrap()
  debug_inspect(rgba8.id() >= 0, content="true")
  let shader_assets_key : @ecs.ResourceKey[@asset.Assets[@shader.Shader]] = @asset.assets_resource_key()
  let shader_assets = app.world().get_resource(shader_assets_key).unwrap()
  debug_inspect(shader_assets.contains(shaders.depth()), content="true")
  debug_inspect(shader_assets.contains(rgba8), content="true")
}

///|
test "mip_generation dynamic shaders keep AssetServer shader handles in sync" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@mip_generation.MipGenerationPlugin::MipGenerationPlugin())
  let asset_server = app
    .world()
    .get_resource(@asset.AssetServer::resource())
    .unwrap()
  let custom_handle : @asset.Handle[@shader.Shader] = @asset.asset_with_world(
    app.world(),
    fn() { asset_server.load("shaders/custom_material_2d.wgsl") },
  )
  app = app.update()
  app = app.update()
  let shader_assets_key : @ecs.ResourceKey[@asset.Assets[@shader.Shader]] = @asset.assets_resource_key()
  let shader_assets = app.world().get_resource(shader_assets_key).unwrap()
  let custom_shader = shader_assets.get(custom_handle).unwrap()
  debug_inspect(
    custom_shader.path,
    content="\"shaders/custom_material_2d.wgsl\"",
  )
}

///|
test "mip_generation texture format table follows bevy list shape" {
  let formats = @mip_generation.downsample_texture_formats()
  debug_inspect(formats.length(), content="40")
  debug_inspect(formats[0], content="(\"Rgba8Unorm\", \"rgba8unorm\")")
  debug_inspect(
    formats[formats.length() - 1],
    content="(\"Rg11b10Ufloat\", \"rg11b10ufloat\")",
  )
}

///|
test "mip_generation plugin initializes finish-stage resources in render sub-app" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@mip_generation.MipGenerationPlugin::MipGenerationPlugin())
    .finish()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let resources = render_world
    .get_resource(@mip_generation.ecs_key_mip_generation_resources)
    .unwrap()
  debug_inspect(resources.sampler_label(), content="\"mip generation sampler\"")
  debug_inspect(resources.mag_filter(), content="\"Linear\"")
  debug_inspect(resources.min_filter(), content="\"Linear\"")
  debug_inspect(resources.mipmap_filter(), content="\"Nearest\"")
}

///|
test "core_2d plugin initializes phase resources in render sub-app only" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
  let main_world = app.world()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  debug_inspect(
    main_world.get_resource(@core_2d.ecs_key_opaque2d_phase) is Some(_),
    content="false",
  )
  debug_inspect(
    main_world.get_resource(@core_2d.ecs_key_alpha_mask2d_phase) is Some(_),
    content="false",
  )
  debug_inspect(
    main_world.get_resource(@core_2d.ecs_key_transparent2d_phase) is Some(_),
    content="false",
  )
  let opaque_phase = render_world
    .get_resource(@core_2d.ecs_key_opaque2d_phase)
    .unwrap()
  let alpha_mask = render_world
    .get_resource(@core_2d.ecs_key_alpha_mask2d_phase)
    .unwrap()
  let transparent = render_world
    .get_resource(@core_2d.ecs_key_transparent2d_phase)
    .unwrap()
  debug_inspect(opaque_phase.is_empty(), content="true")
  debug_inspect(alpha_mask.is_empty(), content="true")
  debug_inspect(transparent.is_empty(), content="true")
}

///|
test "core_2d extracts active Camera2d phase views and retains live views" {
  let mut app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
  let world = app.world()
  let camera_entity = world.spawn_empty()
  try! world.set_by_key(
    camera_entity,
    @camera_components2d.ecs_key_camera2d,
    @camera_components2d.Camera2d::Camera2d(),
  )
  try! world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera(),
  )
  app = app.update()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let retained_view = @render_view.RetainedViewEntity::new(camera_entity)
  let opaque_phase = render_world
    .get_resource(@core_2d.ecs_key_opaque2d_phase)
    .unwrap()
  let alpha_mask_phase = render_world
    .get_resource(@core_2d.ecs_key_alpha_mask2d_phase)
    .unwrap()
  let transparent_phase = render_world
    .get_resource(@core_2d.ecs_key_transparent2d_phase)
    .unwrap()
  debug_inspect(opaque_phase.view_count(), content="1")
  debug_inspect(alpha_mask_phase.view_count(), content="1")
  debug_inspect(transparent_phase.view_count(), content="1")
  debug_inspect(opaque_phase.contains_view(retained_view), content="true")
  debug_inspect(alpha_mask_phase.contains_view(retained_view), content="true")
  debug_inspect(transparent_phase.contains_view(retained_view), content="true")

  let world = app.world()
  try! world.set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )
  app = app.update()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let opaque_phase = render_world
    .get_resource(@core_2d.ecs_key_opaque2d_phase)
    .unwrap()
  let alpha_mask_phase = render_world
    .get_resource(@core_2d.ecs_key_alpha_mask2d_phase)
    .unwrap()
  let transparent_phase = render_world
    .get_resource(@core_2d.ecs_key_transparent2d_phase)
    .unwrap()
  debug_inspect(opaque_phase.view_count(), content="0")
  debug_inspect(alpha_mask_phase.view_count(), content="0")
  debug_inspect(transparent_phase.view_count(), content="0")
}

///|
test "core_2d phase resources store items per retained view" {
  let world = @ecs.World::new()
  defer world.close()
  let view_a = @render_view.RetainedViewEntity::new(world.spawn_empty())
  let view_b = @render_view.RetainedViewEntity::new(world.spawn_empty())

  let opaque_phase = @core_2d.Opaque2dPhase::Opaque2dPhase()
  opaque_phase.prepare_for_new_frame(view_a)
  opaque_phase.prepare_for_new_frame(view_b)
  opaque_phase.push_for_view(
    view_a,
    @core_2d.Opaque2d::new(
      @core_2d.BatchSetKey2d::new(),
      @core_2d.Opaque2dBinKey::new(
        pipeline_id=11,
        draw_function_id=12,
        asset_id=13,
      ),
      representative_entity_id=14,
      main_entity_id=15,
    ),
  )
  opaque_phase.push_for_view(
    view_b,
    @core_2d.Opaque2d::new(
      @core_2d.BatchSetKey2d::new(indexed=true),
      @core_2d.Opaque2dBinKey::new(
        pipeline_id=21,
        draw_function_id=22,
        asset_id=23,
      ),
      representative_entity_id=24,
      main_entity_id=25,
    ),
  )
  debug_inspect(opaque_phase.view_count(), content="2")
  debug_inspect(opaque_phase.len(), content="2")
  debug_inspect(opaque_phase.len_for_view(view_a), content="1")
  debug_inspect(opaque_phase.len_for_view(view_b), content="1")
  debug_inspect(
    opaque_phase.items_for_view(view_b)[0].cached_pipeline_id(),
    content="21",
  )
  opaque_phase.prepare_for_new_frame(view_a)
  debug_inspect(opaque_phase.len_for_view(view_a), content="0")
  debug_inspect(opaque_phase.len_for_view(view_b), content="1")
  opaque_phase.retain_views([view_b])
  debug_inspect(opaque_phase.contains_view(view_a), content="false")
  debug_inspect(opaque_phase.contains_view(view_b), content="true")
  debug_inspect(opaque_phase.len(), content="1")

  let alpha_mask = @core_2d.AlphaMask2dPhase::AlphaMask2dPhase()
  alpha_mask.prepare_for_new_frame(view_a)
  alpha_mask.prepare_for_new_frame(view_b)
  alpha_mask.push_for_view(
    view_a,
    @core_2d.AlphaMask2d::new(
      @core_2d.BatchSetKey2d::new(),
      @core_2d.AlphaMask2dBinKey::new(
        pipeline_id=31,
        draw_function_id=32,
        asset_id=33,
      ),
      representative_entity_id=34,
      main_entity_id=35,
    ),
  )
  alpha_mask.push_for_view(
    view_b,
    @core_2d.AlphaMask2d::new(
      @core_2d.BatchSetKey2d::new(indexed=true),
      @core_2d.AlphaMask2dBinKey::new(
        pipeline_id=41,
        draw_function_id=42,
        asset_id=43,
      ),
      representative_entity_id=44,
      main_entity_id=45,
    ),
  )
  debug_inspect(alpha_mask.len(), content="2")
  alpha_mask.prepare_for_new_frame(view_a)
  debug_inspect(alpha_mask.len_for_view(view_a), content="0")
  debug_inspect(alpha_mask.len_for_view(view_b), content="1")
  alpha_mask.retain_views([view_b])
  debug_inspect(alpha_mask.contains_view(view_a), content="false")
  debug_inspect(alpha_mask.contains_view(view_b), content="true")
  debug_inspect(
    alpha_mask.items_for_view(view_b)[0].cached_pipeline_id(),
    content="41",
  )

  let transparent = @core_2d.Transparent2dPhase::Transparent2dPhase()
  transparent.prepare_for_new_frame(view_a)
  transparent.prepare_for_new_frame(view_b)
  transparent.push_for_view(
    view_a,
    @core_2d.Transparent2d::new(
      sort_key=3.0,
      entity_id=51,
      main_entity_id=52,
      pipeline_id=53,
      draw_function_id=54,
    ),
  )
  transparent.push_for_view(
    view_b,
    @core_2d.Transparent2d::new(
      sort_key=4.0,
      entity_id=61,
      main_entity_id=62,
      pipeline_id=63,
      draw_function_id=64,
      indexed=true,
    ),
  )
  debug_inspect(transparent.len(), content="2")
  transparent.prepare_for_new_frame(view_a)
  debug_inspect(transparent.len_for_view(view_a), content="0")
  debug_inspect(transparent.len_for_view(view_b), content="1")
  transparent.retain_views([view_b])
  debug_inspect(transparent.contains_view(view_a), content="false")
  debug_inspect(transparent.contains_view(view_b), content="true")
  debug_inspect(
    transparent.items_for_view(view_b)[0].is_indexed(),
    content="true",
  )
}

///|
test "core_2d plugin owns Camera2d post-process required components" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
  let world = app.world()
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @camera_components2d.ecs_key_camera2d,
    @camera_components2d.Camera2d::Camera2d(),
  )
  let tonemapping_ok = match
    (try! world.get_by_key(entity, @core_2d.ecs_key_tonemapping)) {
    Some(@core_2d.Tonemapping::None) => true
    _ => false
  }
  let deband_ok = match
    (try! world.get_by_key(entity, @core_2d.ecs_key_deband_dither)) {
    Some(@core_2d.DebandDither::Disabled) => true
    _ => false
  }
  debug_inspect(tonemapping_ok, content="true")
  debug_inspect(deband_ok, content="true")
  let graph_ok = match
    (try! world.get_by_key(entity, @render.ecs_key_camera_render_graph)) {
    Some(graph) =>
      graph.schedule() == @app.schedule_label("mgstudio.core_pipeline.core_2d")
    None => false
  }
  debug_inspect(graph_ok, content="true")
}

///|
priv struct CameraDriverScheduleProbe {
  mut run_count : Int
  mut current_view_bits : UInt64
}

///|
let camera_driver_schedule_probe_key : @ecs.ResourceKey[
  CameraDriverScheduleProbe,
] = @ecs.register_resource(
  debug_name="core_pipeline.test.camera_driver_schedule_probe",
)

///|
fn camera_driver_probe_tick(world : @ecs.World) -> Unit {
  guard world.resource(camera_driver_schedule_probe_key).get() is Some(probe) else {
    return
  }
  probe.run_count = probe.run_count + 1
  if world.get_resource(@render.current_view_resource_key) is Some(current_view) {
    probe.current_view_bits = current_view.entity().to_bits()
  }
}

///|
test "camera_driver runs each sorted camera's render schedule with CurrentView" {
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(@core_pipeline.CorePipelinePlugin::CorePipelinePlugin())
  ignore(
    app.modify_sub_app(@app.RenderApp, fn(render_sub_app) {
      let render_world = render_sub_app.world()
      render_world.insert_resource(camera_driver_schedule_probe_key, CameraDriverScheduleProbe::{
        run_count: 0,
        current_view_bits: 0UL,
      })
      let camera = render_world.spawn_empty()
      try! render_world.set_by_key(
        camera,
        @render.ecs_key_camera_render_graph,
        @render.CameraRenderGraph::new(@core_pipeline.Core2d::schedule()),
      )
      render_world.insert_resource(
        @render.SortedCameras::resource(),
        @render.SortedCameras::from_array([
          @render.SortedCamera::new(
            camera,
            0,
            None,
            false,
            @render.CameraOutputMode::Write,
          ),
        ]),
      )
      render_sub_app.add_systems(
        @core_pipeline.Core2d::schedule(),
        @app.system(camera_driver_probe_tick),
      )
    }),
  )
  let app = app.update()
  let render_world = app.get_sub_app(@app.RenderApp).unwrap().world()
  let probe = render_world
    .get_resource(camera_driver_schedule_probe_key)
    .unwrap()
  debug_inspect(probe.run_count, content="1")
  debug_inspect(probe.current_view_bits > 0UL, content="true")
  debug_inspect(
    render_world.get_resource(@render.current_view_resource_key) is None,
    content="true",
  )
}
