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
/// Baseline parity:
/// - Bevy's voxel irradiance transfer and shader-based voxel visualization are
///   represented as runtime proxies in current mgstudio backend.
/// - Fox animation playback and gizmo line rendering are not exposed yet.
/// - Control model and scene interaction flow are aligned (`Space/Enter/Tab`,
///   `Backspace`, and click-to-move).

///|
const PI : Float = 3.141592653589793F

///|
const ROTATION_SPEED : Float = 0.2F

///|
const FOX_SCALE : Float = 0.05F

///|
const SPHERE_SCALE : Float = 6.0F

///|
const IRRADIANCE_VOLUME_INTENSITY : Float = 1800.0F

///|
const AMBIENT_LIGHT_BRIGHTNESS : Float = 0.06F

///|
const VOXEL_CUBE_SCALE : Float = 0.4F

///|
const VOXEL_COUNT_X : Int = 8

///|
const VOXEL_COUNT_Y : Int = 4

///|
const VOXEL_COUNT_Z : Int = 8

///|
const VOXEL_VOLUME_CENTER_X : Float = 0.0F

///|
const VOXEL_VOLUME_CENTER_Y : Float = 1.3F

///|
const VOXEL_VOLUME_CENTER_Z : Float = 0.0F

///|
const VOXEL_VOLUME_SIZE_X : Float = 4.8F

///|
const VOXEL_VOLUME_SIZE_Y : Float = 2.4F

///|
const VOXEL_VOLUME_SIZE_Z : Float = 4.8F

///|
const CLICK_TO_MOVE_HELP_TEXT : String = "Left click: Move the object"

///|
const HIDE_VOXELS_HELP_TEXT : String = "Backspace: Hide the voxels"

///|
const SHOW_VOXELS_HELP_TEXT : String = "Backspace: Show the voxels"

///|
const DISABLE_IRRADIANCE_VOLUME_HELP_TEXT : String = "Space: Disable the irradiance volume"

///|
const ENABLE_IRRADIANCE_VOLUME_HELP_TEXT : String = "Space: Enable the irradiance volume"

///|
const STOP_ROTATION_HELP_TEXT : String = "Enter: Stop rotation"

///|
const START_ROTATION_HELP_TEXT : String = "Enter: Start rotation"

///|
const SWITCH_TO_FOX_HELP_TEXT : String = "Tab: Switch to a skinned mesh"

///|
const SWITCH_TO_SPHERE_HELP_TEXT : String = "Tab: Switch to a plain sphere mesh"

///|
pub(all) enum ExampleModel {
  Sphere
  Fox
} derive(Eq, Show)

///|
priv struct IrradianceVolumesState {
  mut irradiance_volume_present : Bool
  mut model : ExampleModel
  mut rotating : Bool
  mut voxels_visible : Bool
  mut camera : @core.Entity?
  mut light_probe : @core.Entity?
  mut sphere : @core.Entity?
  mut fox : @core.Entity?
  mut irradiance_texture : @asset.Handle[@asset.Image]?
  voxel_cubes : Array[@core.Entity]
  mut help_text : @text.TextHandle?
}

///|
fn default_state() -> IrradianceVolumesState {
  {
    irradiance_volume_present: true,
    model: ExampleModel::Sphere,
    rotating: true,
    voxels_visible: false,
    camera: None,
    light_probe: None,
    sphere: None,
    fox: None,
    irradiance_texture: None,
    voxel_cubes: [],
    help_text: None,
  }
}

///|
let irradiance_volumes_state : Ref[IrradianceVolumesState] = Ref::new(
  default_state(),
)

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn example_model_eq(lhs : ExampleModel, rhs : ExampleModel) -> Bool {
  if lhs is Sphere {
    rhs is Sphere
  } else {
    rhs is Fox
  }
}

///|
fn create_help_text() -> String {
  let irradiance_volume_help_text = if irradiance_volumes_state.val.irradiance_volume_present {
    DISABLE_IRRADIANCE_VOLUME_HELP_TEXT
  } else {
    ENABLE_IRRADIANCE_VOLUME_HELP_TEXT
  }
  let voxels_help_text = if irradiance_volumes_state.val.voxels_visible {
    HIDE_VOXELS_HELP_TEXT
  } else {
    SHOW_VOXELS_HELP_TEXT
  }
  let rotation_help_text = if irradiance_volumes_state.val.rotating {
    STOP_ROTATION_HELP_TEXT
  } else {
    START_ROTATION_HELP_TEXT
  }
  let switch_mesh_help_text = if example_model_eq(
      irradiance_volumes_state.val.model,
      ExampleModel::Sphere,
    ) {
    SWITCH_TO_FOX_HELP_TEXT
  } else {
    SWITCH_TO_SPHERE_HELP_TEXT
  }
  "\{CLICK_TO_MOVE_HELP_TEXT}\n\{voxels_help_text}\n\{irradiance_volume_help_text}\n\{rotation_help_text}\n\{switch_mesh_help_text}"
}

