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
/// Port of `bevy/examples/3d/pbr.rs`.

///|
const PI : Float = 3.141592653589793F

///|
priv struct PbrState {
  mut loading_label : @text.TextHandle?
  mut diffuse_env_map : @asset.Handle[@asset.Image]?
  mut specular_env_map : @asset.Handle[@asset.Image]?
  mut env_loaded : Bool
}

///|
let pbr_state : Ref[PbrState] = Ref::new({
  loading_label: None,
  diffuse_env_map: None,
  specular_env_map: None,
  env_loaded: false,
})

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn uv_sphere_mesh(
  radius : Float,
  stacks : Int,
  sectors : Int,
) -> @render3d.Mesh3d {
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

  @render3d.Mesh3d::from_geometry(
    @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
  )
}

///|
fn spawn_mesh(
  world : @ecs.World,
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
fn setup(world : @ecs.World) -> Unit {
  pbr_state.val.loading_label = None
  pbr_state.val.diffuse_env_map = None
  pbr_state.val.specular_env_map = None
  pbr_state.val.env_loaded = false
  let tick = world.read_change_tick()
  let sphere_mesh = uv_sphere_mesh(0.45F, 18, 32)
  let sphere_color = @render2d.Color::new(1.0F, 0.847F, 0.569F, 1.0F)

  for y in -2..<3 {
    for x in -5..<6 {
      let x01 = float_from_int(x + 5) / 10.0F
      let y01 = float_from_int(y + 2) / 4.0F
      let material = @render3d.StandardMaterial::from_color(sphere_color)
        .with_metallic(y01)
        .with_perceptual_roughness(x01)
      spawn_mesh(
        world,
        sphere_mesh,
        @render3d.standard_material_add(material),
        @math.Transform::from_xyz(
          float_from_int(x),
          float_from_int(y) + 0.5F,
          0.0F,
        ),
      )
    }
  }

  let unlit_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(sphere_color).with_unlit(true),
  )
  spawn_mesh(
    world,
    sphere_mesh,
    unlit_material,
    @math.Transform::from_xyz(-5.0F, -2.5F, 0.0F),
  )

  let directional = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(
    directional,
    @render3d.DirectionalLight::new(@render2d.Color::white(), 1_500.0F, false),
    tick,
  )
  world
  .component(@math.ecs_key_transform)
  .insert(
    directional,
    @math.Transform::from_xyz(50.0F, 50.0F, 50.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let asset_server = @asset.AssetServer::new()
  let overlay_font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let diffuse_env_map = asset_server.load(
    "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2",
  )
  let specular_env_map = asset_server.load(
    "environment_maps/pisa_specular_rgb9e5_zstd.ktx2",
  )

  @text.Text2dBundle::new(
    @text.Text2d::new("Perceptual Roughness"),
    @text.TextFont::default().with_font(overlay_font).with_font_size(30.0F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(-300.0F, 330.0F),
      0.0F,
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@render2d.Anchor::top_left())
  .with_color(
    @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .spawn()
  |> ignore

  @text.Text2dBundle::new(
    @text.Text2d::new("Metallic"),
    @text.TextFont::default().with_font(overlay_font).with_font_size(30.0F),
    @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(360.0F, 80.0F),
      @math.pi_half(),
      @math.Vec2::new(1.0F, 1.0F),
      z=50.0F,
    ),
  )
  .with_anchor(@render2d.Anchor::top_left())
  .with_color(
    @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
  )
  .spawn()
  |> ignore

  let env_loading_label = @text.Text2dBundle::new(
      @text.Text2d::new("Loading Environment Map..."),
      @text.TextFont::default().with_font(overlay_font).with_font_size(24.0F),
      @math.Transform::from_xy_rotation_scale(
        @math.Vec2::new(375.0F, -330.0F),
        0.0F,
        @math.Vec2::new(1.0F, 1.0F),
        z=50.0F,
      ),
    )
    .with_anchor(@render2d.Anchor::bottom_right())
    .with_color(
      @text.TextColor::new(@render2d.Color::new(0.95F, 0.95F, 0.95F, 1.0F)),
    )
    .spawn()
  pbr_state.val.loading_label = Some(env_loading_label)

  let orthographic = @render3d.OrthographicProjection3d::default()
    .with_scale(0.01F)
    .with_window_size_scaling()
  let camera = @render3d.Camera3dBundle::new_with_projection(
    @render2d.Camera::default(),
    @render3d.Projection3d::Orthographic(orthographic),
    @math.Transform::from_xyz(0.0F, 0.0F, 8.0F).looking_at(
      @math.Vec3::new(0.0F, 0.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_environment_map_light)
  .insert(
    camera,
    @render3d.EnvironmentMapLight::new(
      Some(diffuse_env_map),
      Some(specular_env_map),
      900.0F,
    ),
    tick,
  )
  pbr_state.val.diffuse_env_map = Some(diffuse_env_map)
  pbr_state.val.specular_env_map = Some(specular_env_map)
}

///|
fn environment_map_load_finish(_world : @ecs.World) -> Unit {
  if pbr_state.val.env_loaded {
    return
  }
  guard pbr_state.val.diffuse_env_map is Some(diffuse_map) else { return }
  guard pbr_state.val.specular_env_map is Some(specular_map) else { return }
  if @asset.asset_is_texture_loaded(diffuse_map) &&
    @asset.asset_is_texture_loaded(specular_map) {
    if pbr_state.val.loading_label is Some(label) {
      @text.text_despawn(label) |> ignore
      pbr_state.val.loading_label = None
    }
    pbr_state.val.env_loaded = true
  }
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_startup_system(setup)
  .add_system(environment_map_load_finish)
  .run()
}
