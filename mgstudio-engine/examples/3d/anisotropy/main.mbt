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

///|
const PI : Float = 3.141592653589793F

///|
const CAMERA_INITIAL_X : Float = -0.4F

///|
const CAMERA_INITIAL_Y : Float = 0.0F

///|
const CAMERA_INITIAL_Z : Float = 0.0F

///|
const SKYBOX_BRIGHTNESS : Float = 5000.0F

///|
const ENVIRONMENT_MAP_INTENSITY : Float = 2500.0F

///|
const SPHERE_BASE_R : Float = 0.81960786F

///|
const SPHERE_BASE_G : Float = 0.8352941F

///|
const SPHERE_BASE_B : Float = 0.85882354F

///|
priv enum LightMode {
  Directional
  Point
  EnvironmentMap
}

///|
priv enum SceneKind {
  BarnLamp
  Sphere
}

///|
priv struct MaterialVariants {
  entity : @core.Entity
  anisotropic : @asset.Handle[@pbr.StandardMaterial]
  isotropic : @asset.Handle[@pbr.StandardMaterial]
  scene : SceneKind?
}

///|
priv struct AnisotropyState {
  mut light_mode : LightMode
  mut anisotropy_enabled : Bool
  mut visible_scene : SceneKind
  mut environment_angle : Float
  mut barn_lamp_scene : @core.Entity?
  mut sphere_scene : @core.Entity?
  mut environment_diffuse_map : @asset.Handle[@asset.Image]?
  mut environment_specular_map : @asset.Handle[@asset.Image]?
  mut help_text : @text.TextHandle?
  material_variants : Array[MaterialVariants]
}

///|
let anisotropy_state : Ref[AnisotropyState] = Ref::new({
  light_mode: LightMode::Directional,
  anisotropy_enabled: true,
  visible_scene: SceneKind::BarnLamp,
  environment_angle: 0.0F,
  barn_lamp_scene: None,
  sphere_scene: None,
  environment_diffuse_map: None,
  environment_specular_map: None,
  help_text: None,
  material_variants: [],
})

///|
fn camera_initial_position() -> @math.Vec3 {
  @math.Vec3::new(CAMERA_INITIAL_X, CAMERA_INITIAL_Y, CAMERA_INITIAL_Z)
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
fn same_entity(lhs : @core.Entity, rhs : @core.Entity) -> Bool {
  lhs.id == rhs.id && lhs.generation == rhs.generation
}

///|
fn scene_is_visible(scene : SceneKind) -> Bool {
  match scene {
    SceneKind::BarnLamp =>
      match anisotropy_state.val.visible_scene {
        SceneKind::BarnLamp => true
        SceneKind::Sphere => false
      }
    SceneKind::Sphere =>
      match anisotropy_state.val.visible_scene {
        SceneKind::BarnLamp => false
        SceneKind::Sphere => true
      }
  }
}

///|
fn SceneKind::next(self : SceneKind) -> SceneKind {
  match self {
    SceneKind::BarnLamp => SceneKind::Sphere
    SceneKind::Sphere => SceneKind::BarnLamp
  }
}

///|
fn scene_name(scene : SceneKind) -> String {
  match scene {
    SceneKind::BarnLamp => "Barn Lamp"
    SceneKind::Sphere => "Sphere"
  }
}

///|
fn light_mode_help_text(mode : LightMode) -> String {
  match mode {
    LightMode::Directional => "Press Space to switch to a point light"
    LightMode::Point => "Press Space to switch to an environment map"
    LightMode::EnvironmentMap => "Press Space to switch to a directional light"
  }
}

///|
fn anisotropy_help_text() -> String {
  let anisotropy_text = if anisotropy_state.val.anisotropy_enabled {
    "Press Enter to disable anisotropy"
  } else {
    "Press Enter to enable anisotropy"
  }
  let scene_text = "Press Q to change to \{scene_name(anisotropy_state.val.visible_scene.next())}"
  "\{anisotropy_text}\n\{light_mode_help_text(anisotropy_state.val.light_mode)}\n\{scene_text}"
}

///|
fn update_help_text() -> Unit {
  guard anisotropy_state.val.help_text is Some(handle) else { return }
  @text.text_set_content(handle, anisotropy_help_text())
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
  if (try! world.contains_by_key(entity, @visibility.ecs_key_visibility)) {
    try! (world.replace(entity, @visibility.ecs_key_visibility, visibility)
    |> ignore)
  } else {
    try! world.set_by_key(entity, @visibility.ecs_key_visibility, visibility)
  }
}

///|
fn scene_for_mesh_entity(
  world : @ecs.World,
  entity : @core.Entity,
) -> SceneKind? {
  if anisotropy_state.val.sphere_scene is Some(sphere_entity) &&
    same_entity(entity, sphere_entity) {
    return Some(SceneKind::Sphere)
  }
  if anisotropy_state.val.barn_lamp_scene is Some(root_entity) &&
    (try! world.get_by_key(entity, @hierarchy.ecs_key_parent)) is Some(parent) &&
    same_entity(parent.entity(), root_entity) {
    return Some(SceneKind::BarnLamp)
  }
  None
}

///|
fn has_material_variant(entity : @core.Entity) -> Bool {
  for variants in anisotropy_state.val.material_variants {
    if same_entity(variants.entity, entity) {
      return true
    }
  }
  false
}

///|
fn apply_scene_visibility(world : @ecs.World) -> Unit {
  if anisotropy_state.val.barn_lamp_scene is Some(entity) {
    set_entity_visibility(world, entity, scene_is_visible(SceneKind::BarnLamp))
  }

  if anisotropy_state.val.sphere_scene is Some(entity) {
    set_entity_visibility(world, entity, scene_is_visible(SceneKind::Sphere))
  }

  for variants in anisotropy_state.val.material_variants {
    if variants.scene is Some(scene) {
      set_entity_visibility(world, variants.entity, scene_is_visible(scene))
    }
  }
}

///|
fn spawn_directional_light(world : @ecs.World) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::default().with_illuminance(3000.0F),
  )
}

