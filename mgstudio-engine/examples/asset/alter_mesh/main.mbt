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
pub(all) enum Shape {
  Cube
  Sphere
}

///|
pub fn Shape::get_model_path(self : Shape) -> String {
  match self {
    Cube => "models/cube/cube.gltf"
    Sphere => "models/sphere/sphere.gltf"
  }
}

///|
pub fn Shape::mesh_asset_path(self : Shape) -> String {
  @gltf.GltfAssetLabel::Primitive(0, 0).from_asset(self.get_model_path())
}

///|
pub fn Shape::next(self : Shape) -> Shape {
  match self {
    Cube => Shape::Sphere
    Sphere => Shape::Cube
  }
}

///|
struct Left {}

///|
let left_key : @ecs.ComponentKey[Left] = @ecs.register_component(
  debug_name="examples.asset.alter_mesh.Left",
)

///|
pub impl @ecs.Component for Left with component() {
  left_key
}

///|
let shape_key : @ecs.ComponentKey[Shape] = @ecs.register_component(
  debug_name="examples.asset.alter_mesh.Shape",
)

///|
pub impl @ecs.Component for Shape with component() {
  shape_key
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let left_shape = Shape::Cube
  let right_shape = Shape::Cube
  let material_handle = materials.get_ref().val.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.6F, 0.8F, 0.6F)),
  )
  let left_shape_model : @asset.Handle[@mesh.Mesh] = asset_server
    .get()
    .load_with_settings(left_shape.mesh_asset_path(), fn(
      settings : @gltf.GltfLoaderSettings,
    ) {
      settings.load_meshes = @asset.RenderAssetUsages::all()
    })
  let right_shape_model : @asset.Handle[@mesh.Mesh] = asset_server
    .get()
    .load(right_shape.mesh_asset_path())

  ignore(
    commands.spawn(
      (
        Left::{  },
        @ecs.Name::new("Left Shape"),
        @pbr.Mesh3d::new(left_shape_model),
        @pbr.MeshMaterial3d::new(material_handle),
        @transform.Transform::from_xyz(-3.0F, 0.0F, 0.0F),
        left_shape,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Right Shape"),
        @pbr.Mesh3d::new(right_shape_model),
        @pbr.MeshMaterial3d::new(material_handle),
        @transform.Transform::from_xyz(3.0F, 0.0F, 0.0F),
        right_shape,
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Point Light"),
        @pbr.PointLight::default(),
        @transform.Transform::from_xyz(4.0F, 5.0F, 4.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Camera"),
        @pbr.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 3.0F, 20.0F).looking_at(
          @math.Vec3::zero(),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )
}

///|
fn spawn_text(commands : @app.Commands) -> Unit {
  ignore(
    commands.spawn(
      (
        @ecs.Name::new("Instructions"),
        @text.Text::new(
          "Space: swap meshes by mutating a Handle<Mesh>\nEnter: mutate the mesh asset itself",
        ),
        @ui.Node::{
          ..@ui.Node::default(),
          position_type: @ui.PositionType::Absolute,
          top: @ui.Val::Px(12.0F),
          left: @ui.Val::Px(12.0F),
        },
      ),
    ),
  )
}

///|
fn alter_handle(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  right_shape : @ecs.Query2Filtered[Shape, @pbr.Mesh3d, @ecs.Without[Left]],
) -> Unit {
  try! right_shape.view(fn(entity, shape, _mesh) {
    let next_shape = shape.next()
    commands
    .entity(entity)
    .insert(
      (
        next_shape,
        @pbr.Mesh3d::new(asset_server.get().load(next_shape.mesh_asset_path())),
      ),
    )
  })
}

///|
fn alter_mesh(
  is_mesh_scaled : @app.Local[Bool],
  left_shape : @ecs.Query1Filtered[@pbr.Mesh3d, @ecs.With[Left]],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
) -> Unit {
  guard (try! left_shape.single()) is Some(mesh3d) else { return }
  let mesh_assets = meshes.get_ref().val
  guard mesh_assets.get_mut(mesh3d.mesh) is Some(mesh_asset) else { return }
  guard mesh_asset.as_3d_geometry() is Some(geometry) else { return }

  let scale_factor = if is_mesh_scaled.get() { 0.5F } else { 2.0F }
  for i in 0..<geometry.positions.length() {
    geometry.positions[i] = geometry.positions[i].mul_scalar(scale_factor)
  }
  if mesh_asset.with_3d_geometry(geometry) is Some(updated) {
    ignore(mesh_assets.set(mesh3d.mesh, updated))
  }
  is_mesh_scaled.set(!is_mesh_scaled.get())
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Startup, @app.system(@app.system_param(spawn_text)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(alter_handle)).run_if(
      @input.input_just_pressed(@window.KeyCode::Space),
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param3(alter_mesh)).run_if(
      @input.input_just_pressed(@window.KeyCode::Enter),
    ),
  )
  .run()
}
