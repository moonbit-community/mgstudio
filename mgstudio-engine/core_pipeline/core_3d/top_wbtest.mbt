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
test "core3d: graph systems run main pass before early postprocess" {
  let log : Array[String] = []
  let core_3d_stage = @app.schedule_label("mgstudio.core_pipeline.core_3d")
  let lifecycle_world_15_0 = @ecs.World::new()
  defer lifecycle_world_15_0.close()
  let render_sub_app = @app.SubApp::new(lifecycle_world_15_0).set_update_schedule(
    Some(core_3d_stage),
  )
  let render_sub_app = core_3d_configure_render_sub_app(render_sub_app)
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("prepass") }).in_set(
        core_3d_set_prepass,
      ),
    )
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("main") }).in_set(
        core_3d_set_main_pass,
      ),
    )
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("early_post") }).in_set(
        core_3d_set_early_post_process,
      ),
    )
    .add_systems(
      core_3d_stage,
      @app.system(fn(_world : @ecs.World) { log.push("post") }).in_set(
        core_3d_set_post_process,
      ),
    )

  ignore(render_sub_app.update())

  debug_inspect(log.join(","), content="\"prepass,main,early_post,post\"")
}

///|
test "core3d: main opaque pass skybox draw requires prepared skybox state" {
  let world = @ecs.World::new()
  defer world.close()
  let render_entity = @core.Entity::new(1, 1)

  debug_inspect(
    main_opaque_pass_3d_draw_skybox(world, render_entity),
    content="false",
  )
}

///|
fn transparent_test_item(
  render_entity : @core.Entity,
  main_entity : @core.Entity,
  pipeline_id : UInt64,
  distance? : Float = 0.0F,
) -> Transparent3d {
  Transparent3d::new(
    sorting_info=TransparentSortingInfo3d::sorted(
      mesh_center=@math.Vec3::new(1.0F, 2.0F, 3.0F),
    ),
    distance~,
    pipeline=@material.CachedRenderPipelineId::new(pipeline_id),
    entity=render_entity,
    main_entity=@render.MainEntity::new(main_entity),
    draw_function=@material.DrawFunctionId::new(7U),
    batch_range_end=1,
    indexed=true,
  )
}

///|
test "core3d: sorted transparent phases preserve stable items and expire transient items" {
  let world = @ecs.World::new()
  defer world.close()
  let retained_view = @render_view.RetainedViewEntity::new(world.spawn_empty())
  let stale_view = @render_view.RetainedViewEntity::new(world.spawn_empty())
  let stable_render_entity = world.spawn_empty()
  let stable_main_entity = world.spawn_empty()
  let transient_render_entity = world.spawn_empty()
  let transient_main_entity = world.spawn_empty()
  let phases = Transparent3dPhase::Transparent3dPhase()
  phases.prepare_for_new_frame(retained_view)
  phases.add(
    retained_view,
    transparent_test_item(stable_render_entity, stable_main_entity, 11UL),
  )
  phases.add_transient(
    retained_view,
    transparent_test_item(transient_render_entity, transient_main_entity, 12UL),
  )
  phases.prepare_for_new_frame(stale_view)
  debug_inspect(phases.view_count(), content="2")
  debug_inspect(phases.view(retained_view).unwrap().len(), content="2")

  phases.prepare_for_new_frame(retained_view)
  let retained_phase = phases.view(retained_view).unwrap()
  debug_inspect(retained_phase.len(), content="1")
  debug_inspect(retained_phase.items()[0].pipeline().id(), content="11")

  phases.add(
    retained_view,
    transparent_test_item(stable_render_entity, stable_main_entity, 13UL),
  )
  debug_inspect(retained_phase.len(), content="1")
  debug_inspect(retained_phase.items()[0].pipeline().id(), content="13")
  match retained_phase.items()[0].sorting_info() {
    Sorted(mesh_center, depth_bias) => {
      debug_inspect(mesh_center.x, content="1")
      debug_inspect(depth_bias, content="0")
    }
    AlwaysOnTop => abort("expected sorted transparent phase item")
  }

  phases.retain_views([retained_view])
  debug_inspect(phases.view_count(), content="1")
  debug_inspect(phases.view(stale_view) is None, content="true")
}

