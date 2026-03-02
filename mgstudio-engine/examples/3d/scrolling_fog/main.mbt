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
/// Parity notes:
/// - Keeps Bevy-like TAA/Bloom camera stack and scrolling fog-volume proxy meshes.
/// - Uses `VolumetricFog` and `FogVolume` data-model stubs to mirror Bevy setup.
/// - Backend still approximates voxel raymarching through distance-fog controls.

///|
const FOG_CENTER_Y : Float = 11.0F

///|
const FOG_DENSITY_TEXTURE_SCROLL_SPEED : Float = 0.04F

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
  mut camera : @core.Entity?
  mut fog_volume_outer : @core.Entity?
  mut fog_volume_inner : @core.Entity?
  mut volumetric_fog_stub : @render3d.VolumetricFog
  mut fog_volume_stub : @render3d.FogVolume
}

///|
let scrolling_fog_state : Ref[ScrollingFogState] = Ref::new({
  camera: None,
  fog_volume_outer: None,
  fog_volume_inner: None,
  volumetric_fog_stub: @render3d.VolumetricFog::default(),
  fog_volume_stub: @render3d.FogVolume::default(),
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
fn apply_distance_fog_from_stub(
  world : @ecs.World,
  proxy_density_noise : Float,
  sunlight_phase : Float,
) -> Unit {
  let fog_volume_stub = scrolling_fog_state.val.fog_volume_stub
  let volumetric_fog_stub = scrolling_fog_state.val.volumetric_fog_stub
  let visibility = clampf(
    20.0F / (1.0F + fog_volume_stub.density_factor * 60.0F),
    6.0F,
    32.0F,
  )
  let brightness = 0.45F + 0.55F * sunlight_phase
  let ambient_lift = clampf(
    volumetric_fog_stub.ambient_intensity * 0.5F,
    0.0F,
    0.25F,
  )
  let directional_alpha = clampf(0.25F + sunlight_phase * 0.45F, 0.2F, 0.75F)

  let fog = @render3d.DistanceFog::default()
    .with_color(
      @render2d.Color::new(
        clamp01(
          (0.34F + proxy_density_noise * 0.05F) * brightness + ambient_lift,
        ),
        clamp01(
          (0.37F + proxy_density_noise * 0.06F) * brightness + ambient_lift,
        ),
        clamp01(
          (0.42F + proxy_density_noise * 0.08F) * brightness + ambient_lift,
        ),
        0.95F,
      ),
    )
    .with_directional_light_color(
      @render2d.Color::new(1.0F, 0.95F, 0.85F, directional_alpha),
    )
    .with_directional_light_exponent(12.0F)
    .with_falloff(@render3d.FogFalloff3d::from_visibility_squared(visibility))
  guard scrolling_fog_state.val.camera is Some(camera) else { return }
  let tick = world.read_change_tick()
  let camera3d_store = @render3d.query_get_camera3d_store(world)
  let camera3d = match camera3d_store.get(camera) {
    Some(value) => value
    None => @render3d.Camera3d::default()
  }
  camera3d_store.set(camera, camera3d.with_distance_fog(Some(fog)), tick)
  |> ignore
}

///|
fn spawn_world_geometry(world : @ecs.World) -> Unit {
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
fn spawn_fog_proxy(world : @ecs.World) -> Unit {
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
fn setup_camera(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(CAMERA_X, CAMERA_Y, CAMERA_Z).looking_at(
      focus_point(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  @render3d.query_get_msaa_store(world).insert(
    camera,
    @render3d.Msaa::Off,
    tick,
  )
  @render3d.query_get_temporal_anti_aliasing_store(world).insert(
    camera,
    @render3d.TemporalAntiAliasing::default(),
    tick,
  )
  @render3d.query_get_bloom_store(world).insert(
    camera,
    @render3d.Bloom::default(),
    tick,
  )
  scrolling_fog_state.val.camera = Some(camera)
}

///|
fn setup_lighting(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()

  let ambient = @render3d.query_get_global_ambient_light_resource(world)
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.0F,
    )
  }

  let light = world.spawn_empty()
  @math.query_get_transform_store(world).insert(
    light,
    @math.Transform::from_xyz(-5.0F, 5.0F, -7.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  @render3d.query_get_directional_light_store(world).insert(
    light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 12_000.0F, true),
    tick,
  )
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let shadow_map_resource = @render3d.query_get_directional_light_shadow_map_resource(
    world,
  )
  if shadow_map_resource.get_ref_mut(tick) is Some(current) {
    current.val = @render3d.DirectionalLightShadowMap::new(4096)
  } else {
    shadow_map_resource.insert(
      @render3d.DirectionalLightShadowMap::new(4096),
      tick,
    )
  }

  scrolling_fog_state.val.fog_volume_outer = None
  scrolling_fog_state.val.fog_volume_inner = None
  scrolling_fog_state.val.camera = None
  scrolling_fog_state.val.volumetric_fog_stub = @render3d.VolumetricFog::default()
    .with_ambient_intensity(0.0F)
    .with_jitter(0.5F)
  scrolling_fog_state.val.fog_volume_stub = @render3d.FogVolume::default()
    .with_density_factor(FOG_BASE_DENSITY)
    .with_scattering(0.3F)
    .with_absorption(0.3F)
    .with_scattering_asymmetry(0.5F)

  spawn_world_geometry(world)
  spawn_fog_proxy(world)
  setup_camera(world)
  setup_lighting(world)

  apply_distance_fog_from_stub(world, 0.5F, 1.0F)
}

///|
fn scroll_fog(world : @ecs.World) -> Unit {
  let elapsed = @time.time_elapsed_seconds()
  let density_texture_offset_z = elapsed * FOG_DENSITY_TEXTURE_SCROLL_SPEED
  let tick = world.read_change_tick()

  if scrolling_fog_state.val.fog_volume_outer is Some(fog_outer) {
    @math.query_get_transform_store(world).set(
      fog_outer,
      @math.Transform::from_xyz(0.0F, FOG_CENTER_Y, 0.0F),
      tick,
    )
    |> ignore
  }

  if scrolling_fog_state.val.fog_volume_inner is Some(fog_inner) {
    @math.query_get_transform_store(world).set(
      fog_inner,
      @math.Transform::from_xyz(0.0F, FOG_CENTER_Y - 1.0F, 0.0F),
      tick,
    )
    |> ignore
  }

  let light_transform = @math.Transform::from_xyz(-5.0F, 5.0F, -7.0F).looking_at(
    @math.Vec3::new(0.0F, 0.0F, 0.0F),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )

  let proxy_density_noise = clamp01(
    0.5F + 0.5F * @math.sin(density_texture_offset_z * 10.0F),
  )
  let density = FOG_BASE_DENSITY + FOG_DENSITY_SWING * proxy_density_noise
  scrolling_fog_state.val.fog_volume_stub = scrolling_fog_state.val.fog_volume_stub
    .with_density_factor(density)
    .with_density_texture_offset(
      @math.Vec3::new(0.0F, 0.0F, density_texture_offset_z),
    )

  let view_dir = focus_point().sub(camera_position()).normalize_or_zero()
  let light_dir = transform_forward(light_transform)
  let sunlight_phase = clamp01(light_dir.neg().dot(view_dir) * 0.5F + 0.5F)
  apply_distance_fog_from_stub(world, proxy_density_noise, sunlight_phase)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins_ecs()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(scroll_fog)
  .run()
}
