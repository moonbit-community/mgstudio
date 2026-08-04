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
// Bevy source: `bevy/crates/bevy_camera/src/lib.rs`.

///|
const CAMERA_PROJECTION_PLUGIN_NAME : String = "mgstudio.camera.CameraProjectionPlugin"

///|
const CAMERA_PLUGIN_NAME : String = "mgstudio.camera.CameraPlugin"

///|
// Bevy source: `bevy/crates/bevy_camera/src/camera.rs::CameraUpdateSystems`.
pub let camera_update_systems : @app.SystemSet = @camera_camera.camera_update_systems

///|
pub let camera_update_frusta_systems : @app.SystemSet = @camera_camera.camera_update_frusta_systems

///|
fn camera2d_frustum_render_transform(
  global_transform : @transform.GlobalTransform,
) -> @transform.Transform {
  let camera_transform = global_transform.to_transform_approx()
  let scale_x = if camera_transform.scale.x < 0.0F {
    -camera_transform.scale.x
  } else if camera_transform.scale.x == 0.0F {
    1.0F
  } else {
    camera_transform.scale.x
  }
  camera_transform.with_scale(
    @math.Vec3::new(scale_x, scale_x, camera_transform.scale.z),
  )
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs` registers
// `update_frusta::<Projection>` for the 3d projection component.
pub fn update_frusta_3d_system(world : @ecs.World) -> Unit {
  @camera_visibility.update_frusta(
    world,
    @camera_projection3d.ecs_key_projection,
    fn(projection, transform) { projection.compute_frustum(transform) },
  )
}

///|
// Bevy source: `bevy/crates/bevy_camera/src/visibility/mod.rs::update_frusta`.
// The current 2D projection surface is the WindowSize orthographic subset, so
// reuse the source-aligned orthographic implementation with the 2D defaults.
// Bevy feeds rendering and frustum extraction the same camera affine. The
// current native 2D backend uses absolute non-zero scale.x for both view axes,
// so the 2D frustum must apply that same transform convention before entering
// the shared 3D projection code.
pub fn update_frusta_2d_system(world : @ecs.World) -> Unit {
  let updates : Array[(@core.Entity, @camera_primitives.Frustum)] = []
  world.for_each_component(@camera_projection2d.ecs_key_projection, fn(
    entity,
    projection,
  ) {
    guard (try! world.get_by_key(entity, @camera_camera.ecs_key_camera))
      is Some(camera) else {
      return
    }
    guard camera.logical_viewport_size() is Some(logical_size) else { return }
    if logical_size.x <= 0.0F || logical_size.y <= 0.0F {
      return
    }
    guard (try! world.get_by_key(entity, @transform.ecs_key_global_transform))
      is Some(global_transform) else {
      return
    }
    let orthographic = match projection {
      Orthographic(value) => value
    }
    let projection_3d = @camera_projection3d.OrthographicProjection3d::default_2d()
      .with_scale(orthographic.scale)
      .update(logical_size.x, logical_size.y)
    let next = @camera_projection3d.render3d_orthographic_projection_compute_frustum(
      projection_3d,
      camera2d_frustum_render_transform(global_transform),
    )
    match (try! world.get_by_key(entity, @camera_primitives.ecs_key_frustum)) {
      Some(current) => if current != next { updates.push((entity, next)) }
      None => updates.push((entity, next))
    }
  })
  for update in updates {
    let (entity, frustum) = update
    if (try! world.get_by_key(entity, @camera_primitives.ecs_key_frustum))
      is Some(_) {
      try! (world.replace(entity, @camera_primitives.ecs_key_frustum, frustum)
      |> ignore)
    } else {
      try! world.set_by_key(entity, @camera_primitives.ecs_key_frustum, frustum)
    }
  }
}

///|
pub struct CameraProjectionPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn CameraProjectionPlugin::CameraProjectionPlugin() -> CameraProjectionPlugin {
  CameraProjectionPlugin::{  }
}

///|
pub impl @app.Plugin for CameraProjectionPlugin with fn name(_self) {
  CAMERA_PROJECTION_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CameraProjectionPlugin with fn build(_self, app) {
  camera_projection_plugin(app)
}

///|
pub struct CameraPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn CameraPlugin::CameraPlugin() -> CameraPlugin {
  CameraPlugin::{  }
}

///|
pub impl @app.Plugin for CameraPlugin with fn name(_self) {
  CAMERA_PLUGIN_NAME
}

///|
pub impl @app.Plugin for CameraPlugin with fn build(_self, app) {
  camera_plugin(app)
}

///|
pub fn camera_projection_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  app
  .configure_set(PostUpdate, camera_update_systems, after=[
    @transform.transform_set_propagate,
  ])
  .configure_set(PostUpdate, camera_update_frusta_systems, after=[
    camera_update_systems, @transform.transform_set_propagate,
  ])
  .add_post_update_system_config(
    @app.system(update_frusta_3d_system)
    .named("mgstudio.camera.update_frusta_3d")
    .in_set(camera_update_frusta_systems),
  )
  .add_post_update_system_config(
    @app.system(update_frusta_2d_system)
    .named("mgstudio.camera.update_frusta_2d")
    .in_set(camera_update_frusta_systems),
  )
}

///|
pub fn camera_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  let world = app.world()
  @camera_camera.ensure_camera_required_components(world)
  @camera_components2d.ensure_camera2d_required_components(world)
  world.register_required_components_with(
    ecs_key_camera3d,
    @post_process.ecs_key_color_grading,
    fn() { ColorGrading() },
  ) catch {
    DuplicateRegistration(_, _) => ()
    ArchetypeExists(component_id) =>
      abort(
        "CameraPlugin required-component registration ran too late for component \{component_id}",
      )
    CyclicRequirement(requiree, required) =>
      abort(
        "CameraPlugin required-component cycle detected: \{requiree} -> \{required}",
      )
  }
  world.register_required_components_with(
    ecs_key_camera3d,
    @camera_camera.ecs_key_exposure,
    fn() { Exposure() },
  ) catch {
    DuplicateRegistration(_, _) => ()
    ArchetypeExists(component_id) =>
      abort(
        "CameraPlugin required-component registration ran too late for component \{component_id}",
      )
    CyclicRequirement(requiree, required) =>
      abort(
        "CameraPlugin required-component cycle detected: \{requiree} -> \{required}",
      )
  }
  // Bevy source: `bevy_core_pipeline/src/core_3d/mod.rs` `Core3dPlugin::build`
  // requires `Tonemapping` (default TonyMcMapface) and `DebandDither::Enabled`
  // on every `Camera3d`.
  world.register_required_components_with(
    ecs_key_camera3d,
    @post_process.ecs_key_tonemapping,
    fn() { @post_process.Tonemapping::default() },
  ) catch {
    DuplicateRegistration(_, _) => ()
    ArchetypeExists(component_id) =>
      abort(
        "CameraPlugin required-component registration ran too late for component \{component_id}",
      )
    CyclicRequirement(requiree, required) =>
      abort(
        "CameraPlugin required-component cycle detected: \{requiree} -> \{required}",
      )
  }
  world.register_required_components_with(
    ecs_key_camera3d,
    @post_process.ecs_key_deband_dither,
    fn() { @post_process.DebandDither::Enabled },
  ) catch {
    DuplicateRegistration(_, _) => ()
    ArchetypeExists(component_id) =>
      abort(
        "CameraPlugin required-component registration ran too late for component \{component_id}",
      )
    CyclicRequirement(requiree, required) =>
      abort(
        "CameraPlugin required-component cycle detected: \{requiree} -> \{required}",
      )
  }
  app
  .init_resource(fn() { @camera_clear_color.ClearColor::ClearColor() })
  .add_plugins(CameraProjectionPlugin::CameraProjectionPlugin())
  .add_plugins(@camera_visibility.VisibilityPlugin::VisibilityPlugin())
  .add_plugins(
    @camera_visibility.VisibilityRangePlugin::VisibilityRangePlugin(),
  )
}
