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
/// Port of `bevy/examples/3d/volumetric_fog.rs`.
///
/// Baseline parity: Bevy's voxel volumetric fog stack (`VolumetricFog`,
/// `VolumetricLight`, `FogVolume`, bloom/skybox integration) is approximated
/// using mgstudio's current distance-fog pipeline with light-driven scattering
/// response and proxy fog volume geometry; camera tonemapping/bloom/skybox are
/// aligned with Bevy setup.

///|
const DIRECTIONAL_LIGHT_MOVEMENT_SPEED : Float = 1.2F

///|
const POINT_LIGHT_MIN_X : Float = -1.93F

///|
const POINT_LIGHT_MAX_X : Float = -0.4F

///|
const POINT_LIGHT_INITIAL_SPEED : Float = -0.2F

///|
priv struct VolumetricFogState {
  mut volumetric_spotlight : Bool
  mut volumetric_pointlight : Bool
  mut camera : @core.Entity?
  mut directional_light : @core.Entity?
  mut point_light : @core.Entity?
  mut spot_light : @core.Entity?
  mut point_light_speed : Float
  mut help_text : @text.TextHandle?
}

///|
let volumetric_fog_state : Ref[VolumetricFogState] = Ref::new({
  volumetric_spotlight: true,
  volumetric_pointlight: true,
  camera: None,
  directional_light: None,
  point_light: None,
  spot_light: None,
  point_light_speed: POINT_LIGHT_INITIAL_SPEED,
  help_text: None,
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
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn scene_focus() -> @math.Vec3 {
  @math.Vec3::new(-1.5F, 1.7F, 3.5F)
}

///|
fn create_text() -> String {
  let point_text = if volumetric_fog_state.val.volumetric_pointlight {
    "Press P to turn volumetric point light off"
  } else {
    "Press P to turn volumetric point light on"
  }

  let spot_text = if volumetric_fog_state.val.volumetric_spotlight {
    "Press L to turn volumetric spot light off"
  } else {
    "Press L to turn volumetric spot light on"
  }

  "Press WASD or the arrow keys to change the direction of the directional light\n\{point_text}\n\{spot_text}"
}

///|
fn spawn_mesh(
  world : @ecs_world.World,
  mesh : @render3d.Mesh3d,
  material : @asset.Handle[@render3d.StandardMaterial],
  transform : @math.Transform,
) -> Unit {
  @render3d.MeshMaterial3dBundle::new(
    mesh,
    @render3d.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup_scene_geometry(world : @ecs_world.World) -> Unit {
  let corridor_floor_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.10F, 0.10F, 0.11F, 1.0F),
    )
    .with_perceptual_roughness(0.95F)
    .with_metallic(0.0F),
  )

  let wall_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.16F, 0.16F, 0.18F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )

  let block_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.42F, 0.45F, 0.48F, 1.0F),
    )
    .with_perceptual_roughness(0.6F)
    .with_metallic(0.0F),
  )

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(7.0F, 0.2F, 11.0F),
    corridor_floor_material,
    @math.Transform::from_xyz(-1.5F, -0.1F, 3.5F),
  )

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(7.0F, 0.2F, 11.0F),
    wall_material,
    @math.Transform::from_xyz(-1.5F, 3.9F, 3.5F),
  )

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(0.2F, 4.0F, 11.0F),
    wall_material,
    @math.Transform::from_xyz(-4.9F, 1.9F, 3.5F),
  )

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(0.2F, 4.0F, 11.0F),
    wall_material,
    @math.Transform::from_xyz(1.9F, 1.9F, 3.5F),
  )

  for i in 0..<8 {
    let z = -0.5F + float_from_int(i) * 1.2F
    spawn_mesh(
      world,
      @render3d.Mesh3d::from_cuboid(0.45F, 1.6F, 0.45F),
      block_material,
      @math.Transform::from_xyz(-3.7F, 0.8F, z),
    )
    spawn_mesh(
      world,
      @render3d.Mesh3d::from_cuboid(0.45F, 1.6F, 0.45F),
      block_material,
      @math.Transform::from_xyz(0.7F, 0.8F, z),
    )
  }

  let fog_volume_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.78F, 0.82F, 0.92F, 0.18F),
    )
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F)
    .with_emissive(@render2d.Color::new(0.08F, 0.08F, 0.10F, 1.0F)),
  )

  spawn_mesh(
    world,
    @render3d.Mesh3d::from_cuboid(5.0F, 3.8F, 10.0F),
    fog_volume_material,
    @math.Transform::from_xyz(-1.5F, 1.9F, 3.5F),
  )
}

