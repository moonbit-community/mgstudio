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
const CUBE_NAME : String = "Cube"

///|
const CUBE_SIZE : Float = 2.0F

///|
const MOTION_SAMPLE_COUNT : Int = 121

///|
const ROTATION_SAMPLE_COUNT : Int = 81

///|
fn easing_translation_curve() -> @math.Curve[@math.Vec3] {
  let motion_domain = @math.Interval::new(0.0F, 3.0F) catch {
    _ => abort("eased motion example expects bounded translation domain")
  }
  let base = @math.EasingCurve::new(
    @math.Vec3::new(-6.0F, 2.0F, 0.0F),
    @math.Vec3::new(6.0F, 2.0F, 0.0F),
    @math.EaseFunction::CubicInOut,
  ).as_curve()
  let forward = base.reparametrize_linear(motion_domain) catch {
    _ => abort("eased motion example expects bounded translation curve")
  }
  let backward = forward.reverse() catch {
    _ => abort("eased motion example expects reversible translation curve")
  }
  forward.chain(backward) catch {
    _ => abort("eased motion example expects chainable translation curve")
  }
}

///|
fn easing_rotation_curve() -> @math.Curve[@math.Quat] {
  let rotation_domain = @math.Interval::new(0.0F, 4.0F) catch {
    _ => abort("eased motion example expects bounded rotation domain")
  }
  let base = @math.EasingCurve::new(
    @math.Quat::identity(),
    @math.Quat::from_rotation_y(1.5707963267948966F),
    @math.EaseFunction::ElasticInOut,
  ).as_curve()
  base.reparametrize_linear(rotation_domain) catch {
    _ => abort("eased motion example expects bounded rotation curve")
  }
}

///|
fn easing_motion_clip() -> (
  @asset.Handle[@animation.AnimationGraph],
  @animation.AnimationNodeIndex,
  @animation.AnimationTargetId,
) {
  let target = @animation.AnimationTargetId::from_name(CUBE_NAME)
  let clip = @animation.AnimationClip::new()
    .add_curve_to_target(
      target,
      @animation.AnimatableCurve::Translation(easing_translation_curve()),
      sample_count=MOTION_SAMPLE_COUNT,
    )
    .add_curve_to_target(
      target,
      @animation.AnimatableCurve::Rotation(easing_rotation_curve()),
      sample_count=ROTATION_SAMPLE_COUNT,
    )

  let clip_handle = @animation.animation_clip_add(clip)
  let (graph, node) = @animation.AnimationGraph::from_clip(clip_handle)
  let graph_handle = @animation.animation_graph_add(graph)
  (graph_handle, node, target)
}

///|
fn setup(world : @ecs.World) -> Unit {
  let (graph_handle, animation_node, animation_target) = easing_motion_clip()

  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 100.0F),
  )

  let player = @animation.AnimationPlayer::default()
  player.play(animation_node).repeat() |> ignore

  let cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val
      |> @pbr.add_mesh(@math.Cuboid::from_length(CUBE_SIZE)),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::srgb(1.0F, 0.64705884F, 0.0F),
        ),
      ),
    ),
    @transform.Transform::from_xyz(-6.0F, 2.0F, 0.0F),
  ).spawn(world)
  ignore(
    try! world
    .entity_mut(cube)
    .insert(
      (
        @ecs.Name::new(CUBE_NAME),
        player,
        @animation.AnimationGraphHandle::new(graph_handle),
        animation_target,
        @animation.AnimatedBy::new(cube),
      ),
    ),
  )

  let light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(light)
    .insert(
      (
        @pbr.PointLight::new(
          @sprite.Color::white(),
          10_000_000.0F,
          100.0F,
          true,
        ),
        @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F),
      ),
    ),
  )

  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_plane(50.0F, 50.0F)),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::srgb(0.7529412F, 0.7529412F, 0.7529412F),
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 6.0F, 12.0F).looking_at(
      @math.Vec3::new(0.0F, 1.5F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(setup))
  .run()
}