///|
fn spawn_point_light(world : @ecs.World) -> Unit {
  let entity = world.spawn_empty()
  try! world.set_by_key(
    entity,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::default().with_intensity(200_000.0F),
  )
}

///|
fn add_skybox_and_environment_map(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Unit {
  if anisotropy_state.val.environment_specular_map is Some(specular_map) {
    try! world.set_by_key(
      camera_entity,
      @pbr.ecs_key_skybox,
      @pbr.Skybox::new(specular_map, SKYBOX_BRIGHTNESS),
    )
  }
  if anisotropy_state.val.environment_diffuse_map is Some(diffuse_map) &&
    anisotropy_state.val.environment_specular_map is Some(specular_map) {
    try! world.set_by_key(
      camera_entity,
      @pbr.ecs_key_environment_map_light,
      @pbr.EnvironmentMapLight::new(
        Some(diffuse_map),
        Some(specular_map),
        ENVIRONMENT_MAP_INTENSITY,
      ),
    )
  }
}

///|
fn remove_skybox_and_environment_map(
  world : @ecs.World,
  camera_entity : @core.Entity,
) -> Unit {
  try! (world.take(camera_entity, @pbr.ecs_key_skybox) |> ignore)
  try! (world.take(camera_entity, @pbr.ecs_key_environment_map_light) |> ignore)
}

///|
fn despawn_all_lights(world : @ecs.World) -> Unit {
  let lights : Array[@core.Entity] = []
  world.for_each_component(@pbr.ecs_key_directional_light, fn(entity, _light) {
    lights.push(entity)
  })
  world.for_each_component(@pbr.ecs_key_point_light, fn(entity, _light) {
    lights.push(entity)
  })
  for light in lights {
    try! (world.despawn(light) |> ignore)
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
fn setup(world : @ecs.World) -> Unit {
  anisotropy_state.val.light_mode = LightMode::Directional
  anisotropy_state.val.anisotropy_enabled = true
  anisotropy_state.val.visible_scene = SceneKind::BarnLamp
  anisotropy_state.val.environment_angle = 0.0F
  anisotropy_state.val.barn_lamp_scene = None
  anisotropy_state.val.sphere_scene = None
  anisotropy_state.val.environment_diffuse_map = None
  anisotropy_state.val.environment_specular_map = None
  anisotropy_state.val.help_text = None
  anisotropy_state.val.material_variants.clear()

  @window.window_set_title(title="Bevy Anisotropy Example")

  let asset_server = @asset.AssetServer::new()
  anisotropy_state.val.environment_diffuse_map = Some(
    asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2"),
  )
  anisotropy_state.val.environment_specular_map = Some(
    asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
  )

  @pbr.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(
      CAMERA_INITIAL_X,
      CAMERA_INITIAL_Y,
      CAMERA_INITIAL_Z,
    ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F)),
  ).spawn(world)
  |> ignore

  spawn_directional_light(world)

  let barn_lamp = world.spawn_empty()
  try! world.set_by_key(
    barn_lamp,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/AnisotropyBarnLamp/AnisotropyBarnLamp.gltf",
        ),
      ),
    ),
  )
  try! world.set_by_key(
    barn_lamp,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 0.07F, -0.13F),
  )
  anisotropy_state.val.barn_lamp_scene = Some(barn_lamp)

  let sphere_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(SPHERE_BASE_R, SPHERE_BASE_G, SPHERE_BASE_B, 1.0F),
    )
    .with_anisotropy_rotation(0.5F)
    .with_anisotropy_strength(1.0F),
  )

  let sphere = @pbr.MeshMaterial3dBundle::new(
    uv_sphere_mesh(0.1F, 20, 36),
    @pbr.MeshMaterial3d::new(sphere_material),
    @transform.Transform::identity(),
  ).spawn(world)
  anisotropy_state.val.sphere_scene = Some(sphere)

  apply_scene_visibility(world)

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(anisotropy_help_text()),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(18.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -340.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@sprite.Anchor::bottom_left())
    .with_bounds(@text.TextBounds::new_horizontal(780.0F))
    .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
    .with_color(
      @text.TextColor::new(@sprite.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .with_shadow(Some(@text.Text2dShadow::default()))
    .spawn()
  anisotropy_state.val.help_text = Some(help_text)
  update_help_text()
}

///|
fn create_material_variants(world : @ecs.World) -> Unit {
  let pending_entities : Array[@core.Entity] = []
  world.for_each_component(@pbr.ecs_key_mesh_material3d, fn(entity, _material) {
    if !has_material_variant(entity) {
      pending_entities.push(entity)
    }
  })

  for entity in pending_entities {
    guard (try! world.get_by_key(entity, @pbr.ecs_key_mesh_material3d))
      is Some(anisotropic_component) else {
      continue
    }
    let anisotropic = anisotropic_component.material
    guard @pbr.standard_material_get(anisotropic) is Some(anisotropic_mat) else {
      continue
    }
    let isotropic = @pbr.standard_material_add(
      anisotropic_mat
      .with_anisotropy_texture(None)
      .with_anisotropy_strength(0.0F)
      .with_anisotropy_rotation(0.0F),
    )
    let scene = scene_for_mesh_entity(world, entity)
    anisotropy_state.val.material_variants.push({
      entity,
      anisotropic,
      isotropic,
      scene,
    })
    if scene is Some(scene_kind) {
      set_entity_visibility(world, entity, scene_is_visible(scene_kind))
    }
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in anisotropy example")
  }
}

///|
fn animate_light(world : @ecs.World) -> Unit {
  let now = world_time(world).elapsed_seconds()
  let next_transform = @transform.Transform::from_xyz(
    @math.cos(now) * 3.0F,
    4.0F,
    @math.sin(now) * 3.0F,
  ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))

  world.for_each_component(@pbr.ecs_key_directional_light, fn(entity, _light) {
    try! world.set_by_key(entity, @transform.ecs_key_transform, next_transform)
  })
  world.for_each_component(@pbr.ecs_key_point_light, fn(entity, _light) {
    try! world.set_by_key(entity, @transform.ecs_key_transform, next_transform)
  })
}

