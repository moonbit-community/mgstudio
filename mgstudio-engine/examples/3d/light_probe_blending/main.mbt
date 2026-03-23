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
/// Port of `bevy/examples/3d/light_probe_blending.rs`.
///
/// Baseline parity:
/// - Bevy's light-probe components (`LightProbe`, `EnvironmentMapLight`,
///   `ParallaxCorrection`) are mapped with Bevy-shaped APIs.
/// - UI widgets are adapted to keyboard controls in this runtime.
/// - Camera orbit/free-look consume unified primary-pointer delta APIs for
///   better behavior consistency across web and wasmtime backends.
/// - Bevy asset files for this example are vendored under
///   `assets/light_probe_blending/`.

///|
const PI : Float = 3.141592653589793F

///|
const FRAC_PI_4 : Float = 0.7853981633974483F

///|
const SPHERE_MOVEMENT_SPEED : Float = 0.3F

///|
const ROOM_SEPARATION : Float = 11.0F

///|
const LIGHT_PROBE_SIDE_LENGTH : Float = 15.0F

///|
const LIGHT_PROBE_FALLOFF : Float = 0.5F

///|
const LIGHT_PROBE_PARALLAX_CORRECTION_SIDE_LENGTH : Float = 0.3433333333333333F

///|
const LIGHT_PROBE_INTENSITY : Float = 500.0F

///|
const CAMERA_ORBIT_SPEED_INCLINATION : Float = 0.003F

///|
const CAMERA_ORBIT_SPEED_AZIMUTH : Float = 0.004F

///|
const CAMERA_ZOOM_SPEED : Float = 0.15F

///|
const CAMERA_FREE_LOOK_SPEED_INCLINATION : Float = 0.003F

///|
const CAMERA_FREE_LOOK_SPEED_AZIMUTH : Float = 0.004F

///|
const CAMERA_FREE_MOVE_SPEED : Float = 3.0F

///|
const CAMERA_FREE_PITCH_LIMIT : Float = 1.50F

///|
const LIGHT_PROBE_SCENE_ASSET : String = "light_probe_blending/two_rooms.glb"

///|
const DIFFUSE_ROOM1_ASSET : String = "light_probe_blending/diffuse_room1.ktx2"

///|
const SPECULAR_ROOM1_ASSET : String = "light_probe_blending/specular_room1.ktx2"

///|
const DIFFUSE_ROOM2_ASSET : String = "light_probe_blending/diffuse_room2.ktx2"

///|
const SPECULAR_ROOM2_ASSET : String = "light_probe_blending/specular_room2.ktx2"

///|
pub(all) enum GizmosEnabled {
  On
  Off
} derive(Eq, Show)

///|
pub(all) enum ObjectToShow {
  Sphere
  Prism
} derive(Eq, Show)

///|
pub(all) enum CameraMode {
  Orbit
  Free
} derive(Eq, Show)

///|
priv struct LightProbeBlendingState {
  mut camera : @core.Entity?
  mut sphere : @core.Entity?
  mut prism : @core.Entity?
  mut help_text : @text.TextHandle?
  mut gizmos_enabled : GizmosEnabled
  mut object_to_show : ObjectToShow
  mut camera_mode : CameraMode
  mut orbit_radius : Float
  mut orbit_inclination : Float
  mut orbit_azimuth : Float
  mut free_position : @math.Vec3
  mut free_pitch : Float
  mut free_yaw : Float
  gizmo_entities : Array[@core.Entity]
}

