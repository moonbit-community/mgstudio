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
test "pbr: WireframeConfig can be accessed through ResMut" {
  let observed : Ref[Bool?] = Ref(None)
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(WireframeConfig::WireframeConfig())
    .add_system_param(fn(config : @app.ResMut[WireframeConfig]) {
      observed.val = Some(config.get().global)
      config.update(fn(value) { value.with_global(true) })
    })

  app.run_once() |> ignore

  debug_inspect(observed.val, content="Some(false)")
  debug_inspect(
    app
    .world()
    .get_resource(WireframeConfig::resource())
    .map(fn(config) { config.global }),
    content="Some(true)",
  )
}

///|
test "pbr: WireframeConfig carries Bevy line width and topology defaults" {
  let config = WireframeConfig::WireframeConfig()
  debug_inspect(config.global, content="false")
  debug_inspect(
    config.default_color.to_srgba_tuple() ==
    @color.Color::white().to_srgba_tuple(),
    content="true",
  )
  debug_inspect(config.default_line_width, content="1")
  debug_inspect(config.default_topology, content="Triangles")
  let custom = WireframeConfig::new(
    true,
    @color.Color::white(),
    default_line_width=3.0F,
    default_topology=Quads,
  )
  debug_inspect(custom.global, content="true")
  debug_inspect(custom.default_line_width, content="3")
  debug_inspect(custom.default_topology, content="Quads")
}

///|
test "pbr: WireframeMaterial is an asset-backed authoring material" {
  let material = WireframeMaterial::new(@color.Color::white(), 2.0F, Quads)
  let rendered = RenderWireframeMaterial::from_material(material)
  debug_inspect(
    rendered.color.to_srgba_tuple() == @color.Color::white().to_srgba_tuple(),
    content="true",
  )
  debug_inspect(rendered.line_width, content="2")
  debug_inspect(rendered.topology, content="Quads")
  let assets : @asset.Assets[WireframeMaterial] = @asset.Assets::new()
  let handle = assets.add(material)
  let component = Mesh3dWireframe::new(handle)
  debug_inspect(assets.contains(component.material()), content="true")
}

///|
test "pbr: WireframePlugin initializes config and specialization resources" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    WireframePlugin::WireframePlugin(),
  )
  app.run_startup() |> ignore
  debug_inspect(
    app.world().resource(ecs_key_wireframe_config).is_present(),
    content="true",
  )
  debug_inspect(
    app
    .world()
    .resource(ecs_key_wireframe_entities_needing_specialization)
    .is_present(),
    content="true",
  )
  let asset_key : @ecs.ResourceKey[@asset.Assets[WireframeMaterial]] = @asset.assets_resource_key()
  debug_inspect(app.world().resource(asset_key).is_present(), content="true")
}

///|
fn wireframe_material_assets(
  world : @ecs.World,
) -> @asset.Assets[WireframeMaterial] {
  let asset_key : @ecs.ResourceKey[@asset.Assets[WireframeMaterial]] = @asset.assets_resource_key()
  match world.get_resource(asset_key) {
    Some(assets) => assets
    None => abort("missing WireframeMaterial assets")
  }
}

///|
fn wireframe_material_for_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> WireframeMaterial {
  let component = match
    (try! world.get_by_key(entity, ecs_key_mesh3d_wireframe)) {
    Some(component) => component
    None => abort("missing Mesh3dWireframe")
  }
  match wireframe_material_assets(world).get(component.material()) {
    Some(material) => material
    None => abort("missing WireframeMaterial")
  }
}

///|
test "pbr: WireframePlugin applies explicit wireframe material in PostUpdate" {
  let app = @app.App::new(@ecs.World::new()).add_plugins(
    WireframePlugin::WireframePlugin(),
  )
  app.run_startup() |> ignore
  let entity = app.world().spawn()
  try! app.world().set_by_key(entity, ecs_key_wireframe, Wireframe::Wireframe())
  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_wireframe_color,
    WireframeColor::new(@color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F)),
  )
  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_wireframe_line_width,
    WireframeLineWidth::new(4.0F),
  )
  try! app.world().set_by_key(entity, ecs_key_wireframe_topology, Quads)

  app.run_once() |> ignore

  let material = wireframe_material_for_entity(app.world(), entity)
  debug_inspect(
    material.color.to_srgba_tuple() ==
    @color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F).to_srgba_tuple(),
    content="true",
  )
  debug_inspect(material.line_width, content="4")
  debug_inspect(material.topology, content="Quads")
}

