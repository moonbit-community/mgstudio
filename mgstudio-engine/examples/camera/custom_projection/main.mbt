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
/// Port of `bevy/examples/camera/custom_projection.rs`.

///|
priv struct ObliquePerspectiveProjection {
  horizontal_obliqueness : Float
  vertical_obliqueness : Float
  perspective : @render3d.PerspectiveProjection3d
}

///|
fn oblique_clip_from_view(
  base : @render3d.ProjectionMatrix3d,
  horizontal_obliqueness : Float,
  vertical_obliqueness : Float,
) -> @render3d.ProjectionMatrix3d {
  @render3d.ProjectionMatrix3d::{
    ..base,
    z_axis: @math.Vec4::new(
      horizontal_obliqueness,
      vertical_obliqueness,
      base.z_axis.z,
      base.z_axis.w,
    ),
  }
}

///|
impl @render3d.CameraProjection3d for ObliquePerspectiveProjection with get_clip_from_view(
  self,
) {
  oblique_clip_from_view(
    self.perspective.get_clip_from_view(),
    self.horizontal_obliqueness,
    self.vertical_obliqueness,
  )
}

///|
impl @render3d.CameraProjection3d for ObliquePerspectiveProjection with get_clip_from_view_for_sub(
  self,
  sub_view,
) {
  oblique_clip_from_view(
    self.perspective.get_clip_from_view_for_sub(sub_view),
    self.horizontal_obliqueness,
    self.vertical_obliqueness,
  )
}

///|
impl @render3d.CameraProjection3d for ObliquePerspectiveProjection with update(
  self,
  width,
  height,
) {
  { ..self, perspective: self.perspective.update(width, height) }
}

///|
impl @render3d.CameraProjection3d for ObliquePerspectiveProjection with far(
  self,
) {
  self.perspective.far
}

///|
impl @render3d.CameraProjection3d for ObliquePerspectiveProjection with get_frustum_corners(
  self : ObliquePerspectiveProjection,
  z_near : Float,
  z_far : Float,
) {
  self.perspective.get_frustum_corners(z_near, z_far)
}

///|
fn setup(
  commands : @app.Commands,
  materials : @app.ResMut[@asset.Assets[@render3d.StandardMaterial]],
) -> Unit {
  let white_material = materials.get_ref().val.add(
    @render3d.StandardMaterial::from_color(@render2d.Color::white()),
  )
  let cube_material = materials.get_ref().val.add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::srgb(124.0F / 255.0F, 144.0F / 255.0F, 1.0F),
    ),
  )

  commands.spawn(
    (
      @render3d.Camera3d::default(),
      @render3d.Projection::custom(ObliquePerspectiveProjection::{
        horizontal_obliqueness: 0.2F,
        vertical_obliqueness: 0.6F,
        perspective: @render3d.PerspectiveProjection3d::default(),
      }),
      @math.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @render3d.Mesh3d::from_circle(4.0F),
      @render3d.MeshMaterial3d::new(white_material),
      @math.Transform::identity(),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
      @render3d.MeshMaterial3d::new(cube_material),
      @math.Transform::from_xyz(0.0F, 0.5F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @render3d.PointLight::default().with_shadow_maps_enabled(true),
      @math.Transform::from_xyz(4.0F, 8.0F, 4.0F),
    ),
  )
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup)))
  .run()
}
