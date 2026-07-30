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
extend CameraBundleCustomProjection3d with @camera_projection3d.CameraProjection3d::{
  get_clip_from_view,
}

///|
fn camera_bundle_projection_approx_eq(a : Float, b : Float) -> Bool {
  let delta = a - b
  if delta < 0.0F {
    -delta < 0.0001F
  } else {
    delta < 0.0001F
  }
}

///|
struct CameraBundleCustomProjection3d {
  marker : Float
}

///|
impl @camera_projection3d.CameraProjection3d for CameraBundleCustomProjection3d with fn get_clip_from_view(
  self,
) {
  ProjectionMatrix3d::from_cols(
    @math.Vec4::new(1.0F, 0.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 1.0F, 0.0F, 0.0F),
    @math.Vec4::new(0.0F, 0.0F, 1.0F, 0.0F),
    @math.Vec4::new(self.marker, 0.0F, 0.0F, 1.0F),
  )
}

///|
impl @camera_projection3d.CameraProjection3d for CameraBundleCustomProjection3d with fn get_clip_from_view_for_sub(
  self,
  _sub_view,
) {
  self.get_clip_from_view()
}

///|
impl @camera_projection3d.CameraProjection3d for CameraBundleCustomProjection3d with fn update(
  self,
  _width,
  _height,
) {
  self
}

///|
impl @camera_projection3d.CameraProjection3d for CameraBundleCustomProjection3d with fn far(
  _self,
) {
  256.0F
}

///|
impl @camera_projection3d.CameraProjection3d for CameraBundleCustomProjection3d with fn compute_frustum(
  self,
  camera_transform,
) {
  Projection::custom(self).compute_frustum(camera_transform)
}

///|
impl @camera_projection3d.CameraProjection3d for CameraBundleCustomProjection3d with fn get_frustum_corners(
  self,
  _z_near,
  _z_far,
) {
  [
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
    @math.Vec3::new(self.marker, 0.0F, 0.0F),
  ]
}

///|
test "render3d: Camera3dBundle stores window render target" {
  let world = @ecs.World::new()
  defer world.close()
  let target_window = @core.Entity::new(11, 3)
  let bundle = Camera3dBundle::new(Camera(), @transform.Transform::identity()).with_target(
    Window(Entity(target_window)),
  )
  let entity = bundle.spawn(world)

  let target : @camera_camera.RenderTarget? = try! world.get_by_key(
    entity, @camera_camera.ecs_key_render_target,
  )
  debug_inspect(
    target.map(fn(value) {
      ToJson::to_json(value) ==
      ToJson::to_json(
        @camera_camera.RenderTarget::Window(Entity(target_window)),
      )
    }),
    content="Some(true)",
  )
  let frustum : Frustum? = try! world.get_by_key(entity, ecs_key_frustum)
  debug_inspect(
    frustum.map(fn(value) { value.half_spaces.length() == 6 }),
    content="Some(true)",
  )
}

///|
test "render3d: Camera3dBundle stores custom projection behavior" {
  let world = @ecs.World::new()
  defer world.close()
  let bundle = Camera3dBundle::new_with_projection(
    Camera(),
    Projection::custom(CameraBundleCustomProjection3d::{ marker: 42.0F }),
    @transform.Transform::identity(),
  )
  let entity = bundle.spawn(world)

  let projection : Projection? = try! world.get_by_key(
    entity, ecs_key_projection,
  )
  let ok = match projection {
    Some(Custom(custom)) => {
      let matrix = custom.get_clip_from_view()
      camera_bundle_projection_approx_eq(matrix.w_axis.x, 42.0F)
    }
    Some(Perspective(_)) => false
    Some(Orthographic(_)) => false
    None => false
  }
  debug_inspect(ok, content="true")
}

///|
test "render3d: Commands::spawn accepts Camera3dBundle" {
  let world = @ecs.World::new()
  defer world.close()
  let spawned : Ref[@core.Entity?] = Ref(None)
  let mut app = @app.App::new(world).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(
      commands.spawn(
        Camera3dBundle::new(Camera(), @transform.Transform::identity()).with_color_grading(
          Some(ColorGrading()),
        ),
      ),
    )
  })
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_camera3d)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_projection)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_color_grading)) is Some(_),
    content="true",
  )
}