///|
fn update_help_text() -> Unit {
  if irradiance_volumes_state.val.help_text is Some(help_text) {
    @text.text_set_content(help_text, create_help_text())
  }
}

///|
fn set_global_ambient_light(world : @ecs.World, brightness : Float) -> Unit {
  let ambient = @pbr.GlobalAmbientLight::new(@sprite.Color::white(), brightness)
  world.insert_resource(@pbr.ecs_key_global_ambient_light, ambient)
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
fn set_entity_visibility(
  world : @ecs.World,
  entity : @core.Entity?,
  visible : Bool,
) -> Unit {
  guard entity is Some(target) else { return }
  let value = if visible {
    @visibility.Visibility::Visible
  } else {
    @visibility.Visibility::Hidden
  }
  try! world.set_by_key(target, @visibility.ecs_key_visibility, value)
}

///|
fn spawn_main_scene(
  world : @ecs.World,
  asset_server : @asset.AssetServer,
) -> Unit {
  let scene = @scene.scene_load_gltf_scene(
    asset_server,
    @gltf.GltfAssetLabel::Scene(0).from_asset(
      "models/IrradianceVolumeExample/IrradianceVolumeExample.glb",
    ),
  )
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(scene),
  )
}

///|
fn spawn_camera(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let camera = @pbr.Camera3dBundle::new(
    @sprite.Camera::default().with_clear_color(
      @sprite.Color::srgb(0.18F, 0.20F, 0.24F),
    ),
    @transform.Transform::from_xyz(-10.012F, 4.8605F, 13.281F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  irradiance_volumes_state.val.camera = Some(camera)
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      150.0F,
    ),
  )
}

///|
fn spawn_irradiance_volume(
  world : @ecs.World,
  irradiance_texture : @asset.Handle[@asset.Image],
) -> Unit {
  let entity = world.spawn_empty()
  irradiance_volumes_state.val.light_probe = Some(entity)
  try! world.set_by_key(
    entity,
    @pbr.ecs_key_light_probe,
    @pbr.LightProbe::default(),
  )
  try! world.set_by_key(
    entity,
    @pbr.ecs_key_irradiance_volume,
    @pbr.IrradianceVolume::new(
      Some(irradiance_texture),
      IRRADIANCE_VOLUME_INTENSITY,
    ),
  )
  try! world.set_by_key(
    entity,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(
      VOXEL_VOLUME_CENTER_X,
      VOXEL_VOLUME_CENTER_Y,
      VOXEL_VOLUME_CENTER_Z,
    ).with_scale(
      @math.Vec3::new(
        VOXEL_VOLUME_SIZE_X,
        VOXEL_VOLUME_SIZE_Y,
        VOXEL_VOLUME_SIZE_Z,
      ),
    ),
  )
}

///|
fn spawn_light(world : @ecs.World) -> Unit {
  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@sprite.Color::white(), 250_000.0F, 100.0F, true),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(4.0762F, 5.9039F, 1.0055F),
  )
}

///|
fn spawn_sphere(world : @ecs.World) -> Unit {
  let material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.85F, 0.95F, 1.0F, 1.0F),
    ).with_unlit(true),
  )
  let sphere = @pbr.MeshMaterial3dBundle::new(
    uv_sphere_mesh(1.0F, 24, 36),
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(0.0F, SPHERE_SCALE, 0.0F).with_scale(
      @math.Vec3::splat(SPHERE_SCALE),
    ),
  ).spawn(world)
  irradiance_volumes_state.val.sphere = Some(sphere)
}

///|
fn spawn_fox(world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let fox = world.spawn_empty()
  irradiance_volumes_state.val.fox = Some(fox)
  try! world.set_by_key(
    fox,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset("models/animated/Fox.glb"),
      ),
    ),
  )
  try! world.set_by_key(
    fox,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_scale(
      @math.Vec3::splat(FOX_SCALE),
    ),
  )
  set_entity_visibility(world, Some(fox), false)
}

