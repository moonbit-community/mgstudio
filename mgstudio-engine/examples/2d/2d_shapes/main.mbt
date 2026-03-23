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
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@sprite.wireframe2d_plugin])
  .add_systems(Startup, @app.system(@app.system_param3(setup)))
  .add_systems(
    Update,
    @app.system(@app.system_param(toggle_wireframe)).run_if(
      @input.input_just_pressed(@window.KeyCode::Space),
    ),
  )
  .add_systems(
    Update,
    @app.system(@app.system_param2(rotate)).run_if(
      @input.input_toggle_active(false, @window.KeyCode::KeyR),
    ),
  )
  .run()
}

///|
const X_EXTENT : Float = 1000.0F

///|
const Y_EXTENT : Float = 150.0F

///|
const THICKNESS : Float = 5.0F

///|
fn shape_palette_color(index : Int, count : Int) -> @sprite.Color {
  let safe_count = if count <= 0 { 1 } else { count }
  let hue = 360.0F *
    Float::from_double(index.to_double()) /
    Float::from_double(safe_count.to_double())
  @sprite.Color::hsl(hue, 0.95F, 0.7F)
}

///|
fn lane_x(index : Int, total : Int, extent : Float) -> Float {
  if total <= 1 {
    return 0.0F
  }
  let ratio = Float::from_double(index.to_double()) /
    Float::from_double((total - 1).to_double())
  -extent / 2.0F + ratio * extent
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))

  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val
  let shapes : Array[@asset.Handle[@mesh.Mesh]] = [
    mesh_assets |> @sprite.add_mesh(@sprite.Circle::new(50.0F)),
    mesh_assets |> @sprite.add_mesh(@sprite.CircularSector::new(50.0F, 1.0F)),
    mesh_assets |> @sprite.add_mesh(@sprite.CircularSegment::new(50.0F, 1.25F)),
    mesh_assets |> @sprite.add_mesh(@sprite.Ellipse::new(25.0F, 50.0F)),
    mesh_assets |> @sprite.add_mesh(@sprite.Annulus::new(25.0F, 50.0F)),
    mesh_assets |> @sprite.add_mesh(@sprite.Capsule2d::new(25.0F, 50.0F)),
    mesh_assets |> @sprite.add_mesh(@sprite.Rhombus::new(75.0F, 100.0F)),
    mesh_assets |> @sprite.add_mesh(@sprite.Rectangle::new(50.0F, 100.0F)),
    mesh_assets |> @sprite.add_mesh(@sprite.RegularPolygon::new(50.0F, 6)),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Segment2d::new(
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Polyline2d::new([
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(0.0F, -50.0F),
        @math.Vec2::new(50.0F, 50.0F),
      ]),
    ),
  ]
  let rings : Array[@asset.Handle[@mesh.Mesh]] = [
    mesh_assets
    |> @sprite.add_mesh(@sprite.Circle::new(50.0F).to_ring(THICKNESS)),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Ring::new(
        @sprite.CircularSector::new(50.0F, 1.0F),
        @sprite.CircularSector::new(45.0F, 1.0F),
      ),
    ),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.CircularSegment::new(50.0F, 1.25F).to_ring(THICKNESS),
    ),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Ring::new(
        @sprite.Ellipse::new(25.0F, 50.0F),
        @sprite.Ellipse::new(25.0F - THICKNESS, 50.0F - THICKNESS),
      ),
    ),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Ring::new(@sprite.Circle::new(50.0F), @sprite.Circle::new(25.0F)),
    ),
    mesh_assets
    |> @sprite.add_mesh(@sprite.Capsule2d::new(25.0F, 50.0F).to_ring(THICKNESS)),
    mesh_assets
    |> @sprite.add_mesh(@sprite.Rhombus::new(75.0F, 100.0F).to_ring(THICKNESS)),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Rectangle::new(50.0F, 100.0F).to_ring(THICKNESS),
    ),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.RegularPolygon::new(50.0F, 6).to_ring(THICKNESS),
    ),
    mesh_assets
    |> @sprite.add_mesh(
      @sprite.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ).to_ring(THICKNESS),
    ),
  ]

  let num_shapes = shapes.length()
  for i in 0..<num_shapes {
    let color = shape_palette_color(i, num_shapes)
    ignore(
      commands.spawn(
        (
          @sprite.Mesh2d::new(shapes[i]),
          @sprite.MeshMaterial2d::new(
            material_assets |> @sprite.add_material(color),
          ),
          @transform.Transform::from_xyz(
            lane_x(i, num_shapes, X_EXTENT),
            Y_EXTENT / 2.0F,
            0.0F,
          ),
        ),
      ),
    )
  }
  let num_rings = rings.length() + 2
  for i in 0..<rings.length() {
    let color = shape_palette_color(i, num_rings)
    ignore(
      commands.spawn(
        (
          @sprite.Mesh2d::new(rings[i]),
          @sprite.MeshMaterial2d::new(
            material_assets |> @sprite.add_material(color),
          ),
          @transform.Transform::from_xyz(
            lane_x(i, num_rings, X_EXTENT),
            -Y_EXTENT / 2.0F,
            0.0F,
          ),
        ),
      ),
    )
  }
  ignore(
    commands.spawn(
      (
        @text.Text::new(
          "Press 'R' to pause/resume rotation\nPress 'Space' to toggle wireframes",
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
fn toggle_wireframe(config : @app.ResMut[@sprite.Wireframe2dConfig]) -> Unit {
  let current = config.get_ref().val
  config.get_ref().val = current.with_global(!current.global)
}

///|
fn rotate(
  query : @ecs.Query2[@transform.Transform, @sprite.Mesh2d],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta_secs = time.get().delta_seconds()
  let speed = 0.5F
  try! query.for_each(fn(_entity, transform, _mesh) {
    let next_rotation = transform.rotation_z() + speed * delta_secs
    transform.rotation = @math.Quat::from_rotation_z(next_rotation)
  })
}
