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
impl CameraProjection3d for CameraBundleCustomProjection3d with get_clip_from_view(
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
impl CameraProjection3d for CameraBundleCustomProjection3d with get_clip_from_view_for_sub(
  self,
  _sub_view,
) {
  self.get_clip_from_view()
}

///|
impl CameraProjection3d for CameraBundleCustomProjection3d with update(
  self,
  _width,
  _height,
) {
  self
}

///|
impl CameraProjection3d for CameraBundleCustomProjection3d with far(_self) {
  256.0F
}

///|
impl CameraProjection3d for CameraBundleCustomProjection3d with compute_frustum(
  self,
  camera_transform,
) {
  Projection::custom(self).compute_frustum(camera_transform)
}

///|
impl CameraProjection3d for CameraBundleCustomProjection3d with get_frustum_corners(
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
  let target_window = @core.Entity::new(11, 3)
  let bundle = Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::identity(),
  ).with_target(
    @render2d.RenderTarget::Window(@window.WindowRef::Entity(target_window)),
  )
  let entity = bundle.spawn(world)

  let target : @render2d.RenderTarget? = try! world.get(
    entity, @render2d.ecs_key_render_target,
  )
  inspect(
    target.map(fn(value) {
      value.to_json() ==
      @render2d.RenderTarget::Window(@window.WindowRef::Entity(target_window)).to_json()
    }),
    content="Some(true)",
  )
  let frustum : Frustum? = try! world.get(entity, ecs_key_frustum)
  inspect(
    frustum.map(fn(value) { value.half_spaces.length() == 6 }),
    content="Some(true)",
  )
}

///|
test "render3d: Camera3dBundle stores custom projection payload" {
  let world = @ecs.World::new()
  let bundle = Camera3dBundle::new_with_projection(
    @render2d.Camera::default(),
    Projection::custom(CameraBundleCustomProjection3d::{ marker: 42.0F }),
    @math.Transform::identity(),
  )
  let entity = bundle.spawn(world)

  let projection : Projection? = try! world.get(entity, ecs_key_projection)
  let ok = match projection {
    Some(Projection::Custom(custom)) => {
      let payload : CameraBundleCustomProjection3d? = custom.get()
      match payload {
        Some(value) => camera_bundle_projection_approx_eq(value.marker, 42.0F)
        None => false
      }
    }
    Some(Projection::Perspective(_)) => false
    Some(Projection::Orthographic(_)) => false
    None => false
  }
  inspect(ok, content="true")
}

///|
test "render3d: Commands::spawn accepts Camera3dBundle" {
  let world = @ecs.World::new()
  let spawned : Ref[@core.Entity?] = Ref::new(None)
  let mut app = @app.App::new(world).add_system_param(fn(
    commands : @app.Commands,
  ) {
    spawned.val = Some(
      commands.spawn(
        Camera3dBundle::new(
          @render2d.Camera::default(),
          @math.Transform::identity(),
        ).with_color_grading(Some(ColorGrading::default())),
      ),
    )
  })
  app = app.run_once()

  guard spawned.val is Some(entity) else {
    abort("expected Commands::spawn to return an entity")
  }
  inspect(
    (try! app.world().get(entity, ecs_key_camera3d)) is Some(_),
    content="true",
  )
  inspect(
    (try! app.world().get(entity, ecs_key_projection)) is Some(_),
    content="true",
  )
  inspect(
    (try! app.world().get(entity, ecs_key_color_grading)) is Some(_),
    content="true",
  )
}