///|
fn spawn_voxel_cubes(world : @ecs.World) -> Unit {
  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.2F, 0.2F, 0.75F),
    )
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @pbr.Mesh::from_3d_geometry(@pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F)),
    ),
  )
  for z in 0..<VOXEL_COUNT_Z {
    for y in 0..<VOXEL_COUNT_Y {
      for x in 0..<VOXEL_COUNT_X {
        let fx = (float_from_int(x) + 0.5F) / float_from_int(VOXEL_COUNT_X) -
          0.5F
        let fy = (float_from_int(y) + 0.5F) / float_from_int(VOXEL_COUNT_Y) -
          0.5F
        let fz = (float_from_int(z) + 0.5F) / float_from_int(VOXEL_COUNT_Z) -
          0.5F
        let position = @math.Vec3::new(
          VOXEL_VOLUME_CENTER_X + fx * VOXEL_VOLUME_SIZE_X,
          VOXEL_VOLUME_CENTER_Y + fy * VOXEL_VOLUME_SIZE_Y,
          VOXEL_VOLUME_CENTER_Z + fz * VOXEL_VOLUME_SIZE_Z,
        )
        let entity = @pbr.MeshMaterial3dBundle::new(
          mesh,
          @pbr.MeshMaterial3d::new(cube_material),
          @transform.Transform::from_xyz(position.x, position.y, position.z).with_scale(
            @math.Vec3::splat(VOXEL_CUBE_SCALE),
          ),
        ).spawn(world)
        try! world.set_by_key(
          entity,
          @pbr.ecs_key_not_shadow_caster,
          @pbr.NotShadowCaster::default(),
        )
        irradiance_volumes_state.val.voxel_cubes.push(entity)
      }
    }
  }
  for i in 0..<irradiance_volumes_state.val.voxel_cubes.length() {
    set_entity_visibility(
      world,
      Some(irradiance_volumes_state.val.voxel_cubes[i]),
      false,
    )
  }
}

///|
fn spawn_text(_world : @ecs.World, asset_server : @asset.AssetServer) -> Unit {
  let text = @text.Text2dBundle::new(
      @text.Text2d::new(create_help_text()),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(15.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -285.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(@text.TextColor::new(@sprite.Color::white()))
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  irradiance_volumes_state.val.help_text = Some(text)
}

///|
fn setup(world : @ecs.World) -> Unit {
  irradiance_volumes_state.val = default_state()
  let asset_server = @asset.AssetServer::new()
  let irradiance_texture = asset_server.load(
    "irradiance_volumes/Example.vxgi.ktx2",
  )
  irradiance_volumes_state.val.irradiance_texture = Some(irradiance_texture)

  spawn_main_scene(world, asset_server)
  spawn_camera(world, asset_server)
  spawn_irradiance_volume(world, irradiance_texture)
  spawn_light(world)
  spawn_sphere(world)
  spawn_fox(world, asset_server)
  spawn_voxel_cubes(world)
  spawn_text(world, asset_server)
  set_global_ambient_light(world, 0.0F)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in irradiance_volumes example")
  }
}

///|
fn rotate_camera(world : @ecs.World) -> Unit {
  if !irradiance_volumes_state.val.rotating {
    return
  }
  guard irradiance_volumes_state.val.camera is Some(camera) else { return }
  guard (try! world.get_by_key(camera, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  let angle = ROTATION_SPEED * world_time(world).delta_seconds()
  let x = transform.translation.x * @math.cos(angle) -
    transform.translation.z * @math.sin(angle)
  let z = transform.translation.x * @math.sin(angle) +
    transform.translation.z * @math.cos(angle)
  let next = @transform.Transform::from_xyz(x, transform.translation.y, z).looking_at(
    @math.Vec3::zero(),
    @math.Vec3::new(0.0F, 1.0F, 0.0F),
  )
  try! (world.replace(camera, @transform.ecs_key_transform, next) |> ignore)
}

///|
fn change_main_object(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Tab) {
    return
  }
  if example_model_eq(irradiance_volumes_state.val.model, ExampleModel::Sphere) {
    irradiance_volumes_state.val.model = ExampleModel::Fox
    set_entity_visibility(world, irradiance_volumes_state.val.sphere, false)
    set_entity_visibility(world, irradiance_volumes_state.val.fox, true)
  } else {
    irradiance_volumes_state.val.model = ExampleModel::Sphere
    set_entity_visibility(world, irradiance_volumes_state.val.sphere, true)
    set_entity_visibility(world, irradiance_volumes_state.val.fox, false)
  }
  update_help_text()
}

///|
fn toggle_irradiance_volumes(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  guard irradiance_volumes_state.val.light_probe is Some(light_probe) else {
    return
  }
  if irradiance_volumes_state.val.irradiance_volume_present {
    try! (world.take(light_probe, @pbr.ecs_key_irradiance_volume) |> ignore)
    set_global_ambient_light(
      world,
      AMBIENT_LIGHT_BRIGHTNESS * IRRADIANCE_VOLUME_INTENSITY,
    )
    irradiance_volumes_state.val.irradiance_volume_present = false
  } else {
    guard irradiance_volumes_state.val.irradiance_texture is Some(texture) else {
      return
    }
    try! world.set_by_key(
      light_probe,
      @pbr.ecs_key_irradiance_volume,
      @pbr.IrradianceVolume::new(Some(texture), IRRADIANCE_VOLUME_INTENSITY),
    )
    set_global_ambient_light(world, 0.0F)
    irradiance_volumes_state.val.irradiance_volume_present = true
  }
  update_help_text()
}

///|
fn toggle_voxel_visibility(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Backspace) {
    return
  }
  irradiance_volumes_state.val.voxels_visible = !irradiance_volumes_state.val.voxels_visible
  for i in 0..<irradiance_volumes_state.val.voxel_cubes.length() {
    set_entity_visibility(
      world,
      Some(irradiance_volumes_state.val.voxel_cubes[i]),
      irradiance_volumes_state.val.voxels_visible,
    )
  }
  update_help_text()
}

///|
fn toggle_rotation(_world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Enter) {
    return
  }
  irradiance_volumes_state.val.rotating = !irradiance_volumes_state.val.rotating
  update_help_text()
}