///|
test "core3d: phase resources live in RenderApp" {
  let lifecycle_world_134_0 = @ecs.World::new()
  defer lifecycle_world_134_0.close()
  let app = @app.App::new(lifecycle_world_134_0)
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(Core3dPlugin::Core3dPlugin())
  let render_world = app.get_sub_app(RenderApp).unwrap().world()
  debug_inspect(
    app.world().get_resource(Transparent3dPhase::resource()) is None,
    content="true",
  )
  debug_inspect(
    render_world.get_resource(Transparent3dPhase::resource()) is Some(_),
    content="true",
  )
  debug_inspect(
    render_world.get_resource(Transparent3dDrawFunctions::resource()) is Some(_),
    content="true",
  )
}

///|
test "core3d: active Camera3d prepares and retains transparent phase views" {
  let lifecycle_world_156_0 = @ecs.World::new()
  defer lifecycle_world_156_0.close()
  let mut app = @app.App::new(lifecycle_world_156_0)
    .add_plugins(@asset.AssetPlugin::AssetPlugin())
    .add_plugins(@shader.ShaderPlugin::ShaderPlugin())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(Core3dPlugin::Core3dPlugin())
  let camera_entity = app.world().spawn_empty()
  try! app
  .world()
  .set_by_key(camera_entity, @camera_components3d.ecs_key_camera3d, Camera3d())
  try! app
  .world()
  .set_by_key(camera_entity, @camera_camera.ecs_key_camera, Camera())
  app = app.update()
  let retained_view = @render_view.RetainedViewEntity::new(camera_entity)
  let phases = app
    .get_sub_app(RenderApp)
    .unwrap()
    .world()
    .get_resource(Transparent3dPhase::resource())
    .unwrap()
  debug_inspect(phases.view_count(), content="1")
  debug_inspect(phases.view(retained_view) is Some(_), content="true")

  try! app
  .world()
  .set_by_key(
    camera_entity,
    @camera_camera.ecs_key_camera,
    @camera_camera.Camera::Camera().with_is_active(false),
  )
  app = app.update()
  let phases = app
    .get_sub_app(RenderApp)
    .unwrap()
    .world()
    .get_resource(Transparent3dPhase::resource())
    .unwrap()
  debug_inspect(phases.view_count(), content="0")
}

///|
test "core3d: DrawFunctions<Transparent3d> executes the registered render command" {
  let world = @ecs.World::new()
  defer world.close()
  let draw_functions = Transparent3dDrawFunctions::Transparent3dDrawFunctions()
  let seen : Array[@core.Entity] = []
  let draw_function = draw_functions.register("DrawCustom", fn(_world, item) {
    seen.push(item.entity())
    Success
  })
  let entity = @core.Entity::new(17, 2)
  let item = Transparent3d::new(
    distance=0.0F,
    pipeline=@material.CachedRenderPipelineId::new(9UL),
    entity~,
    main_entity=@render.MainEntity::new(entity),
    draw_function~,
  )
  debug_inspect(draw_functions.len(), content="1")
  debug_inspect(draw_functions.render(world, item), content="Success")
  debug_inspect(seen.length(), content="1")
  debug_inspect(seen[0] == entity, content="true")
  let unknown = Transparent3d::new(
    distance=0.0F,
    pipeline=@material.CachedRenderPipelineId::new(9UL),
    entity~,
    main_entity=@render.MainEntity::new(entity),
    draw_function=@material.DrawFunctionId::new(99U),
  )
  debug_inspect(draw_functions.render(world, unknown), content="Skip")
}
