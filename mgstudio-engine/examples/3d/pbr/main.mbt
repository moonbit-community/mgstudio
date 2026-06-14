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
struct EnvironmentMapLabel {}

///|
let environment_map_label_component_key : @ecs.ComponentKey[EnvironmentMapLabel] = @ecs.register_component(
  debug_name="mgstudio_examples_pbr::EnvironmentMapLabel",
)

///|
pub impl @ecs.Component for EnvironmentMapLabel with fn component() {
  environment_map_label_component_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn uv_sphere_mesh(radius : Float, stacks : Int, sectors : Int) -> @mesh.Mesh3d {
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

  @mesh.Mesh3d::new(
    @engine_pbr.mesh_assets_mut_or_abort().modify(fn(assets) {
      assets.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh.Mesh3dGeometry::new(positions, uvs, Some(indices)),
        ),
      )
    }),
  )
}

///|
fn spawn_mesh(
  commands : @app.Commands,
  mesh : @mesh.Mesh3d,
  material : @asset.Handle[@engine_pbr.StandardMaterial],
  transform : @transform.Transform,
) -> Unit {
  ignore(
    commands.spawn(
      @engine_pbr.MeshMaterial3dBundle::new(
        mesh,
        @engine_pbr.MeshMaterial3d::new(material),
        transform,
      ),
    ),
  )
}

///|
fn spawn_label(
  commands : @app.Commands,
  parent : @core.Entity,
  text : String,
  font : @text.TextFont,
  node : @ui.Node,
) -> @core.Entity {
  commands.spawn(
    (
      @hierarchy.Parent::new(parent),
      @text.Text::new(text),
      font,
      node,
      @text.TextColor::white(),
    ),
  )
}

///|
fn spawn_rotated_label(
  commands : @app.Commands,
  parent : @core.Entity,
  text : String,
  font : @text.TextFont,
  node : @ui.Node,
  rotation : Float,
) -> @core.Entity {
  let entity = spawn_label(commands, parent, text, font, node)
  commands
  .entity(entity)
  .insert_component(@ui.UiTransform::from_rotation(rotation))
  entity
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let asset_server = asset_server.get()
  let sphere_mesh = uv_sphere_mesh(0.45F, 18, 32)
  let sphere_color = @color.Color::new(1.0F, 0.847F, 0.569F, 1.0F)

  for y in -2..<3 {
    for x in -5..<6 {
      let x01 = float_from_int(x + 5) / 10.0F
      let y01 = float_from_int(y + 2) / 4.0F
      let material = @engine_pbr.StandardMaterial::from_color(sphere_color)
        .with_metallic(y01)
        .with_perceptual_roughness(x01)
      spawn_mesh(
        commands,
        sphere_mesh,
        @engine_pbr.standard_material_add(material),
        @transform.Transform::from_xyz(
          float_from_int(x),
          float_from_int(y) + 0.5F,
          0.0F,
        ),
      )
    }
  }

  let unlit_material = @engine_pbr.standard_material_add(
    @engine_pbr.StandardMaterial::from_color(sphere_color).with_unlit(true),
  )
  spawn_mesh(
    commands,
    sphere_mesh,
    unlit_material,
    @transform.Transform::from_xyz(-5.0F, -2.5F, 0.0F),
  )

  ignore(
    commands.spawn(
      (
        @engine_pbr.DirectionalLight::new(
          @color.Color::white(),
          1_500.0F,
          false,
        ),
        @transform.Transform::from_xyz(50.0F, 50.0F, 50.0F).looking_at(
          @math.Vec3::new(0.0F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let ui_camera = commands.spawn(
    (
      @camera_components2d.Camera2d::Camera2d(),
      @camera_camera.Camera::Camera().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  commands
  .entity(ui_camera)
  .insert_component(@ui.IsDefaultUiCamera::IsDefaultUiCamera())
  let root = commands.spawn(
    (
      @ui.UiRoot::UiRoot(),
      @ui.Node::Node()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )

  let label_font = @text.TextFont::TextFont().with_font_size(30.0F)
  ignore(
    spawn_label(
      commands,
      root,
      "Perceptual Roughness",
      label_font,
      @ui.Node::Node()
      .with_position_type(@ui.PositionType::Absolute)
      .with_top(@ui.Val::Px(20.0F))
      .with_left(@ui.Val::Px(100.0F)),
    ),
  )
  ignore(
    spawn_rotated_label(
      commands,
      root,
      "Metallic",
      label_font,
      @ui.Node::Node()
      .with_position_type(@ui.PositionType::Absolute)
      .with_top(@ui.Val::Px(130.0F))
      .with_right(@ui.Val::zero()),
      @math.pi_half(),
    ),
  )
  let env_loading_label = spawn_label(
    commands,
    root,
    "Loading Environment Map...",
    label_font,
    @ui.Node::Node()
    .with_position_type(@ui.PositionType::Absolute)
    .with_bottom(@ui.Val::Px(20.0F))
    .with_right(@ui.Val::Px(20.0F)),
  )
  commands.entity(env_loading_label).insert_component(EnvironmentMapLabel::{  })

  let diffuse_env_map = asset_server.load(
    "environment_maps/pisa_diffuse_rgb9e5_zstd.ktx2",
  )
  let specular_env_map = asset_server.load(
    "environment_maps/pisa_specular_rgb9e5_zstd.ktx2",
  )

  let orthographic = @camera.OrthographicProjection3d::{
    ..@camera.OrthographicProjection3d::default_3d(),
    scale: 0.01F,
  }
  let camera = commands.spawn(
    @camera.Camera3dBundle::new_with_projection(
      @camera_camera.Camera::Camera(),
      @camera.Projection::Orthographic(orthographic),
      @transform.Transform::from_xyz(0.0F, 0.0F, 8.0F).looking_at(
        @math.Vec3::new(0.0F, 0.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  commands
  .entity(camera)
  .insert_component(
    @engine_pbr.EnvironmentMapLight::new(
      Some(diffuse_env_map),
      Some(specular_env_map),
      900.0F,
    ),
  )
}

///|
fn environment_map_load_finish(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  environment_map : @ecs.Query[
    @ecs.Read[@engine_pbr.EnvironmentMapLight],
    @ecs.All,
  ],
  label_entity : @ecs.Query[@core.Entity, @ecs.With[EnvironmentMapLabel]],
) -> Unit {
  let label = label_entity.single() catch { _ => None }
  if label is None {
    return
  }
  guard (environment_map.single() catch { _ => None }) is Some(environment_map) else {
    return
  }
  let environment_map = environment_map.value()
  guard environment_map.diffuse_map is Some(diffuse_map) else { return }
  guard environment_map.specular_map is Some(specular_map) else { return }
  if asset_server.get().load_state(diffuse_map) is @asset.LoadState::Loaded &&
    asset_server.get().load_state(specular_map) is @asset.LoadState::Loaded {
    commands.entity(label.unwrap()).despawn()
  }
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_startup_system_param2(setup)
  .add_system_param4(environment_map_load_finish)
  .run()
}
