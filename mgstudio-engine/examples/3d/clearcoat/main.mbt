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
const PI : Float = 3.141592653589793F

///|
const SPHERE_SCALE : Float = 0.9F

///|
const SPHERE_ROTATION_SPEED : Float = 0.8F

///|
const LIGHT_MODE_POINT : Int = 0

///|
const LIGHT_MODE_DIRECTIONAL : Int = 1

///|
priv struct ClearcoatState {
  sphere_entities : Array[@core.Entity]
  sphere_positions : Array[@math.Vec3]
  mut light_mode : Int
  mut light : @core.Entity?
  mut help_text : @text.TextHandle?
}

///|
let clearcoat_state : Ref[ClearcoatState] = Ref({
  sphere_entities: [],
  sphere_positions: [],
  light_mode: LIGHT_MODE_POINT,
  light: None,
  help_text: None,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
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
fn create_point_light() -> @pbr.PointLight {
  @pbr.PointLight::new(@sprite.Color::white(), 100_000.0F, 20.0F, false)
}

///|
fn create_directional_light() -> @pbr.DirectionalLight {
  @pbr.DirectionalLight::new(@sprite.Color::white(), 1000.0F, false)
}

///|
fn create_help_text() -> String {
  if clearcoat_state.val.light_mode == LIGHT_MODE_POINT {
    "Press Space to switch to a directional light"
  } else {
    "Press Space to switch to a point light"
  }
}

///|
fn update_help_text() -> Unit {
  if clearcoat_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, create_help_text())
  }
}

///|
fn apply_light_mode(world : @ecs.World) -> Unit {
  guard clearcoat_state.val.light is Some(light) else { return }
  try! (world.take(light, @pbr.ecs_key_point_light) |> ignore)
  try! (world.take(light, @pbr.ecs_key_directional_light) |> ignore)

  if clearcoat_state.val.light_mode == LIGHT_MODE_POINT {
    try! world.set_by_key(light, @pbr.ecs_key_point_light, create_point_light())
  } else {
    try! world.set_by_key(
      light,
      @pbr.ecs_key_directional_light,
      create_directional_light(),
    )
  }

  update_help_text()
}

///|
fn spawn_sphere(
  world : @ecs.World,
  mesh : @pbr.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  position : @math.Vec3,
) -> Unit {
  let entity = @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(position.x, position.y, position.z).with_scale(
      @math.Vec3::splat(SPHERE_SCALE),
    ),
  ).spawn(world)
  clearcoat_state.val.sphere_entities.push(entity)
  clearcoat_state.val.sphere_positions.push(position)
}