///|
test "pbr: WireframePlugin applies global wireframe material to Mesh3d entities" {
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(
      WireframeConfig::new(
        true,
        @color.Color::srgba(0.0F, 1.0F, 0.0F, 1.0F),
        default_line_width=2.0F,
        default_topology=Triangles,
      ),
    )
    .add_plugins(WireframePlugin::WireframePlugin())
  app.run_startup() |> ignore
  let entity = app.world().spawn()
  try! app
  .world()
  .set_by_key(entity, ecs_key_mesh3d, @mesh.Mesh3d::new(@asset.Handle::new(7)))

  app.run_once() |> ignore

  let material = wireframe_material_for_entity(app.world(), entity)
  debug_inspect(
    material.color.to_srgba_tuple() ==
    @color.Color::srgba(0.0F, 1.0F, 0.0F, 1.0F).to_srgba_tuple(),
    content="true",
  )
  debug_inspect(material.line_width, content="2")
  debug_inspect(material.topology, content="Triangles")
  debug_inspect(wireframe_material_assets(app.world()).len(), content="1")
}

///|
test "pbr: WireframePlugin removes Mesh3dWireframe for NoWireframe entities" {
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(
      WireframeConfig::new(
        true,
        @color.Color::white(),
        default_line_width=1.0F,
        default_topology=Triangles,
      ),
    )
    .add_plugins(WireframePlugin::WireframePlugin())
  app.run_startup() |> ignore
  let entity = app.world().spawn()
  try! app
  .world()
  .set_by_key(entity, ecs_key_mesh3d, @mesh.Mesh3d::new(@asset.Handle::new(8)))
  app.run_once() |> ignore
  debug_inspect(
    try! (app.world().get_by_key(entity, ecs_key_mesh3d_wireframe) is Some(_)),
    content="true",
  )

  try! app
  .world()
  .set_by_key(entity, ecs_key_no_wireframe, NoWireframe::NoWireframe())
  app.run_once() |> ignore

  debug_inspect(
    try! (app.world().get_by_key(entity, ecs_key_mesh3d_wireframe) is None),
    content="true",
  )
}

///|
test "pbr: WireframePlugin refreshes global material when config changes" {
  let frame = Ref(0)
  let app = @app.App::new(@ecs.World::new())
    .insert_resource(
      WireframeConfig::new(
        true,
        @color.Color::srgba(0.0F, 1.0F, 0.0F, 1.0F),
        default_line_width=2.0F,
        default_topology=Triangles,
      ),
    )
    .add_plugins(WireframePlugin::WireframePlugin())
    .add_systems_world(@app.Update, fn(world) {
      if frame.val == 1 {
        world
        .get_resource_mut(WireframeConfig::resource())
        .unwrap()
        .set(
          WireframeConfig::new(
            true,
            @color.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F),
            default_line_width=5.0F,
            default_topology=Quads,
          ),
        )
      }
      frame.val = frame.val + 1
    })
  app.run_startup() |> ignore
  let entity = app.world().spawn()
  try! app
  .world()
  .set_by_key(entity, ecs_key_mesh3d, @mesh.Mesh3d::new(@asset.Handle::new(9)))
  app.run_once() |> ignore
  app.run_once() |> ignore

  let material = wireframe_material_for_entity(app.world(), entity)
  debug_inspect(
    material.color.to_srgba_tuple() ==
    @color.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F).to_srgba_tuple(),
    content="true",
  )
  debug_inspect(material.line_width, content="5")
  debug_inspect(material.topology, content="Quads")
  debug_inspect(wireframe_material_assets(app.world()).len(), content="1")
}

///|
test "pbr: WireframePlugin refreshes explicit material when color changes" {
  let frame = Ref(0)
  let target : Ref[@core.Entity?] = Ref(None)
  let updated_seen = Ref(false)
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(WireframePlugin::WireframePlugin())
    .add_systems_world(@app.Update, fn(world) {
      if frame.val == 1 {
        if target.val is Some(entity) {
          let updated = world.update_by_key(entity, ecs_key_wireframe_color, fn(
            _value,
          ) {
            WireframeColor::new(@color.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F))
          }) catch {
            _ => false
          }
          updated_seen.val = updated
        }
      }
      frame.val = frame.val + 1
    })
  app.run_startup() |> ignore
  let entity = app.world().spawn()
  target.val = Some(entity)
  try! app.world().set_by_key(entity, ecs_key_wireframe, Wireframe::Wireframe())
  try! app
  .world()
  .set_by_key(
    entity,
    ecs_key_wireframe_color,
    WireframeColor::new(@color.Color::srgba(1.0F, 0.0F, 0.0F, 1.0F)),
  )
  app.run_once() |> ignore
  app.run_once() |> ignore

  debug_inspect(updated_seen.val, content="true")
  let material = wireframe_material_for_entity(app.world(), entity)
  debug_inspect(
    material.color.to_srgba_tuple() ==
    @color.Color::srgba(0.0F, 0.0F, 1.0F, 1.0F).to_srgba_tuple(),
    content="true",
  )
}

