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
/// Port of `bevy/examples/2d/2d_shapes.rs`.
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_plugins([@sprite.wireframe2d_plugin])
  .add_systems(Startup, @app.system(@app.system_param4(setup)))
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
fn spawn_shape(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
  geometry : @sprite.Mesh2dGeometry,
  position : @math.Vec2,
  color : @sprite.Color,
) -> Unit {
  let mesh = @sprite.Mesh2d::new(
    meshes.get_ref().val |> @sprite.add_mesh(geometry),
  )
  let material = @sprite.MeshMaterial2d::new(
    materials.get_ref().val |> @sprite.add_material(color),
  )
  let transform = @transform.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  ignore(
    commands.spawn(
      @sprite.Mesh2dBundle::new_with_mesh_material(mesh, material, transform),
    ),
  )
}

///|
fn spawn_help_overlay(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let font = asset_server.get().load_font("fonts/FiraSans-Bold.ttf")
  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(@ui.Val::Percent(100.0F))
      .with_height(@ui.Val::Percent(100.0F)),
    ),
  )
  let text_entity = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(12.0F))
      .with_top(@ui.Val::Px(12.0F)),
      @text.Text::new(
        "Press 'R' to pause/resume rotation\nPress 'Space' to toggle wireframes",
      ),
      @text.TextFont::default().with_font(font).with_font_size(20.0F),
      @text.TextColor::new(@sprite.Color::white()),
      @text.TextLayout::new_with_justify(@text.Justify::Left),
    ),
  )
  root |> ignore
  text_entity |> ignore
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@sprite.ColorMaterialAsset]],
) -> Unit {
  let shapes : Array[@sprite.Mesh2dGeometry] = [
    @sprite.mesh2d_geometry_circle(@sprite.Circle::new(50.0F)),
    @sprite.mesh2d_geometry_circular_sector(
      @sprite.CircularSector::new(50.0F, 1.0F),
    ),
    @sprite.mesh2d_geometry_circular_segment(
      @sprite.CircularSegment::new(50.0F, 1.25F),
    ),
    @sprite.mesh2d_geometry_ellipse(@sprite.Ellipse::new(25.0F, 50.0F)),
    @sprite.mesh2d_geometry_annulus(@sprite.Annulus::new(25.0F, 50.0F)),
    @sprite.mesh2d_geometry_capsule(@sprite.Capsule2d::new(25.0F, 25.0F, 16)),
    @sprite.mesh2d_geometry_rhombus(@sprite.Rhombus::new(75.0F, 100.0F)),
    @sprite.mesh2d_geometry_rectangle(@sprite.Rectangle::new(50.0F, 100.0F)),
    @sprite.mesh2d_geometry_regular_polygon(
      @sprite.RegularPolygon::new(50.0F, 6),
    ),
    @sprite.mesh2d_geometry_triangle(
      @sprite.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    @sprite.mesh2d_geometry_segment(
      @sprite.Segment2d::new(
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    @sprite.mesh2d_geometry_polyline(
      @sprite.Polyline2d::new([
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(0.0F, -50.0F),
        @math.Vec2::new(50.0F, 50.0F),
      ]),
    ),
  ]
  let rings : Array[@sprite.Mesh2dGeometry] = [
    @sprite.mesh2d_geometry_ring(@sprite.Circle::new(50.0F).to_ring(THICKNESS)),
    // This visually produces an arc segment but is not technically accurate.
    @sprite.mesh2d_geometry_circular_sector_ring(
      @sprite.CircularSectorRing::new(
        @sprite.CircularSector::new(50.0F, 1.0F),
        @sprite.CircularSector::new(45.0F, 1.0F),
      ),
    ),
    @sprite.mesh2d_geometry_circular_segment_ring(
      @sprite.CircularSegment::new(50.0F, 1.25F).to_ring(THICKNESS),
    ),
    // This is an approximation because concentric ellipses are not parallel curves.
    @sprite.mesh2d_geometry_ellipse_ring(
      @sprite.EllipseRing::new(
        @sprite.Ellipse::new(25.0F, 50.0F),
        @sprite.Ellipse::new(25.0F - THICKNESS, 50.0F - THICKNESS),
      ),
    ),
    // This is equivalent to the annulus above.
    @sprite.mesh2d_geometry_ring(@sprite.Ring2d::new(50.0F, 25.0F)),
    @sprite.mesh2d_geometry_capsule_ring(
      @sprite.Capsule2d::new(25.0F, 25.0F, 16).to_ring(THICKNESS),
    ),
    @sprite.mesh2d_geometry_rhombus_ring(
      @sprite.Rhombus::new(75.0F, 100.0F).to_ring(THICKNESS),
    ),
    @sprite.mesh2d_geometry_rectangle_ring(
      @sprite.Rectangle::new(50.0F, 100.0F).to_ring(THICKNESS),
    ),
    @sprite.mesh2d_geometry_regular_polygon_ring(
      @sprite.RegularPolygon::new(50.0F, 6).to_ring(THICKNESS),
    ),
    @sprite.mesh2d_geometry_triangle_ring(
      @sprite.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ).to_ring(THICKNESS),
    ),
  ]

  let num_shapes = shapes.length()
  for i in 0..<num_shapes {
    spawn_shape(
      commands,
      meshes,
      materials,
      shapes[i],
      @math.Vec2::new(lane_x(i, num_shapes, X_EXTENT), Y_EXTENT / 2.0F),
      shape_palette_color(i, num_shapes),
    )
  }
  let num_rings = rings.length() + 2
  for i in 0..<rings.length() {
    spawn_shape(
      commands,
      meshes,
      materials,
      rings[i],
      @math.Vec2::new(lane_x(i, num_rings, X_EXTENT), -Y_EXTENT / 2.0F),
      shape_palette_color(i, num_rings),
    )
  }
  ignore(
    commands.spawn(
      @sprite.Camera2dBundle::new(
        @sprite.Camera::default(),
        @transform.Transform::identity(),
      ),
    ),
  )

  spawn_help_overlay(commands, asset_server)
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