///|
fn setup(world : @ecs.World) -> Unit {
  clearcoat_state.val.sphere_entities.clear()
  clearcoat_state.val.sphere_positions.clear()
  clearcoat_state.val.light_mode = LIGHT_MODE_POINT
  clearcoat_state.val.light = None
  clearcoat_state.val.help_text = None

  let asset_server = @asset.AssetServer::new()
  let sphere = uv_sphere_mesh(1.0F, 24, 48)

  let blue_noise = asset_server.load("textures/BlueNoise-Normal.png")
  let scratched_gold = asset_server.load("textures/ScratchedGold-Normal.png")

  let car_paint = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 0.0F, 1.0F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.1F)
    .with_normal_map_texture(Some(blue_noise))
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.5F),
  )
  spawn_sphere(world, sphere, car_paint, @math.Vec3::new(-1.0F, 1.0F, 0.0F))

  let coated_glass = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.9F, 0.9F, 0.9F, 0.3F),
    )
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.1F)
    .with_metallic(0.5F)
    .with_perceptual_roughness(0.1F),
  )
  spawn_sphere(world, sphere, coated_glass, @math.Vec3::new(-1.0F, -1.0F, 0.0F))

  let scratched_gold_ball = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.843F, 0.0F, 1.0F),
    )
    .with_clearcoat(1.0F)
    .with_clearcoat_perceptual_roughness(0.3F)
    .with_clearcoat_normal_texture(Some(scratched_gold))
    .with_metallic(0.9F)
    .with_perceptual_roughness(0.1F),
  )
  spawn_sphere(
    world,
    sphere,
    scratched_gold_ball,
    @math.Vec3::new(1.0F, -1.0F, 0.0F),
  )

  let golf_ball_root = world.spawn_empty()
  try! world.set_by_key(
    golf_ball_root,
    @scene.ecs_key_scene_root,
    @scene.SceneRoot::new(
      @scene.scene_load_gltf_scene(
        asset_server,
        @gltf.GltfAssetLabel::Scene(0).from_asset(
          "models/GolfBall/GolfBall.glb",
        ),
      ),
    ),
  )
  try! world.set_by_key(
    golf_ball_root,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(1.0F, 1.0F, 0.0F).with_scale(
      @math.Vec3::splat(SPHERE_SCALE),
    ),
  )
  clearcoat_state.val.sphere_entities.push(golf_ball_root)
  clearcoat_state.val.sphere_positions.push(@math.Vec3::new(1.0F, 1.0F, 0.0F))

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(0.0F, 4.0F, 3.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )
  clearcoat_state.val.light = Some(light)

  apply_light_mode(world)

  let camera = @camera.Camera3dBundle::new_with_projection(
    @sprite.Camera::default(),
    @camera.Projection::Perspective(@camera.PerspectiveProjection3d::{
      ..@camera.PerspectiveProjection3d::default(),
      fov: 27.0F * PI / 180.0F,
    }),
    @transform.Transform::from_xyz(0.0F, 0.0F, 10.0F),
  ).spawn(world)
  try! world.set_by_key(camera, @pbr.ecs_key_hdr, @pbr.Hdr::default())
  try! world.set_by_key(
    camera,
    @post_process.ecs_key_tonemapping,
    @post_process.Tonemapping::AcesFitted,
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_skybox,
    @pbr.Skybox::new(
      asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2"),
      5000.0F,
    ),
  )
  try! world.set_by_key(
    camera,
    @pbr.ecs_key_environment_map_light,
    @pbr.EnvironmentMapLight::new(
      Some(asset_server.load("environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2")),
      Some(asset_server.load("environment_maps/pisa_specular_rgb9e5_zstd.ktx2")),
      2000.0F,
    ),
  )

  let help_text = @text.Text2dBundle::new(
      @text.Text2d::new(""),
      @text.TextFont::default()
      .with_font(asset_server.load_font("fonts/FiraSans-Bold.ttf"))
      .with_font_size(16.0F),
      @transform.Transform::from_xy_rotation_scale(
        @math.Vec2::new(-390.0F, -320.0F),
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
  clearcoat_state.val.help_text = Some(help_text)
  update_help_text()
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in clearcoat example")
  }
}

///|
fn animate_light(world : @ecs.World) -> Unit {
  let now = world_time(world).elapsed_seconds()
  let light_pos = @math.Vec3::new(
    @math.sin(now * 1.4F) * 3.0F,
    @math.cos(now * 1.0F) * 4.0F,
    @math.cos(now * 0.6F) * 3.0F,
  )
  let target = @math.Vec3::zero()
  let up = @math.Vec3::new(0.0F, 1.0F, 0.0F)

  if clearcoat_state.val.light is Some(entity) {
    try! (world.replace(
      entity,
      @transform.ecs_key_transform,
      @transform.Transform::from_xyz(light_pos.x, light_pos.y, light_pos.z).looking_at(
        target, up,
      ),
    )
    |> ignore)
  }
}

///|
fn animate_spheres(world : @ecs.World) -> Unit {
  let angle = SPHERE_ROTATION_SPEED * world_time(world).elapsed_seconds()
  let rotation = @math.Quat::from_rotation_y(angle)
  let count = clearcoat_state.val.sphere_entities.length()
  for i in 0..<count {
    let entity = clearcoat_state.val.sphere_entities[i]
    let position = clearcoat_state.val.sphere_positions[i]
    try! (world.replace(
      entity,
      @transform.ecs_key_transform,
      @transform.Transform::from_xyz(position.x, position.y, position.z)
      .with_rotation(rotation)
      .with_scale(@math.Vec3::splat(SPHERE_SCALE)),
    )
    |> ignore)
  }
}

///|
fn handle_input(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  if clearcoat_state.val.light_mode == LIGHT_MODE_POINT {
    clearcoat_state.val.light_mode = LIGHT_MODE_DIRECTIONAL
  } else {
    clearcoat_state.val.light_mode = LIGHT_MODE_POINT
  }
  apply_light_mode(world)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(animate_light))
  .add_systems(@app.Update, @app.system(animate_spheres))
  .add_systems(@app.Update, @app.system(handle_input))
  .run()
}