///|
test "pbr: WireframePlugin removes internal material when Wireframe is removed" {
  let frame = Ref(0)
  let target : Ref[@core.Entity?] = Ref(None)
  let removed_seen = Ref(false)
  let app = @app.App::new(@ecs.World::new())
    .add_plugins(WireframePlugin::WireframePlugin())
    .add_systems_world(@app.Update, fn(world) {
      if frame.val == 1 {
        if target.val is Some(entity) {
          let removed = world.remove_by_key(entity, ecs_key_wireframe) catch {
            _ => false
          }
          removed_seen.val = removed
        }
      }
      frame.val = frame.val + 1
    })
  app.run_startup() |> ignore
  let entity = app.world().spawn()
  target.val = Some(entity)
  try! app.world().set_by_key(entity, ecs_key_wireframe, Wireframe::Wireframe())
  app.run_once() |> ignore
  debug_inspect(
    try! (app.world().get_by_key(entity, ecs_key_mesh3d_wireframe) is Some(_)),
    content="true",
  )

  app.run_once() |> ignore

  debug_inspect(removed_seen.val, content="true")
  debug_inspect(
    try! (app.world().get_by_key(entity, ecs_key_mesh3d_wireframe) is None),
    content="true",
  )
}

///|
test "pbr: WireframePlugin initializes Bevy-shaped render-world resources" {
  let initial_render_world = @ecs.World::new()
  defer initial_render_world.close()
  initial_render_world.insert_resource(
    @render_mesh.MeshAllocatorSettings::resource(),
    @render_mesh.MeshAllocatorSettings::MeshAllocatorSettings(),
  )
  let app = @app.App::new(@ecs.World::new()).insert_sub_app(
    @app.RenderApp,
    @app.SubApp::new(initial_render_world).set_update_schedule(Some(@app.Main)),
  )
  let app = wireframe_plugin(app)
  let render_world = match app.get_sub_app(@app.RenderApp) {
    Some(sub_app) => sub_app.world()
    None => abort("missing RenderApp")
  }

  debug_inspect(
    render_world.get_resource(Wireframe3dPipeline::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(SpecializedWireframePipelineCache::resource())
    is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(SpecializedWireframeMeshPipelines::resource())
    is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(RenderWireframeInstances::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(RenderWireframeAssets::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(WireframeWideBindGroups::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(PendingWireframeQueues::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(DirtyWireframeSpecializations::resource())
    is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(Wireframe3dPhases::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(Wireframe3dBatchedInstanceBuffer::resource())
    is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(
      Wireframe3dPhaseBatchedInstanceBuffers::resource(),
    )
    is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(
      Wireframe3dPhaseIndirectParametersBuffers::resource(),
    )
    is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(WireframeViewKeyCache::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(@render_mesh.MeshAllocator::resource()) is None,
    content="true",
  )
  debug_inspect(
    render_world
    .get_resource(@render_mesh.MeshAllocatorSettings::resource())
    .map(fn(settings) {
      (settings.extra_buffer_usages() & @wgpu.BUFFER_USAGE_STORAGE) != 0UL
    }),
    content="Some(true)",
  )
  debug_inspect(
    render_world
    .get_resource(Wireframe3dDrawFunctions::resource())
    .map(fn(value) { value.len() }),
    content="Some(2)",
  )
  let settings = @app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
      name : String,
    ) {
      name.has_prefix("mgstudio_pbr::")
    },
  )
  let render_dot = app
    .sub_app(@app.RenderApp)
    .schedule_graph_dot(@render.render_schedule_stage(), settings~)
  debug_inspect(
    render_dot.contains("\"mgstudio_pbr::prepare_wireframe_3d_phase_buffers\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains("\"mgstudio_pbr::collect_wireframe_3d_phase_buffers\""),
    content="true",
  )
  debug_inspect(
    render_dot.contains(
      "\"mgstudio_pbr::prepare_wireframe_3d_phase_buffers\" -> \"mgstudio_pbr::collect_wireframe_3d_phase_buffers\"",
    ),
    content="true",
  )
}