///|
test "render3d: Camera3dBundle injects Bevy-style tonemapping defaults" {
  let world = @ecs.World::new()
  defer world.close()
  let entity = Camera3dBundle::new(Camera(), @transform.Transform::identity()).spawn(
    world,
  )

  let tonemapping_ok = match
    (try! world.get_by_key(entity, ecs_key_tonemapping)) {
    Some(TonyMcMapface) => true
    _ => false
  }
  let deband_ok = match (try! world.get_by_key(entity, ecs_key_deband_dither)) {
    Some(Enabled) => true
    _ => false
  }
  debug_inspect(tonemapping_ok, content="true")
  debug_inspect(deband_ok, content="true")
}

///|
test "render3d: required components align PBR-owned Camera3d authoring" {
  let world = @ecs.World::new()
  defer world.close()
  try! register_render3d_required_components(world)
  let entity = world.spawn_empty()

  try! (world.set_by_key(entity, ecs_key_camera3d, Camera3d()) |> ignore)

  debug_inspect(
    (try! world.get_by_key(entity, @camera_camera.ecs_key_camera)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_projection)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @transform.ecs_key_transform)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @camera_camera.ecs_key_render_target))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, @camera_render_layers.ecs_key_render_layers))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_tonemapping)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_deband_dither)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_screen_space_transmission)) is None,
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_exposure)) is Some(_),
    content="false",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_frustum)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! world.get_by_key(entity, ecs_key_hdr)) is None,
    content="true",
  )

  let tonemapping_ok = match
    (try! world.get_by_key(entity, ecs_key_tonemapping)) {
    Some(TonyMcMapface) => true
    _ => false
  }
  let deband_ok = match (try! world.get_by_key(entity, ecs_key_deband_dither)) {
    Some(Enabled) => true
    _ => false
  }
  let target_ok = match
    (try! world.get_by_key(entity, @camera_camera.ecs_key_render_target)) {
    Some(Screen) => true
    _ => false
  }
  debug_inspect(tonemapping_ok, content="true")
  debug_inspect(deband_ok, content="true")
  debug_inspect(target_ok, content="true")
}

///|
test "render3d: spawn_component(Camera3d) uses required component defaults" {
  let spawned : Ref[@core.Entity?] = Ref(None)
  let world = @ecs.World::new()
  defer world.close()
  try! register_render3d_required_components(world)
  let mut app = @app.App::new(world).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(commands.spawn_component(Camera3d::Camera3d()))
  })
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn_component to return an entity")
  }

  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_camera3d)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, @camera_camera.ecs_key_camera))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_projection)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, @transform.ecs_key_transform))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_screen_space_transmission))
    is None,
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_hdr)) is None,
    content="true",
  )
}

///|
test "render3d: ScreenSpaceReflections requires depth and deferred prepasses" {
  let spawned : Ref[@core.Entity?] = Ref(None)
  let world = @ecs.World::new()
  defer world.close()
  try! register_render3d_required_components(world)
  let mut app = @app.App::new(world).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(
      commands.spawn_component(ScreenSpaceReflections::ScreenSpaceReflections()),
    )
  })
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn_component to return an entity")
  }

  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_screen_space_reflections))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_depth_prepass)) is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_deferred_prepass)) is Some(_),
    content="true",
  )
}

///|
test "render3d: AtmosphereSettings requires HDR" {
  let spawned : Ref[@core.Entity?] = Ref(None)
  let world = @ecs.World::new()
  defer world.close()
  try! register_render3d_required_components(world)
  let mut app = @app.App::new(world).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(
      commands.spawn_component(AtmosphereSettings::AtmosphereSettings()),
    )
  })
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn_component to return an entity")
  }

  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_atmosphere_settings))
    is Some(_),
    content="true",
  )
  debug_inspect(
    (try! app.world().get_by_key(entity, ecs_key_hdr)) is Some(_),
    content="true",
  )
}