///|
fn ray_plane_intersection_ground(
  origin : @math.Vec3,
  direction : @math.Vec3,
) -> @math.Vec3? {
  if absf(direction.y) <= 1.0e-6F {
    return None
  }
  let t = -origin.y / direction.y
  if t < 0.0F {
    return None
  }
  Some(origin.add(direction.mul_scalar(t)))
}

///|
fn move_entity_on_ground(
  world : @ecs.World,
  entity : @core.Entity?,
  point : @math.Vec3,
) -> Unit {
  guard entity is Some(target) else { return }
  guard (try! world.get_by_key(target, @transform.ecs_key_transform))
    is Some(current) else {
    return
  }
  try! (world.replace(
    target,
    @transform.ecs_key_transform,
    current.with_translation(
      @math.Vec3::new(point.x, current.translation.y, point.z),
    ),
  )
  |> ignore)
}

///|
fn handle_mouse_clicks(world : @ecs.World) -> Unit {
  if !@input.mouse_button_pressed(@window.MouseButton::Left) {
    return
  }
  guard irradiance_volumes_state.val.camera is Some(camera_entity) else {
    return
  }
  guard @input.mouse_position() is Some(screen_pos) else { return }

  guard (try! world.get_by_key(camera_entity, @sprite.ecs_key_camera))
    is Some(camera) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @pbr.ecs_key_projection))
    is Some(projection) else {
    return
  }
  guard (try! world.get_by_key(camera_entity, @transform.ecs_key_transform))
    is Some(camera_transform) else {
    return
  }

  let target_size = @math.IVec2::new(
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()

  guard @pbr.render3d_camera_viewport_to_world_ray(
      screen_pos, camera, projection, camera_transform, target_size, scale_factor,
    )
    is Some((origin, direction)) else {
    return
  }

  guard ray_plane_intersection_ground(origin, direction) is Some(point) else {
    return
  }

  move_entity_on_ground(world, irradiance_volumes_state.val.sphere, point)
  move_entity_on_ground(world, irradiance_volumes_state.val.fox, point)
}

///|
fn update_text(_world : @ecs.World) -> Unit {
  update_help_text()
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotate_camera))
  .add_systems(@app.Update, @app.system(handle_mouse_clicks))
  .add_systems(@app.Update, @app.system(change_main_object))
  .add_systems(@app.Update, @app.system(toggle_irradiance_volumes))
  .add_systems(@app.Update, @app.system(toggle_voxel_visibility))
  .add_systems(@app.Update, @app.system(toggle_rotation))
  .add_systems(@app.Update, @app.system(update_text))
  .run()
}