///|
let light_probe_blending_state : Ref[LightProbeBlendingState] = Ref::new({
  camera: None,
  sphere: None,
  prism: None,
  help_text: None,
  gizmos_enabled: GizmosEnabled::On,
  object_to_show: ObjectToShow::Sphere,
  camera_mode: CameraMode::Orbit,
  orbit_radius: 3.0F,
  orbit_inclination: 7.0F * FRAC_PI_4,
  orbit_azimuth: FRAC_PI_4,
  free_position: @math.Vec3::new(0.0F, 0.0F, 0.0F),
  free_pitch: 0.0F,
  free_yaw: 0.0F,
  gizmo_entities: [],
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

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
fn maxf(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn set_global_ambient_light(
  world : @ecs.World,
  color : @sprite.Color,
  brightness : Float,
) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(color, brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
}

///|
fn set_entity_visibility(
  world : @ecs.World,
  entity : @core.Entity,
  visible : Bool,
) -> Unit {
  let visibility = if visible {
    @visibility.Visibility::Inherited
  } else {
    @visibility.Visibility::Hidden
  }
  let store = world.component(@visibility.ecs_key_visibility)
  if store.contains(entity) {
    store.set(entity, visibility) |> ignore
  } else {
    store.insert(entity, visibility)
  }
}

///|
fn set_optional_visibility(
  world : @ecs.World,
  entity : @core.Entity?,
  visible : Bool,
) -> Unit {
  if entity is Some(actual) {
    set_entity_visibility(world, actual, visible)
  }
}

///|
fn set_entities_visibility(
  world : @ecs.World,
  entities : Array[@core.Entity],
  visible : Bool,
) -> Unit {
  for entity in entities {
    set_entity_visibility(world, entity, visible)
  }
}

///|
fn apply_object_visibility(world : @ecs.World) -> Unit {
  let show_sphere = light_probe_blending_state.val.object_to_show ==
    ObjectToShow::Sphere
  set_optional_visibility(
    world,
    light_probe_blending_state.val.sphere,
    show_sphere,
  )
  set_optional_visibility(
    world,
    light_probe_blending_state.val.prism,
    !show_sphere,
  )
}

///|
fn apply_gizmo_visibility(world : @ecs.World) -> Unit {
  set_entities_visibility(
    world,
    light_probe_blending_state.val.gizmo_entities,
    light_probe_blending_state.val.gizmos_enabled == GizmosEnabled::On,
  )
}

///|
fn help_text_content() -> String {
  let camera_mode_text = if light_probe_blending_state.val.camera_mode ==
    CameraMode::Orbit {
    "Orbit"
  } else {
    "Free"
  }
  let object_text = if light_probe_blending_state.val.object_to_show ==
    ObjectToShow::Sphere {
    "Sphere"
  } else {
    "Prism"
  }
  let gizmos_text = if light_probe_blending_state.val.gizmos_enabled ==
    GizmosEnabled::On {
    "On"
  } else {
    "Off"
  }

  "Light Probe Blending (Bevy-adapted controls)\n" +
  "Tab: Object (Sphere/Prism) = " +
  object_text +
  "\n" +
  "G: Gizmos = " +
  gizmos_text +
  "\n" +
  "C: Camera Mode (Orbit/Free) = " +
  camera_mode_text +
  "\n" +
  "\n" +
  "Orbit: Hold primary pointer to orbit, wheel to zoom\n" +
  "Free: Hold primary pointer to look, WASDEQ to move\n" +
  "\n" +
  "Gizmo colors: Tan=Probe bounds, Red=Falloff, Blue=Parallax bounds"
}

///|
fn update_help_text() -> Unit {
  if light_probe_blending_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, help_text_content())
  }
}

///|
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @pbr.Mesh3d {
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let indices : Array[Int] = []

  let stacks_f = float_from_int(stacks)
  let sectors_f = float_from_int(sectors)
  let stack_step = PI / stacks_f
  let sector_step = 2.0F * PI / sectors_f

  for i in 0..<(stacks + 1) {
    let stack_angle = PI / 2.0F - float_from_int(i) * stack_step
    let ring_radius = radius * @math.cos(stack_angle)
    let y = radius * @math.sin(stack_angle)
    for j in 0..<(sectors + 1) {
      let sector_angle = float_from_int(j) * sector_step
      let x = ring_radius * @math.cos(sector_angle)
      let z = ring_radius * @math.sin(sector_angle)
      positions.push(@math.Vec3::new(x, y, z))
      uvs.push(
        @math.Vec2::new(
          float_from_int(j) / sectors_f,
          float_from_int(i) / stacks_f,
        ),
      )
    }
  }

  let row = sectors + 1
  for i in 0..<stacks {
    let k1 = i * row
    let k2 = k1 + row
    for j in 0..<sectors {
      if i != 0 {
        indices.push(k1 + j)
        indices.push(k2 + j)
        indices.push(k1 + j + 1)
      }
      if i != stacks - 1 {
        indices.push(k1 + j + 1)
        indices.push(k2 + j)
        indices.push(k2 + j + 1)
      }
    }
  }

  @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(
        @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
      ),
    ),
  )
}

