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
fn transform_forward(transform : @transform.Transform) -> @math.Vec3 {
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
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  transform : @transform.Transform,
) -> Unit {
  @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    transform,
  ).spawn(world)
  |> ignore
}

///|
fn setup_scene_geometry(world : @ecs.World) -> Unit {
  let corridor_floor_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.10F, 0.10F, 0.11F, 1.0F),
    )
    .with_perceptual_roughness(0.95F)
    .with_metallic(0.0F),
  )

  let wall_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.16F, 0.16F, 0.18F, 1.0F),
    )
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )

  let block_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.42F, 0.45F, 0.48F, 1.0F),
    )
    .with_perceptual_roughness(0.6F)
    .with_metallic(0.0F),
  )

  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(7.0F, 0.2F, 11.0F),
        ),
      ),
    ),
    corridor_floor_material,
    @transform.Transform::from_xyz(-1.5F, -0.1F, 3.5F),
  )

  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(7.0F, 0.2F, 11.0F),
        ),
      ),
    ),
    wall_material,
    @transform.Transform::from_xyz(-1.5F, 3.9F, 3.5F),
  )

  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.2F, 4.0F, 11.0F),
        ),
      ),
    ),
    wall_material,
    @transform.Transform::from_xyz(-4.9F, 1.9F, 3.5F),
  )

  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(0.2F, 4.0F, 11.0F),
        ),
      ),
    ),
    wall_material,
    @transform.Transform::from_xyz(1.9F, 1.9F, 3.5F),
  )

  for i in 0..<8 {
    let z = -0.5F + float_from_int(i) * 1.2F
    spawn_mesh(
      world,
      @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(0.45F, 1.6F, 0.45F),
          ),
        ),
      ),
      block_material,
      @transform.Transform::from_xyz(-3.7F, 0.8F, z),
    )
    spawn_mesh(
      world,
      @pbr.Mesh3d::new(
        @pbr.mesh_assets_mut_or_abort().val.add(
          @pbr.Mesh::from_3d_geometry(
            @pbr.mesh3d_geometry_cuboid(0.45F, 1.6F, 0.45F),
          ),
        ),
      ),
      block_material,
      @transform.Transform::from_xyz(0.7F, 0.8F, z),
    )
  }

  let fog_volume_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.78F, 0.82F, 0.92F, 0.18F),
    )
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F)
    .with_emissive(@sprite.Color::new(0.08F, 0.08F, 0.10F, 1.0F)),
  )

  spawn_mesh(
    world,
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(5.0F, 3.8F, 10.0F),
        ),
      ),
    ),
    fog_volume_material,
    @transform.Transform::from_xyz(-1.5F, 1.9F, 3.5F),
  )
}

///|
fn setup_camera(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(-1.7F, 1.5F, 4.5F).looking_at(
      scene_focus(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_tonemapping,
    @post_process.Tonemapping::TonyMcMapface,
  )
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_bloom,
    @post_process.Bloom::default(),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      1000.0F,
    ),
  )
  volumetric_fog_state.val.camera = Some(camera)
}

