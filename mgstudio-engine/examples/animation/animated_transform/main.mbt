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
const PI : Float = 3.141592653589793F

///|
const PLANET_NAME : String = "planet"

///|
const ORBIT_CONTROLLER_NAME : String = "orbit_controller"

///|
const SATELLITE_NAME : String = "satellite"

///|
fn animated_transform_clip() -> (
  @asset.Handle[@animation.AnimationGraph],
  @animation.AnimationNodeIndex,
  @animation.AnimationTargetId,
  @animation.AnimationTargetId,
  @animation.AnimationTargetId,
) {
  let planet_target = @animation.AnimationTargetId::from_names([PLANET_NAME])
  let orbit_controller_target = @animation.AnimationTargetId::from_names([
    PLANET_NAME,
    ORBIT_CONTROLLER_NAME,
  ])
  let satellite_target = @animation.AnimationTargetId::from_names([
    PLANET_NAME,
    ORBIT_CONTROLLER_NAME,
    SATELLITE_NAME,
  ])

  let clip = @animation.AnimationClip::new()
    .add_translation_curve(planet_target, [
      @animation.KeyframeVec3::new(0.0F, @math.Vec3::new(1.0F, 0.0F, 1.0F)),
      @animation.KeyframeVec3::new(1.0F, @math.Vec3::new(-1.0F, 0.0F, 1.0F)),
      @animation.KeyframeVec3::new(2.0F, @math.Vec3::new(-1.0F, 0.0F, -1.0F)),
      @animation.KeyframeVec3::new(3.0F, @math.Vec3::new(1.0F, 0.0F, -1.0F)),
      @animation.KeyframeVec3::new(4.0F, @math.Vec3::new(1.0F, 0.0F, 1.0F)),
    ])
    .add_rotation_curve(orbit_controller_target, [
      @animation.KeyframeQuat::new(0.0F, @math.Quat::identity()),
      @animation.KeyframeQuat::new(
        1.0F,
        @math.Quat::from_axis_angle(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          PI / 2.0F,
        ),
      ),
      @animation.KeyframeQuat::new(
        2.0F,
        @math.Quat::from_axis_angle(@math.Vec3::new(0.0F, 1.0F, 0.0F), PI),
      ),
      @animation.KeyframeQuat::new(
        3.0F,
        @math.Quat::from_axis_angle(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          PI * 1.5F,
        ),
      ),
      @animation.KeyframeQuat::new(4.0F, @math.Quat::identity()),
    ])
    .add_scale_curve(satellite_target, [
      @animation.KeyframeVec3::new(0.0F, @math.Vec3::splat(0.8F)),
      @animation.KeyframeVec3::new(0.5F, @math.Vec3::splat(1.2F)),
      @animation.KeyframeVec3::new(1.0F, @math.Vec3::splat(0.8F)),
      @animation.KeyframeVec3::new(1.5F, @math.Vec3::splat(1.2F)),
      @animation.KeyframeVec3::new(2.0F, @math.Vec3::splat(0.8F)),
      @animation.KeyframeVec3::new(2.5F, @math.Vec3::splat(1.2F)),
      @animation.KeyframeVec3::new(3.0F, @math.Vec3::splat(0.8F)),
      @animation.KeyframeVec3::new(3.5F, @math.Vec3::splat(1.2F)),
      @animation.KeyframeVec3::new(4.0F, @math.Vec3::splat(0.8F)),
    ])
    .add_rotation_curve(satellite_target, [
      @animation.KeyframeQuat::new(0.0F, @math.Quat::identity()),
      @animation.KeyframeQuat::new(
        1.0F,
        @math.Quat::from_axis_angle(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          PI / 2.0F,
        ),
      ),
      @animation.KeyframeQuat::new(
        2.0F,
        @math.Quat::from_axis_angle(@math.Vec3::new(0.0F, 1.0F, 0.0F), PI),
      ),
      @animation.KeyframeQuat::new(
        3.0F,
        @math.Quat::from_axis_angle(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          PI * 1.5F,
        ),
      ),
      @animation.KeyframeQuat::new(4.0F, @math.Quat::identity()),
    ])

  let clip_handle = @animation.animation_clip_add(clip)
  let (graph, node) = @animation.AnimationGraph::from_clip(clip_handle)
  let graph_handle = @animation.animation_graph_add(graph)
  (graph_handle, node, planet_target, orbit_controller_target, satellite_target)
}

///|
fn setup(world : @ecs.World) -> Unit {
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 150.0F),
  )

  let camera = @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-2.0F, 2.5F, 5.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  ignore(camera.spawn(world))

  let light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(light)
    .insert(
      (
        @pbr.PointLight::default().with_intensity(500_000.0F),
        @transform.Transform::from_xyz(0.0F, 2.5F, 0.0F),
      ),
    ),
  )

  let (
    graph_handle,
    animation_node,
    planet_target,
    orbit_controller_target,
    satellite_target,
  ) = animated_transform_clip()

  let player = @animation.AnimationPlayer::default()
  player.play(animation_node).repeat() |> ignore

  let planet_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val
    |> @pbr.add_mesh(@math.Sphere::new(0.5F)),
  )
  let planet_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.8F, 0.7F, 0.6F)),
  )
  let planet = @pbr.MeshMaterial3dBundle::new(
    planet_mesh,
    @pbr.MeshMaterial3d::new(planet_material),
    @transform.Transform::identity(),
  ).spawn(world)
  ignore(
    try! world
    .entity_mut(planet)
    .insert(
      (
        @ecs.Name::new(PLANET_NAME),
        @animation.AnimationGraphHandle::new(graph_handle),
        player,
        planet_target,
        @animation.AnimatedBy::new(planet),
      ),
    ),
  )

  let orbit_controller = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(orbit_controller)
    .insert(
      (
        @transform.Transform::identity(),
        @ecs.Name::new(ORBIT_CONTROLLER_NAME),
        orbit_controller_target,
        @animation.AnimatedBy::new(planet),
        @hierarchy.Parent::new(planet),
      ),
    ),
  )

  let satellite_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val
    |> @pbr.add_mesh(@math.Cuboid::new(0.5F, 0.5F, 0.5F)),
  )
  let satellite_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.9F, 0.3F)),
  )
  let satellite = @pbr.MeshMaterial3dBundle::new(
    satellite_mesh,
    @pbr.MeshMaterial3d::new(satellite_material),
    @transform.Transform::from_xyz(1.5F, 0.0F, 0.0F),
  ).spawn(world)
  ignore(
    try! world
    .entity_mut(satellite)
    .insert(
      (
        @ecs.Name::new(SATELLITE_NAME),
        satellite_target,
        @animation.AnimatedBy::new(planet),
        @hierarchy.Parent::new(orbit_controller),
      ),
    ),
  )
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