///|
fn spawn_probe_gizmo_box(
  world : @ecs.World,
  material : @asset.Handle[@pbr.StandardMaterial],
  side : Float,
  center_z : Float,
) -> @core.Entity {
  @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(side, side, side),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(0.0F, 0.0F, center_z),
  ).spawn(world)
}

///|
fn sphere_position(world : @ecs.World) -> @math.Vec3 {
  if light_probe_blending_state.val.sphere is Some(entity) {
    if world.component(@transform.ecs_key_transform).get(entity)
      is Some(transform) {
      return transform.translation
    }
  }
  @math.Vec3::zero()
}

///|
fn write_orbit_camera_transform(world : @ecs.World) -> Unit {
  guard light_probe_blending_state.val.camera is Some(camera_entity) else {
    return
  }

  let target = sphere_position(world)
  let radius = light_probe_blending_state.val.orbit_radius
  let inclination = light_probe_blending_state.val.orbit_inclination
  let azimuth = light_probe_blending_state.val.orbit_azimuth

  let translation = @math.Vec3::new(
    radius * @math.sin(inclination) * @math.cos(azimuth),
    radius * @math.cos(inclination),
    radius * @math.sin(inclination) * @math.sin(azimuth),
  ).add(target)

  world
  .component(@transform.ecs_key_transform)
  .set(
    camera_entity,
    @transform.Transform::from_xyz(translation.x, translation.y, translation.z).looking_at(
      target,
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore
}

///|
fn write_free_camera_transform(
  world : @ecs.World,
  forward : @math.Vec3,
) -> Unit {
  guard light_probe_blending_state.val.camera is Some(camera_entity) else {
    return
  }

  let position = light_probe_blending_state.val.free_position
  world
  .component(@transform.ecs_key_transform)
  .set(
    camera_entity,
    @transform.Transform::from_xyz(position.x, position.y, position.z).looking_at(
      position.add(forward),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  |> ignore
}

///|
fn switch_to_free_camera(world : @ecs.World) -> Unit {
  guard light_probe_blending_state.val.camera is Some(camera_entity) else {
    return
  }
  guard world.component(@transform.ecs_key_transform).get(camera_entity)
    is Some(camera_transform) else {
    return
  }

  let target = sphere_position(world)
  let direction = target.sub(camera_transform.translation).normalize_or_zero()
  let horizontal = @math.sqrt(
    direction.x * direction.x + direction.z * direction.z,
  )

  light_probe_blending_state.val.camera_mode = CameraMode::Free
  light_probe_blending_state.val.free_position = camera_transform.translation
  light_probe_blending_state.val.free_pitch = @math.atan2(
    direction.y,
    horizontal,
  )
  light_probe_blending_state.val.free_yaw = @math.atan2(
    direction.x,
    direction.z,
  )
}

///|
fn switch_to_orbit_camera(world : @ecs.World) -> Unit {
  guard light_probe_blending_state.val.camera is Some(camera_entity) else {
    return
  }
  guard world.component(@transform.ecs_key_transform).get(camera_entity)
    is Some(camera_transform) else {
    return
  }

  let target = sphere_position(world)
  let relative = camera_transform.translation.sub(target)
  let radius = maxf(relative.length(), 0.01F)
  let horizontal = @math.sqrt(relative.x * relative.x + relative.z * relative.z)

  light_probe_blending_state.val.camera_mode = CameraMode::Orbit
  light_probe_blending_state.val.orbit_radius = radius
  if radius > 1.0e-6F {
    light_probe_blending_state.val.orbit_inclination = @math.atan2(
      horizontal / radius,
      relative.y / radius,
    )
  }
  if horizontal > 1.0e-6F {
    light_probe_blending_state.val.orbit_azimuth = @math.atan2(
      relative.z / horizontal,
      relative.x / horizontal,
    )
  }
}

///|
fn spawn_scene(world : @ecs.World) -> Unit {
  light_probe_blending_state.val.gizmo_entities.clear()

  let asset_server = @asset.AssetServer::new()

  set_global_ambient_light(world, @sprite.Color::white(), 0.06F)

  let room_scene = @scene.scene_load_gltf_scene(
    asset_server,
    @gltf.GltfAssetLabel::Scene(0).from_asset(LIGHT_PROBE_SCENE_ASSET),
  )
  let room_scene_entity = world.spawn_empty()
  world
  .component(@scene.ecs_key_scene_root)
  .insert(room_scene_entity, @scene.SceneRoot::new(room_scene))

  let reflective_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white())
    .with_metallic(1.0F)
    .with_reflectance(1.0F)
    .with_perceptual_roughness(0.0F),
  )

  let sphere = @pbr.MeshMaterial3dBundle::new(
    uv_sphere_mesh(1.0F, 18, 32),
    @pbr.MeshMaterial3d::new(reflective_material),
    @transform.Transform::identity(),
  ).spawn(world)
  light_probe_blending_state.val.sphere = Some(sphere)

  let prism = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(4.0F, 2.0F, 20.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(reflective_material),
    @transform.Transform::from_xyz(0.0F, -4.0F, -5.5F),
  ).spawn(world)
  light_probe_blending_state.val.prism = Some(prism)

  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::identity(),
  ).spawn(world)
  light_probe_blending_state.val.camera = Some(camera)

  let directional = world.spawn_empty()
  world
  .component(@pbr.ecs_key_directional_light)
  .insert(
    directional,
    @pbr.DirectionalLight::new(@sprite.Color::white(), 10_000.0F, true),
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(
    directional,
    @transform.Transform::from_xyz(3.0F, 6.0F, 4.0F).looking_at(
      @math.Vec3::new(0.0F, -1.5F, -5.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let diffuse_room1 = Some(asset_server.load(DIFFUSE_ROOM1_ASSET))
  let specular_room1 = Some(asset_server.load(SPECULAR_ROOM1_ASSET))
  let diffuse_room2 = Some(asset_server.load(DIFFUSE_ROOM2_ASSET))
  let specular_room2 = Some(asset_server.load(SPECULAR_ROOM2_ASSET))

  let probe_1 = world.spawn_empty()
  world
  .component(@pbr.ecs_key_light_probe)
  .insert(
    probe_1,
    @pbr.LightProbe::default().with_falloff(
      @math.Vec3::splat(LIGHT_PROBE_FALLOFF),
    ),
  )
  world
  .component(@pbr.ecs_key_environment_map_light)
  .insert(
    probe_1,
    @pbr.EnvironmentMapLight::new(
      diffuse_room1,
      specular_room1,
      LIGHT_PROBE_INTENSITY,
    ),
  )
  world
  .component(@pbr.ecs_key_parallax_correction)
  .insert(
    probe_1,
    @pbr.ParallaxCorrection::Custom(
      @math.Vec3::splat(LIGHT_PROBE_PARALLAX_CORRECTION_SIDE_LENGTH),
    ),
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(
    probe_1,
    @transform.Transform::identity()
    .with_scale(
      @math.Vec3::new(1.0F, -1.0F, 1.0F).mul_scalar(LIGHT_PROBE_SIDE_LENGTH),
    )
    .with_rotation(@math.Quat::from_rotation_x(PI)),
  )

  let probe_2 = world.spawn_empty()
  world
  .component(@pbr.ecs_key_light_probe)
  .insert(
    probe_2,
    @pbr.LightProbe::default().with_falloff(
      @math.Vec3::splat(LIGHT_PROBE_FALLOFF),
    ),
  )
  world
  .component(@pbr.ecs_key_environment_map_light)
  .insert(
    probe_2,
    @pbr.EnvironmentMapLight::new(
      diffuse_room2,
      specular_room2,
      LIGHT_PROBE_INTENSITY,
    ),
  )
  world
  .component(@pbr.ecs_key_parallax_correction)
  .insert(
    probe_2,
    @pbr.ParallaxCorrection::Custom(
      @math.Vec3::splat(LIGHT_PROBE_PARALLAX_CORRECTION_SIDE_LENGTH),
    ),
  )
  world
  .component(@transform.ecs_key_transform)
  .insert(
    probe_2,
    @transform.Transform::identity()
    .with_scale(
      @math.Vec3::new(1.0F, -1.0F, 1.0F).mul_scalar(LIGHT_PROBE_SIDE_LENGTH),
    )
    .with_rotation(@math.Quat::from_rotation_x(PI))
    .with_translation(@math.Vec3::new(0.0F, 0.0F, -ROOM_SEPARATION)),
  )

  let bounds_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.82F, 0.71F, 0.55F, 0.16F),
    )
    .with_unlit(true)
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )
  let falloff_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.86F, 0.14F, 0.22F, 0.18F),
    )
    .with_unlit(true)
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )
  let parallax_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.39F, 0.58F, 0.93F, 0.18F),
    )
    .with_unlit(true)
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_perceptual_roughness(1.0F)
    .with_metallic(0.0F),
  )

  let falloff_side = LIGHT_PROBE_SIDE_LENGTH * (1.0F - LIGHT_PROBE_FALLOFF)
  let parallax_side = LIGHT_PROBE_SIDE_LENGTH *
    LIGHT_PROBE_PARALLAX_CORRECTION_SIDE_LENGTH

  light_probe_blending_state.val.gizmo_entities.push(
    spawn_probe_gizmo_box(world, bounds_material, LIGHT_PROBE_SIDE_LENGTH, 0.0F),
  )
  light_probe_blending_state.val.gizmo_entities.push(
    spawn_probe_gizmo_box(world, falloff_material, falloff_side, 0.0F),
  )
  light_probe_blending_state.val.gizmo_entities.push(
    spawn_probe_gizmo_box(world, parallax_material, parallax_side, 0.0F),
  )

  light_probe_blending_state.val.gizmo_entities.push(
    spawn_probe_gizmo_box(
      world,
      bounds_material,
      LIGHT_PROBE_SIDE_LENGTH,
      -ROOM_SEPARATION,
    ),
  )
  light_probe_blending_state.val.gizmo_entities.push(
    spawn_probe_gizmo_box(
      world,
      falloff_material,
      falloff_side,
      -ROOM_SEPARATION,
    ),
  )
  light_probe_blending_state.val.gizmo_entities.push(
    spawn_probe_gizmo_box(
      world,
      parallax_material,
      parallax_side,
      -ROOM_SEPARATION,
    ),
  )

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
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
  light_probe_blending_state.val.help_text = Some(help_text)
}

