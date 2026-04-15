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
priv struct ObliquePerspectiveProjection {
  horizontal_obliqueness : Float
  vertical_obliqueness : Float
  perspective : @camera.PerspectiveProjection3d
}

///|
fn oblique_clip_from_view(
  base : @camera.ProjectionMatrix3d,
  horizontal_obliqueness : Float,
  vertical_obliqueness : Float,
) -> @camera.ProjectionMatrix3d {
  @camera.ProjectionMatrix3d::{
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
impl @pbr.CameraProjection3d for ObliquePerspectiveProjection with get_clip_from_view(
  self,
) {
  oblique_clip_from_view(
    self.perspective.get_clip_from_view(),
    self.horizontal_obliqueness,
    self.vertical_obliqueness,
  )
}

///|
impl @pbr.CameraProjection3d for ObliquePerspectiveProjection with get_clip_from_view_for_sub(
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
impl @pbr.CameraProjection3d for ObliquePerspectiveProjection with update(
  self,
  width,
  height,
) {
  { ..self, perspective: self.perspective.update(width, height) }
}

///|
impl @pbr.CameraProjection3d for ObliquePerspectiveProjection with far(self) {
  self.perspective.far
}

///|
impl @pbr.CameraProjection3d for ObliquePerspectiveProjection with compute_frustum(
  self,
  camera_transform,
) {
  @camera.Projection::custom(self).compute_frustum(camera_transform)
}

///|
impl @pbr.CameraProjection3d for ObliquePerspectiveProjection with get_frustum_corners(
  self : ObliquePerspectiveProjection,
  z_near : Float,
  z_far : Float,
) {
  self.perspective.get_frustum_corners(z_near, z_far)
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let ground_mesh = meshes.get_ref().val.add(
    @mesh.Mesh::from_3d_geometry(@mesh.Mesh3dGeometry::circle(4.0F, 32)),
  )
  let cube_mesh = meshes.get_ref().val.add(
    @mesh.Mesh::from_3d_geometry(
      @mesh.Mesh3dGeometry::cuboid(@math.Cuboid::new(1.0F, 1.0F, 1.0F)),
    ),
  )
  let white_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()),
  )
  let cube_material = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::srgb(124.0F / 255.0F, 144.0F / 255.0F, 1.0F),
    ),
  )

  commands.spawn(
    (
      @camera.Camera3d::default(),
      @camera.Projection::custom(ObliquePerspectiveProjection::{
        horizontal_obliqueness: 0.2F,
        vertical_obliqueness: 0.6F,
        perspective: @camera.PerspectiveProjection3d::default(),
      }),
      @transform.Transform::from_xyz(-2.5F, 4.5F, 9.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.Mesh3d::new(ground_mesh),
      @pbr.MeshMaterial3d::new(white_material),
      @transform.Transform::from_rotation(
        @math.Quat::from_rotation_x(-@math.pi() / 2.0F),
      ),
    ),
  )
  |> ignore

  commands.spawn(
    (
      @pbr.Mesh3d::new(cube_mesh),
      @pbr.MeshMaterial3d::new(cube_material),
      @transform.Transform::from_xyz(0.0F, 0.5F, 0.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::default().with_shadow_maps_enabled(true),
      @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
    ),
  )
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .run()
}