///|
fn rotate_camera(world : @ecs.World) -> Unit {
  match anisotropy_state.val.light_mode {
    LightMode::EnvironmentMap =>
      anisotropy_state.val.environment_angle = anisotropy_state.val.environment_angle +
        world_time(world).delta_seconds()
    _ => ()
  }

  let rotated_position = quat_rotate_vec3(
    @math.Quat::from_rotation_y(anisotropy_state.val.environment_angle),
    camera_initial_position(),
  )
  let next_transform = @transform.Transform::from_xyz(
    rotated_position.x,
    rotated_position.y,
    rotated_position.z,
  ).looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  world.for_each_component(@sprite.ecs_key_camera, fn(entity, _camera) {
    try! world.set_by_key(entity, @transform.ecs_key_transform, next_transform)
  })
}

///|
fn toggle_anisotropy(world : @ecs.World) -> Unit {
  anisotropy_state.val.anisotropy_enabled = !anisotropy_state.val.anisotropy_enabled
  for variants in anisotropy_state.val.material_variants {
    let next_material = if anisotropy_state.val.anisotropy_enabled {
      variants.anisotropic
    } else {
      variants.isotropic
    }
    try! (world.replace(
      variants.entity,
      @pbr.ecs_key_mesh_material3d,
      @pbr.MeshMaterial3d::new(next_material),
    )
    |> ignore)
  }
}

///|
fn handle_input(world : @ecs.World) -> Unit {
  let mut changed = false
  if @input.key_just_pressed(@window.KeyCode::Space) {
    match anisotropy_state.val.light_mode {
      LightMode::Directional => {
        anisotropy_state.val.light_mode = LightMode::Point
        despawn_all_lights(world)
        spawn_point_light(world)
      }
      LightMode::Point => {
        anisotropy_state.val.light_mode = LightMode::EnvironmentMap
        despawn_all_lights(world)
        world.for_each_component(@sprite.ecs_key_camera, fn(entity, _camera) {
          add_skybox_and_environment_map(world, entity)
        })
      }
      LightMode::EnvironmentMap => {
        anisotropy_state.val.light_mode = LightMode::Directional
        world.for_each_component(@sprite.ecs_key_camera, fn(entity, _camera) {
          remove_skybox_and_environment_map(world, entity)
        })
        spawn_directional_light(world)
      }
    }
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::Enter) {
    toggle_anisotropy(world)
    changed = true
  }

  if @input.key_just_pressed(@window.KeyCode::KeyQ) {
    anisotropy_state.val.visible_scene = anisotropy_state.val.visible_scene.next()
    apply_scene_visibility(world)
    changed = true
  }

  if changed {
    update_help_text()
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(create_material_variants))
  .add_systems(@app.Update, @app.system(animate_light))
  .add_systems(@app.Update, @app.system(rotate_camera))
  .add_systems(@app.Update, @app.system(handle_input))
  .run()
}