///|
fn setup(world : @ecs.World) -> Unit {
  light_probe_blending_state.val.camera = None
  light_probe_blending_state.val.sphere = None
  light_probe_blending_state.val.prism = None
  light_probe_blending_state.val.help_text = None
  light_probe_blending_state.val.gizmos_enabled = GizmosEnabled::On
  light_probe_blending_state.val.object_to_show = ObjectToShow::Sphere
  light_probe_blending_state.val.camera_mode = CameraMode::Orbit
  light_probe_blending_state.val.orbit_radius = 3.0F
  light_probe_blending_state.val.orbit_inclination = 7.0F * FRAC_PI_4
  light_probe_blending_state.val.orbit_azimuth = FRAC_PI_4
  light_probe_blending_state.val.free_position = @math.Vec3::zero()
  light_probe_blending_state.val.free_pitch = 0.0F
  light_probe_blending_state.val.free_yaw = 0.0F
  light_probe_blending_state.val.gizmo_entities.clear()

  spawn_scene(world)
  apply_object_visibility(world)
  apply_gizmo_visibility(world)
  update_help_text()
  write_orbit_camera_transform(world)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in light_probe_blending example")
  }
}

///|
fn move_sphere(world : @ecs.World) -> Unit {
  guard light_probe_blending_state.val.sphere is Some(entity) else { return }

  let t = (
      @math.sin(
        world_time(world).elapsed_seconds() * SPHERE_MOVEMENT_SPEED * PI,
      ) +
      1.0F
    ) *
    0.5F
  world
  .component(@transform.ecs_key_transform)
  .set(entity, @transform.Transform::from_xyz(0.0F, 0.0F, -ROOM_SEPARATION * t))
  |> ignore
}