///|
fn setup_lights(world : @ecs.World) -> Unit {
  let directional_light = world.spawn_empty()
  try! world.set_by_key(
    directional_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 4.3F, -1.5F).looking_at(
      scene_focus(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    directional_light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 15_000.0F, true),
  )
  volumetric_fog_state.val.directional_light = Some(directional_light)

  let point_light = world.spawn_empty()
  try! world.set_by_key(
    point_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-0.4F, 1.9F, 1.0F),
  )
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(
      @sprite.Color::new(1.0F, 0.15F, 0.15F, 1.0F),
      10_000.0F,
      150.0F,
      true,
    ),
  )
  volumetric_fog_state.val.point_light = Some(point_light)

  let spot_light = world.spawn_empty()
  try! world.set_by_key(
    spot_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(-1.8F, 3.9F, -2.7F).looking_at(
      @math.Vec3::new(-1.5F, 0.7F, 3.5F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  try! world.set_by_key(
    spot_light,
    @pbr.ecs_key_spot_light,
    @pbr.SpotLight::new(
      @sprite.Color::white(),
      50_000.0F,
      150.0F,
      0.76F,
      0.94F,
      true,
    ),
  )
  volumetric_fog_state.val.spot_light = Some(spot_light)
}

///|
fn setup_instructions(_world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let handle = @text.Text2dBundle::new(
      @text.Text2d::new(create_text()),
      @text.TextFont::default().with_font(font).with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, 320.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::top_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  volumetric_fog_state.val.help_text = Some(handle)
}

///|
fn apply_light_switches(world : @ecs.World) -> Unit {
  if volumetric_fog_state.val.point_light is Some(point_light) {
    if (try! world.get_by_key(point_light, @pbr.ecs_key_point_light))
      is Some(light) {
      try! (world.replace(
        point_light,
        @pbr.ecs_key_point_light,
        @pbr.PointLight::new(
          light.color,
          if volumetric_fog_state.val.volumetric_pointlight {
            10_000.0F
          } else {
            0.0F
          },
          light.range,
          volumetric_fog_state.val.volumetric_pointlight,
        ),
      )
      |> ignore)
    }
  }

  if volumetric_fog_state.val.spot_light is Some(spot_light) {
    if (try! world.get_by_key(spot_light, @pbr.ecs_key_spot_light))
      is Some(light) {
      try! (world.replace(
        spot_light,
        @pbr.ecs_key_spot_light,
        @pbr.SpotLight::new(
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
      )
      |> ignore)
    }
  }
}

///|
fn apply_fog_proxy(world : @ecs.World) -> Unit {
  let mut phase = 0.5F

  if volumetric_fog_state.val.camera is Some(camera_entity) {
    if volumetric_fog_state.val.directional_light is Some(light_entity) {
      if (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
        is Some(camera_transform) {
        if (try! world.get_by_key(light_entity, @transform.ecs_key_transform))
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

  let fog = @pbr.DistanceFog::new(
    @sprite.Color::new(
      clamp01(0.06F + brightness * 0.42F),
      clamp01(0.06F + brightness * 0.40F),
      clamp01(0.08F + brightness * 0.50F),
      1.0F,
    ),
    @pbr.FogFalloff3d::exponential_squared(density),
  )
  guard volumetric_fog_state.val.camera is Some(camera) else { return }
  let camera3d = match (try! world.get_by_key(camera, @pbr.ecs_key_camera3d)) {
    Some(value) => value
    None => @pbr.Camera3d::default()
  }
  try! (world.replace(
    camera,
    @pbr.ecs_key_camera3d,
    camera3d.with_distance_fog(Some(fog)),
  )
  |> ignore)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in volumetric_fog example")
  }
}

///|
fn move_directional_light(world : @ecs.World) -> Unit {
  let delta_time = world_time(world).delta_seconds()
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
    if (try! world.get_by_key(light_entity, @transform.ecs_key_transform))
      is Some(light_transform) {
      let next_rotation = @math.Quat::from_rotation_y(delta_x)
        .mul(@math.Quat::from_rotation_x(delta_y))
        .mul(light_transform.rotation)
        .normalize()

      try! (world.replace(
        light_entity,
        @transform.ecs_key_transform,
        light_transform.with_rotation(next_rotation),
      )
      |> ignore)
    }
  }

  apply_fog_proxy(world)
}

///|
fn move_point_light(world : @ecs.World) -> Unit {
  if volumetric_fog_state.val.point_light is Some(point_entity) {
    if (try! world.get_by_key(point_entity, @transform.ecs_key_transform))
      is Some(point_transform) {
      let mut x = point_transform.translation.x +
        volumetric_fog_state.val.point_light_speed *
        world_time(world).delta_seconds()

      if x > POINT_LIGHT_MAX_X {
        x = POINT_LIGHT_MAX_X
        volumetric_fog_state.val.point_light_speed = -volumetric_fog_state.val.point_light_speed
      } else if x < POINT_LIGHT_MIN_X {
        x = POINT_LIGHT_MIN_X
        volumetric_fog_state.val.point_light_speed = -volumetric_fog_state.val.point_light_speed
      }

      try! (world.replace(
        point_entity,
        @transform.ecs_key_transform,
        point_transform.with_translation(
          @math.Vec3::new(
            x,
            point_transform.translation.y,
            point_transform.translation.z,
          ),
        ),
      )
      |> ignore)
    }
  }

  apply_fog_proxy(world)
}

///|
fn adjust_app_settings(world : @ecs.World) -> Unit {
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
fn setup(world : @ecs.World) -> Unit {
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

  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(@sprite.Color::white(), 0.0F),
  )

  setup_scene_geometry(world)
  setup_camera(world)
  setup_lights(world)
  setup_instructions(world)
  apply_light_switches(world)
  apply_fog_proxy(world)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(move_directional_light))
  .add_systems(@app.Update, @app.system(move_point_light))
  .add_systems(@app.Update, @app.system(adjust_app_settings))
  .run()
}