///|
fn setup_camera(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(-1.7F, 1.5F, 4.5F).looking_at(
      scene_focus(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  let tick = world.read_change_tick()
  world
  .get_tonemapping_store()
  .insert(camera, @render3d.Tonemapping::TonyMcMapface, tick)
  world.get_bloom_store().insert(camera, @render3d.Bloom::default(), tick)
  world
  .get_skybox_store()
  .insert(
    camera,
    @render3d.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      1000.0F,
    ),
    tick,
  )
  volumetric_fog_state.val.camera = Some(camera)
}

///|
fn setup_lights(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  let directional_light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    directional_light,
    @math.Transform::from_xyz(1.0F, 4.3F, -1.5F).looking_at(
      scene_focus(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_directional_light_store()
  .insert(
    directional_light,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 15_000.0F, true),
    tick,
  )
  volumetric_fog_state.val.directional_light = Some(directional_light)

  let point_light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(point_light, @math.Transform::from_xyz(-0.4F, 1.9F, 1.0F), tick)
  world
  .get_point_light_store()
  .insert(
    point_light,
    @render3d.PointLight::new(
      @render2d.Color::new(1.0F, 0.15F, 0.15F, 1.0F),
      10_000.0F,
      150.0F,
      true,
    ),
    tick,
  )
  volumetric_fog_state.val.point_light = Some(point_light)

  let spot_light = world.spawn_empty()
  world
  .get_transform_store()
  .insert(
    spot_light,
    @math.Transform::from_xyz(-1.8F, 3.9F, -2.7F).looking_at(
      @math.Vec3::new(-1.5F, 0.7F, 3.5F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )
  world
  .get_spot_light_store()
  .insert(
    spot_light,
    @render3d.SpotLight::new(
      @render2d.Color::white(),
      50_000.0F,
      150.0F,
      0.76F,
      0.94F,
      true,
    ),
    tick,
  )
  volumetric_fog_state.val.spot_light = Some(spot_light)
}

///|
fn setup_instructions(_world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(create_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  volumetric_fog_state.val.help_text = Some(handle)
}

///|
fn apply_light_switches(world : @ecs_world.World) -> Unit {
  let tick = world.read_change_tick()

  if volumetric_fog_state.val.point_light is Some(point_light) {
    if world.get_point_light_store().get(point_light) is Some(light) {
      world
      .get_point_light_store()
      .set(
        point_light,
        @render3d.PointLight::new(
          light.color,
          if volumetric_fog_state.val.volumetric_pointlight {
            10_000.0F
          } else {
            0.0F
          },
          light.range,
          volumetric_fog_state.val.volumetric_pointlight,
        ),
        tick,
      )
      |> ignore
    }
  }

  if volumetric_fog_state.val.spot_light is Some(spot_light) {
    if world.get_spot_light_store().get(spot_light) is Some(light) {
      world
      .get_spot_light_store()
      .set(
        spot_light,
        @render3d.SpotLight::new(
          light.color,
          if volumetric_fog_state.val.volumetric_spotlight {
            50_000.0F
          } else {
            0.0F
          },
          light.range,
          light.inner_angle,
          light.outer_angle,
          volumetric_fog_state.val.volumetric_spotlight,
        ),
        tick,
      )
      |> ignore
    }
  }
}

///|
fn apply_fog_proxy(world : @ecs_world.World) -> Unit {
  let mut phase = 0.5F

  if volumetric_fog_state.val.camera is Some(camera_entity) {
    if volumetric_fog_state.val.directional_light is Some(light_entity) {
      if world.get_transform_store().get(camera_entity)
        is Some(camera_transform) {
        if world.get_transform_store().get(light_entity)
          is Some(light_transform) {
          let light_dir = transform_forward(light_transform).neg()
          let view_dir = scene_focus()
            .sub(camera_transform.translation)
            .normalize_or_zero()
          phase = clamp01(light_dir.dot(view_dir) * 0.5F + 0.5F)
        }
      }
    }
  }

  let point_factor = if volumetric_fog_state.val.volumetric_pointlight {
    0.22F
  } else {
    0.0F
  }
  let spot_factor = if volumetric_fog_state.val.volumetric_spotlight {
    0.26F
  } else {
    0.0F
  }

  let brightness = clampf(
    0.12F + phase * 0.36F + point_factor + spot_factor,
    0.10F,
    0.95F,
  )
  let density = clampf(0.34F - brightness * 0.22F, 0.10F, 0.32F)

  @render3d.render3d_set_distance_fog(
    @render3d.DistanceFog::new(
      @render2d.Color::new(
        clamp01(0.06F + brightness * 0.42F),
        clamp01(0.06F + brightness * 0.40F),
        clamp01(0.08F + brightness * 0.50F),
        1.0F,
      ),
      @render3d.FogFalloff3d::exponential_squared(density),
    ),
  )
}

///|
fn move_directional_light(world : @ecs_world.World) -> Unit {
  let delta_time = @time.time_delta_seconds()
  let mut delta_x = 0.0F
  let mut delta_y = 0.0F

  if @input.key_pressed(@window.KeyCode::KeyW) ||
    @input.key_pressed(@window.KeyCode::ArrowUp) {
    delta_y = delta_y + DIRECTIONAL_LIGHT_MOVEMENT_SPEED * delta_time
  }
  if @input.key_pressed(@window.KeyCode::KeyS) ||
    @input.key_pressed(@window.KeyCode::ArrowDown) {
    delta_y = delta_y - DIRECTIONAL_LIGHT_MOVEMENT_SPEED * delta_time
  }
  if @input.key_pressed(@window.KeyCode::KeyA) ||
    @input.key_pressed(@window.KeyCode::ArrowLeft) {
    delta_x = delta_x + DIRECTIONAL_LIGHT_MOVEMENT_SPEED * delta_time
  }
  if @input.key_pressed(@window.KeyCode::KeyD) ||
    @input.key_pressed(@window.KeyCode::ArrowRight) {
    delta_x = delta_x - DIRECTIONAL_LIGHT_MOVEMENT_SPEED * delta_time
  }

  if delta_x == 0.0F && delta_y == 0.0F {
    return
  }

  if volumetric_fog_state.val.directional_light is Some(light_entity) {
    if world.get_transform_store().get(light_entity) is Some(light_transform) {
      let next_rotation = @math.Quat::from_rotation_y(delta_x)
        .mul(@math.Quat::from_rotation_x(delta_y))
        .mul(light_transform.rotation)
        .normalize()

      let tick = world.read_change_tick()
      world
      .get_transform_store()
      .set(light_entity, light_transform.with_rotation(next_rotation), tick)
      |> ignore
    }
  }

  apply_fog_proxy(world)
}

///|
fn move_point_light(world : @ecs_world.World) -> Unit {
  if volumetric_fog_state.val.point_light is Some(point_entity) {
    if world.get_transform_store().get(point_entity) is Some(point_transform) {
      let mut x = point_transform.translation.x +
        volumetric_fog_state.val.point_light_speed * @time.time_delta_seconds()

      if x > POINT_LIGHT_MAX_X {
        x = POINT_LIGHT_MAX_X
        volumetric_fog_state.val.point_light_speed = -volumetric_fog_state.val.point_light_speed
      } else if x < POINT_LIGHT_MIN_X {
        x = POINT_LIGHT_MIN_X
        volumetric_fog_state.val.point_light_speed = -volumetric_fog_state.val.point_light_speed
      }

      let tick = world.read_change_tick()
      world
      .get_transform_store()
      .set(
        point_entity,
        point_transform.with_translation(
          @math.Vec3::new(
            x,
            point_transform.translation.y,
            point_transform.translation.z,
          ),
        ),
        tick,
      )
      |> ignore
    }
  }

  apply_fog_proxy(world)
}

///|
fn adjust_app_settings(world : @ecs_world.World) -> Unit {
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::KeyP) {
    volumetric_fog_state.val.volumetric_pointlight = !volumetric_fog_state.val.volumetric_pointlight
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyL) {
    volumetric_fog_state.val.volumetric_spotlight = !volumetric_fog_state.val.volumetric_spotlight
    changed = true
  }

  if !changed {
    return
  }

  apply_light_switches(world)

  if volumetric_fog_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, create_text())
  }

  apply_fog_proxy(world)
}

///|
fn setup(world : @ecs_world.World) -> Unit {
  volumetric_fog_state.val = {
    volumetric_spotlight: true,
    volumetric_pointlight: true,
    camera: None,
    directional_light: None,
    point_light: None,
    spot_light: None,
    point_light_speed: POINT_LIGHT_INITIAL_SPEED,
    help_text: None,
  }

  let tick = world.read_change_tick()
  let ambient = world.get_global_ambient_light_resource()
  if ambient.get_ref_mut(tick) is Some(value) {
    value.val = @render3d.GlobalAmbientLight::new(
      @render2d.Color::white(),
      0.0F,
    )
  }

  setup_scene_geometry(world)
  setup_camera(world)
  setup_lights(world)
  setup_instructions(world)
  apply_light_switches(world)
  apply_fog_proxy(world)
}

///|
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(move_directional_light)
  .add_system(move_point_light)
  .add_system(adjust_app_settings)
  .run()
}