///|
fn handle_keyboard_actions(world : @ecs.World) -> Unit {
  let mut changed = false

  if @input.key_just_pressed(@window.KeyCode::Tab) {
    if light_probe_blending_state.val.object_to_show == ObjectToShow::Sphere {
      light_probe_blending_state.val.object_to_show = ObjectToShow::Prism
    } else {
      light_probe_blending_state.val.object_to_show = ObjectToShow::Sphere
    }
    apply_object_visibility(world)
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyG) {
    if light_probe_blending_state.val.gizmos_enabled == GizmosEnabled::On {
      light_probe_blending_state.val.gizmos_enabled = GizmosEnabled::Off
    } else {
      light_probe_blending_state.val.gizmos_enabled = GizmosEnabled::On
    }
    apply_gizmo_visibility(world)
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyC) {
    if light_probe_blending_state.val.camera_mode == CameraMode::Orbit {
      switch_to_free_camera(world)
    } else {
      switch_to_orbit_camera(world)
      write_orbit_camera_transform(world)
    }
    changed = true
  }

  if changed {
    update_help_text()
  }
}

///|
fn orbit_camera(world : @ecs.World) -> Unit {
  if light_probe_blending_state.val.camera_mode != CameraMode::Orbit {
    return
  }

  if @input.primary_pointer_pressed() {
    let delta = @input.primary_pointer_delta()
    light_probe_blending_state.val.orbit_azimuth = light_probe_blending_state.val.orbit_azimuth -
      delta.x * CAMERA_ORBIT_SPEED_AZIMUTH
    light_probe_blending_state.val.orbit_inclination = clampf(
      light_probe_blending_state.val.orbit_inclination +
      delta.y * CAMERA_ORBIT_SPEED_INCLINATION,
      0.05F,
      PI - 0.05F,
    )
  }

  let wheel = @input.mouse_wheel_delta()
  light_probe_blending_state.val.orbit_radius = maxf(
    0.5F,
    light_probe_blending_state.val.orbit_radius - wheel.y * CAMERA_ZOOM_SPEED,
  )

  write_orbit_camera_transform(world)
}

