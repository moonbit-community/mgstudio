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
/// Port of `bevy/examples/3d/scrolling_fog.rs`.
///
/// Baseline parity: Bevy's voxel fog density texture path (`FogVolume` with a
/// scrolling 3D density texture, plus TAA/Bloom integration) is approximated
/// with mgstudio's distance fog controls and animated proxy fog-volume meshes.

///|
const FOG_CENTER_Y : Float = 11.0F

///|
const FOG_SCROLL_SPEED : Float = 0.35F

///|
const FOG_SCROLL_AMPLITUDE : Float = 12.0F

///|
const FOG_BASE_DENSITY : Float = 0.03F

///|
const FOG_DENSITY_SWING : Float = 0.05F

///|
const CAMERA_X : Float = 0.0F

///|
const CAMERA_Y : Float = 2.0F

///|
const CAMERA_Z : Float = 0.0F

///|
const LOOK_TARGET_X : Float = -5.0F

///|
const LOOK_TARGET_Y : Float = 3.5F

///|
const LOOK_TARGET_Z : Float = -6.0F

///|
priv struct ScrollingFogState {
  mut fog_volume_outer : @core.Entity?
  mut fog_volume_inner : @core.Entity?
  mut directional_light : @core.Entity?
}

///|
let scrolling_fog_state : Ref[ScrollingFogState] = Ref::new({
  fog_volume_outer: None,
  fog_volume_inner: None,
  directional_light: None,
})

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn clamp01(value : Float) -> Float {
  clampf(value, 0.0F, 1.0F)
}

///|
fn quat_rotate_vec3(q : @math.Quat, v : @math.Vec3) -> @math.Vec3 {
  let qv = @math.Vec3::new(q.x, q.y, q.z)
  let t = qv.cross(v).mul_scalar(2.0F)
  v.add(t.mul_scalar(q.w)).add(qv.cross(t))
}

///|
fn transform_forward(transform : @math.Transform) -> @math.Vec3 {
  quat_rotate_vec3(transform.rotation, @math.Vec3::new(0.0F, 0.0F, -1.0F)).normalize_or_zero()
}

///|
fn focus_point() -> @math.Vec3 {
  @math.Vec3::new(LOOK_TARGET_X, LOOK_TARGET_Y, LOOK_TARGET_Z)
}

///|
fn camera_position() -> @math.Vec3 {
  @math.Vec3::new(CAMERA_X, CAMERA_Y, CAMERA_Z)
}

///|
fn spawn_world_geometry(world : @ecs_world.World) -> Unit {
  let black_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(@render2d.Color::black())
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(64.0F, 1.0F, 64.0F),
    @render3d.MeshMaterial3d::new(black_material),
    @math.Transform::from_xyz(0.0F, -0.5F, 0.0F),
  ).spawn(world)
  |> ignore

  @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(2.0F, 9.0F, 2.0F),
    @render3d.MeshMaterial3d::new(black_material),
    @math.Transform::from_xyz(-10.0F, 4.5F, -11.0F),
  ).spawn(world)
  |> ignore
}

///|
fn spawn_fog_proxy(world : @ecs_world.World) -> Unit {
  let outer_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.74F, 0.79F, 0.87F, 0.15F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F)
    .with_emissive(@render2d.Color::new(0.08F, 0.09F, 0.12F, 1.0F)),
  )

  let inner_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.72F, 0.78F, 0.86F, 0.12F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F)
    .with_emissive(@render2d.Color::new(0.09F, 0.10F, 0.13F, 1.0F)),
  )

  let outer = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(64.0F, 24.0F, 64.0F),
    @render3d.MeshMaterial3d::new(outer_material),
    @math.Transform::from_xyz(0.0F, FOG_CENTER_Y, 0.0F),
  ).spawn(world)
  scrolling_fog_state.val.fog_volume_outer = Some(outer)

  let inner = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(48.0F, 16.0F, 48.0F),
    @render3d.MeshMaterial3d::new(inner_material),
    @math.Transform::from_xyz(0.0F, FOG_CENTER_Y - 1.0F, 0.0F),
  ).spawn(world)
  scrolling_fog_state.val.fog_volume_inner = Some(inner)
}

///|
fn setup_camera(world : @ecs_world.World) -> Unit {
  @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(CAMERA_X, CAMERA_Y, CAMERA_Z).looking_at(
      focus_point(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  |> ignore
}

///|
fn setup_lighting(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.0F,
    )
  }

  let light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    light,
    @math.Transform::from_xyz(-5.0F, 5.0F, -7.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 12_000.0F, true),
    tick,
  )
  scrolling_fog_state.val.directional_light = Some(light)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  scrolling_fog_state.val.fog_volume_outer = None
  scrolling_fog_state.val.fog_volume_inner = None
  scrolling_fog_state.val.directional_light = None

  spawn_world_geometry(world)
  spawn_fog_proxy(world)
  setup_camera(world)
  setup_lighting(world)

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(0.34F, 0.37F, 0.42F, 0.95F),
      @render3d.FogFalloff3d::exponential_squared(FOG_BASE_DENSITY),
    ),
  )
}

///|
fn scroll_fog(world : @ecs_world.World) -> Unit {
  let elapsed = @time.time_elapsed_seconds()
  let wind_phase = elapsed * FOG_SCROLL_SPEED
  let offset = @math.sin(wind_phase) * FOG_SCROLL_AMPLITUDE
  let tick = world.read_change_tick()

  if scrolling_fog_state.val.fog_volume_outer is Some(fog_outer) {
    world
    .get_transform_store()
    .set(fog_outer, @math.Transform::from_xyz(0.0F, FOG_CENTER_Y, offset), tick)
    |> ignore
  }

  if scrolling_fog_state.val.fog_volume_inner is Some(fog_inner) {
    world
    .get_transform_store()
    .set(
      fog_inner,
      @math.Transform::from_xyz(
        @math.sin(wind_phase * 0.7F) * 3.0F,
        FOG_CENTER_Y - 1.0F,
        -offset * 0.65F,
      ),
      tick,
    )
    |> ignore
  }

  let mut light_transform = @math.Transform::from_xyz(-5.0F, 5.0F, -7.0F).looking_at(
    @math.Vec3::new(0.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  if scrolling_fog_state.val.directional_light is Some(light_entity) {
    light_transform = @math.Transform::from_xyz(
      -5.0F + @math.sin(wind_phase * 0.5F) * 0.9F,
      5.0F,
      -7.0F + @math.cos(wind_phase * 0.45F) * 0.9F,
    ).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    )
    world.get_transform_store().set(light_entity, light_transform, tick)
    |> ignore
  }

  let proxy_density_noise = clamp01(
    0.5F +
    0.5F * @math.sin(wind_phase * 1.7F + @math.sin(wind_phase * 0.23F) * 2.0F),
  )
  let density = FOG_BASE_DENSITY + FOG_DENSITY_SWING * proxy_density_noise

  let view_dir = focus_point().sub(camera_position()).normalize_or_zero()
  let light_dir = transform_forward(light_transform)
  let sunlight_phase = clamp01(light_dir.neg().dot(view_dir) * 0.5F + 0.5F)
  let brightness = 0.45F + 0.55F * sunlight_phase

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(
        clamp01((0.34F + proxy_density_noise * 0.05F) * brightness),
        clamp01((0.37F + proxy_density_noise * 0.06F) * brightness),
        clamp01((0.42F + proxy_density_noise * 0.08F) * brightness),
        0.95F,
      ),
      @render3d.FogFalloff3d::exponential_squared(density),
    ),
  )
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(scroll_fog)
  .run()
}
