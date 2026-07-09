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
fn atmosphere_top_approx_eq(lhs : Float, rhs : Float) -> Bool {
  (lhs - rhs).abs() < 0.0001F
}

///|
fn atmosphere_top_spawn_atmosphere(
  world : @ecs.World,
  x : Float,
  inner_radius : Float,
  handle_id : Int,
) -> @core.Entity {
  let entity = world.spawn()
  let atmosphere = @light.Atmosphere::earth(@asset.Handle::new(handle_id)).with_radii(
    inner_radius,
    inner_radius + 1.0F,
  )
  try! world.set_by_key(entity, @light.ecs_key_atmosphere, atmosphere)
  try! world.set_by_key(
    entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(x, 0.0F, 0.0F),
    ),
  )
  entity
}

///|
fn atmosphere_top_spawn_camera(
  source_world : @ecs.World,
  render_world : @ecs.World,
  x : Float,
) -> (@core.Entity, @core.Entity) {
  let source_entity = source_world.spawn()
  let render_entity = render_world.spawn()
  try! source_world.set_by_key(
    source_entity,
    @render.ecs_key_render_entity,
    @render.RenderEntity::new(render_entity),
  )
  try! source_world.set_by_key(
    source_entity,
    @camera_components3d.ecs_key_camera3d,
    @camera_components3d.Camera3d::Camera3d(),
  )
  try! source_world.set_by_key(
    source_entity,
    @light.ecs_key_atmosphere_settings,
    @light.AtmosphereSettings::AtmosphereSettings().with_sky_max_samples(23),
  )
  try! source_world.set_by_key(
    source_entity,
    @transform.ecs_key_global_transform,
    @transform.GlobalTransform::from_transform(
      @transform.Transform::from_xyz(x, 0.0F, 0.0F),
    ),
  )
  (source_entity, render_entity)
}

///|
test "pbr atmosphere: extract_atmosphere writes nearest Bevy atmosphere to render camera" {
  let source_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  ignore(atmosphere_top_spawn_atmosphere(source_world, -10.0F, 3.0F, 10))
  ignore(atmosphere_top_spawn_atmosphere(source_world, 2.0F, 7.0F, 11))
  let (_source_entity, render_entity) = atmosphere_top_spawn_camera(
    source_world, render_world, 1.0F,
  )

  extract_atmosphere_from_worlds(source_world, render_world)

  let extracted = (try! render_world.get_by_key(
    render_entity, ecs_key_extracted_atmosphere,
  )).unwrap()
  inspect(
    atmosphere_top_approx_eq(extracted.inner_radius, 7.0F),
    content="true",
  )
  let (_scale, _rotation, translation) = extracted.world_to_atmosphere.to_scale_rotation_translation()
  inspect(atmosphere_top_approx_eq(translation.x, -2.0F), content="true")
  let gpu_settings = (try! render_world.get_by_key(
    render_entity,
    GpuAtmosphereSettings::component(),
  )).unwrap()
  inspect(gpu_settings.sky_max_samples, content="23")

  prepare_atmosphere_uniforms(render_world)

  let gpu_atmosphere = (try! render_world.get_by_key(
    render_entity,
    GpuAtmosphere::component(),
  )).unwrap()
  inspect(
    atmosphere_top_approx_eq(gpu_atmosphere.inner_radius, 7.0F),
    content="true",
  )
}

///|
test "pbr atmosphere: extract_atmosphere removes stale render payload when scene has no atmosphere" {
  let source_world = @ecs.World::new()
  let render_world = @ecs.World::new()
  let (_source_entity, render_entity) = atmosphere_top_spawn_camera(
    source_world, render_world, 1.0F,
  )
  let atmosphere_entity = atmosphere_top_spawn_atmosphere(
    source_world, 0.0F, 3.0F, 12,
  )
  extract_atmosphere_from_worlds(source_world, render_world)
  inspect(
    (try! render_world.get_by_key(render_entity, ecs_key_extracted_atmosphere))
    is Some(_),
    content="true",
  )
  try! (source_world.take(atmosphere_entity, @light.ecs_key_atmosphere)
  |> ignore)

  extract_atmosphere_from_worlds(source_world, render_world)

  inspect(
    (try! render_world.get_by_key(render_entity, ecs_key_extracted_atmosphere))
    is None,
    content="true",
  )
  inspect(
    (try! render_world.get_by_key(
      render_entity,
      GpuAtmosphereSettings::component(),
    ))
    is None,
    content="true",
  )
}

///|
test "pbr atmosphere: plugin installs Bevy-shaped build systems" {
  let app_before_finish = @app.App::new(@ecs.World::new())
    .add_plugins(@render.RenderPlugin::RenderPlugin())
    .add_plugins(AtmospherePlugin::AtmospherePlugin())
  let update_settings = @app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
      name : String,
    ) {
      name.has_prefix("mgstudio_pbr::atmosphere::")
    },
  )
  let update_dot = app_before_finish.schedule_graph_dot(
    @app.Update,
    settings=update_settings,
  )
  inspect(
    update_dot.contains(
      "\"mgstudio_pbr::atmosphere::prepare_atmosphere_probe_components\"",
    ),
    content="true",
  )
  let render_extract_dot = app_before_finish
    .sub_app(@app.RenderApp)
    .schedule_graph_dot(
      @render.render_extract_schedule_stage(),
      settings=update_settings,
    )
  inspect(
    render_extract_dot.contains(
      "\"mgstudio_pbr::atmosphere::extract_atmosphere\"",
    ),
    content="true",
  )
  let render_settings = @app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
      name : String,
    ) {
      name.has_prefix("mgstudio_render::uniform::")
    },
  )
  let render_dot = app_before_finish
    .sub_app(@app.RenderApp)
    .schedule_graph_dot(
      @render.render_schedule_stage(),
      settings=render_settings,
    )
  inspect(
    render_dot.contains(
      "\"mgstudio_render::uniform::prepare_uniform_components<mgstudio_pbr::GpuAtmosphere>\"",
    ),
    content="true",
  )
  inspect(
    render_dot.contains(
      "\"mgstudio_render::uniform::prepare_uniform_components<mgstudio_pbr::GpuAtmosphereSettings>\"",
    ),
    content="true",
  )
  let app = app_before_finish.finish()
  let finish_settings = @app.ScheduleGraphSettings::ScheduleGraphSettings().with_include_system_name(fn(
      name : String,
    ) {
      name.has_prefix("mgstudio_pbr::atmosphere::prepare_")
    },
  )
  let finish_dot = app
    .sub_app(@app.RenderApp)
    .schedule_graph_dot(
      @render.render_schedule_stage(),
      settings=finish_settings,
    )
  inspect(
    finish_dot.contains(
      "\"mgstudio_pbr::atmosphere::prepare_atmosphere_uniforms\"",
    ),
    content="true",
  )
}