///|
fn free_camera(world : @ecs.World) -> Unit {
  if light_probe_blending_state.val.camera_mode != CameraMode::Free {
    return
  }

  if @input.primary_pointer_pressed() {
    let delta = @input.primary_pointer_delta()
    light_probe_blending_state.val.free_yaw = light_probe_blending_state.val.free_yaw -
      delta.x * CAMERA_FREE_LOOK_SPEED_AZIMUTH
    light_probe_blending_state.val.free_pitch = clampf(
      light_probe_blending_state.val.free_pitch -
      delta.y * CAMERA_FREE_LOOK_SPEED_INCLINATION,
      -CAMERA_FREE_PITCH_LIMIT,
      CAMERA_FREE_PITCH_LIMIT,
    )
  }

  let cos_pitch = @math.cos(light_probe_blending_state.val.free_pitch)
  let forward = @math.Vec3::new(
    @math.sin(light_probe_blending_state.val.free_yaw) * cos_pitch,
    @math.sin(light_probe_blending_state.val.free_pitch),
    @math.cos(light_probe_blending_state.val.free_yaw) * cos_pitch,
  )
  let forward_flat = @math.Vec3::new(forward.x, 0.0F, forward.z).normalize_or_zero()
  let right = @math.Vec3::new(forward_flat.z, 0.0F, -forward_flat.x)

  let mut movement = @math.Vec3::zero()
  if @input.key_pressed(@window.KeyCode::KeyW) {
    movement = movement.add(forward_flat)
  }
  if @input.key_pressed(@window.KeyCode::KeyS) {
    movement = movement.sub(forward_flat)
  }
  if @input.key_pressed(@window.KeyCode::KeyD) {
    movement = movement.add(right)
  }
  if @input.key_pressed(@window.KeyCode::KeyA) {
    movement = movement.sub(right)
  }
  if @input.key_pressed(@window.KeyCode::KeyE) {
    movement = movement.add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  if @input.key_pressed(@window.KeyCode::KeyQ) {
    movement = movement.sub(@math.Vec3::new(0.0F, 1.0F, 0.0F))
  }

  if movement.length_squared() > 0.0F {
    light_probe_blending_state.val.free_position = light_probe_blending_state.val.free_position.add(
      movement
      .normalize_or_zero()
      .mul_scalar(CAMERA_FREE_MOVE_SPEED * world_time(world).delta_seconds()),
    )
  }

  write_free_camera_transform(world, forward)
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(move_sphere))
  .add_systems(@app.Update, @app.system(handle_keyboard_actions))
  .add_systems(@app.Update, @app.system(orbit_camera))
  .add_systems(@app.Update, @app.system(free_camera))
  .run()
}
