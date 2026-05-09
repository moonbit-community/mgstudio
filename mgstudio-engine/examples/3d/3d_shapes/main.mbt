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
const SHAPES_X_EXTENT : Float = 14.0F

///|
const EXTRUSION_X_EXTENT : Float = 14.0F

///|
const Z_EXTENT : Float = 8.0F

///|
const THICKNESS : Float = 0.1F

///|
const TEXTURE_SIZE : Int = 8

///|
priv enum Row {
  Front
  Middle
  Rear
}

///|
let row_key : @ecs.ComponentKey[Row] = @ecs.register_component(
  debug_name="examples.3d.3d_shapes.Row",
)

///|
impl @ecs.Component for Row with component() {
  row_key
}

///|
priv struct Shape {}

///|
let shape_key : @ecs.ComponentKey[Shape] = @ecs.register_component(
  debug_name="examples.3d.3d_shapes.Shape",
)

///|
impl @ecs.Component for Shape with component() {
  shape_key
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn byte_from_int(value : Int) -> Byte {
  value.to_byte()
}

///|
fn row_z(row : Row) -> Float {
  match row {
    Front => Z_EXTENT / 2.0F
    Middle => 0.0F
    Rear => -Z_EXTENT / 2.0F
  }
}

///|
fn row_advance(row : Row) -> Row {
  match row {
    Front => Rear
    Middle => Front
    Rear => Middle
  }
}

///|
fn spacing_at(index : Int, count : Int, extent : Float) -> Float {
  if count <= 1 {
    0.0F
  } else {
    -extent / 2.0F + float_from_int(index) / float_from_int(count - 1) * extent
  }
}

///|
fn uv_debug_texture(
  images : @asset.Assets[@asset.Image],
) -> @asset.Handle[@asset.Image] {
  let palette : Array[Byte] = [
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(159),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(159),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(236),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(121),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(198),
    byte_from_int(255),
    byte_from_int(102),
    byte_from_int(198),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(121),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(255),
    byte_from_int(236),
    byte_from_int(102),
    byte_from_int(255),
    byte_from_int(255),
  ]

  let texture_data : Array[Byte] = []
  for _y in 0..<TEXTURE_SIZE {
    for i in 0..<palette.length() {
      texture_data.push(palette[i])
    }
    let tail0 = palette[palette.length() - 4]
    let tail1 = palette[palette.length() - 3]
    let tail2 = palette[palette.length() - 2]
    let tail3 = palette[palette.length() - 1]
    let mut index = palette.length() - 1
    while index >= 4 {
      palette[index] = palette[index - 4]
      index = index - 1
    }
    palette[0] = tail0
    palette[1] = tail1
    palette[2] = tail2
    palette[3] = tail3
  }

  let image = @asset.Image::new(
    TEXTURE_SIZE,
    TEXTURE_SIZE,
    Bytes::from_array(texture_data),
  ).with_format(Rgba8UnormSrgb)
  images.add(image)
}

///|
fn mesh3d_from_geometry(
  meshes : @asset.Assets[@mesh.Mesh],
  geometry : @mesh.Mesh3dGeometry,
) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(meshes.add(@mesh.Mesh::from_3d_geometry(geometry)))
}

///|
fn spawn_shape(
  commands : @app.Commands,
  mesh : @mesh.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  x : Float,
  row : Row,
) -> Unit {
  ignore(
    commands.spawn(
      (
        mesh,
        @pbr.MeshMaterial3d::new(material),
        @transform.Transform::from_xyz(x, 2.0F, row_z(row)).with_rotation(
          @math.Quat::from_rotation_x(-PI / 4.0F),
        ),
        Shape::{  },
        row,
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  images : @app.ResMut[@asset.Assets[@asset.Image]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let mesh_assets = meshes.peek()
  let image_assets = images.peek()
  let material_assets = materials.peek()
  let debug_material = material_assets.add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_base_color_texture(
      Some(uv_debug_texture(image_assets)),
    ),
  )

  let shapes = [
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.CuboidMeshBuilder::new(1.0F, 1.0F, 1.0F).build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.TetrahedronMeshBuilder::default().build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.Capsule3dMeshBuilder::default().build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.TorusMeshBuilder::default().build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.CylinderMeshBuilder::default().build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.ConeMeshBuilder::default().build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.ConicalFrustumMeshBuilder::default().build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.SphereMeshBuilder::new(
        0.5F,
        @mesh_primitives_dim3.SphereKind::ico(5),
      ).build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.SphereMeshBuilder::new(
        0.5F,
        @mesh_primitives_dim3.SphereKind::uv(32, 18),
      ).build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.Segment3dMeshBuilder::default().build(),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives_dim3.Polyline3dMeshBuilder::new(
        @math.Polyline3d::new([
          @math.Vec3::new(-0.5F, 0.0F, 0.0F),
          @math.Vec3::new(0.5F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 0.5F, 0.0F),
        ]),
      ).build(),
    ),
  ]

  let shape_count = shapes.length()
  for i in 0..<shape_count {
    spawn_shape(
      commands,
      shapes[i],
      debug_material,
      spacing_at(i, shape_count, SHAPES_X_EXTENT),
      Front,
    )
  }

  let extrusions = [
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_rectangle_mesh(
        @math.Rectangle::default(),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_capsule2d_mesh(
        @math.Capsule2d::default(),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_annulus_mesh(@math.Annulus::default(), 1.0F),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_circle_mesh(@math.Circle::default(), 1.0F),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_ellipse_mesh(@math.Ellipse::default(), 1.0F),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_regular_polygon_mesh(
        @math.RegularPolygon::default(),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_triangle2d_mesh(
        @math.Triangle2d::default(),
        1.0F,
      ),
    ),
  ]

  let extrusion_count = extrusions.length()
  for i in 0..<extrusion_count {
    spawn_shape(
      commands,
      extrusions[i],
      debug_material,
      spacing_at(i, extrusion_count, EXTRUSION_X_EXTENT),
      Middle,
    )
  }

  let ring_extrusions = [
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_rectangle_ring_mesh(
        @math.Rectangle::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_capsule2d_ring_mesh(
        @math.Capsule2d::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_ring2d_mesh(
        @math.Ring2d::new(1.0F, 0.5F),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_circle_ring_mesh(
        @math.Circle::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_ellipse_ring_mesh(
        @math.Ellipse::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_regular_polygon_ring_mesh(
        @math.RegularPolygon::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      mesh_assets,
      @mesh_primitives.extrusion_triangle2d_ring_mesh(
        @math.Triangle2d::default(),
        1.0F,
      ),
    ),
  ]

  let ring_count = ring_extrusions.length()
  for i in 0..<ring_count {
    spawn_shape(
      commands,
      ring_extrusions[i],
      debug_material,
      spacing_at(i, ring_count, EXTRUSION_X_EXTENT),
      Rear,
    )
  }

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::new(
          @sprite.Color::white(),
          10_000_000.0F,
          100.0F,
          true,
        ).with_shadow_depth_bias(0.2F),
        @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(
          mesh_assets.add(
            @mesh.Mesh::from_3d_geometry(
              @mesh_primitives_dim3.plane3d_mesh_from_size(50.0F, 50.0F, 10),
            ),
          ),
        ),
        @pbr.MeshMaterial3d::new(
          material_assets.add(
            @pbr.StandardMaterial::from_color(
              @sprite.Color::srgb(0.7529412F, 0.7529412F, 0.7529412F),
            ),
          ),
        ),
        @transform.Transform::identity(),
      ),
    ),
  )

  ignore(
    commands.spawn(
      (
        @camera.Camera3d::default(),
        @transform.Transform::from_xyz(0.0F, 7.0F, 14.0F).looking_at(
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
          @math.Vec3::new(0.0F, 1.0F, 0.0F),
        ),
      ),
    ),
  )

  let ui_camera = commands.spawn(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default().with_order(100).with_clear_color_none(),
      @transform.Transform::identity(),
    ),
  )
  commands.entity(ui_camera).insert_component(@ui.IsDefaultUiCamera::default())

  let root = commands.spawn(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(Percent(100.0F))
      .with_height(Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(Absolute)
        .with_top(Px(12.0F))
        .with_left(Px(12.0F)),
        @text.Text::new(
          "Press 'R' to pause/resume rotation\nPress 'Tab' to cycle through rows\nPress 'Space' to toggle wireframes",
        ),
        @text.TextFont::default(),
        @text.TextColor::default(),
        @text.TextLayout::default(),
        @text.LineHeight::default(),
        @text.FontHinting::default(),
      ),
    ),
  )
}

///|
fn rotate(
  query : @ecs.Query[@ecs.Mut[@transform.Transform], @ecs.With[Shape]],
  time : @app.Res[@time.Time[Unit]],
) -> Unit {
  let delta = time.get().delta_seconds() / 2.0F
  try! query.for_each(fn(_entity, transform) {
    transform.modify(fn(value) {
      value.rotation = value.rotation
        .mul(@math.Quat::from_rotation_y(delta))
        .normalize()
    })
  })
}

///|
fn advance_rows(
  query : @ecs.Query[
    (@ecs.Mut[Row], @ecs.Mut[@transform.Transform]),
    @ecs.With[Shape],
  ],
) -> Unit {
  try! query.for_each(fn(_entity, data) {
    let (row, transform) = data
    let next_row = row_advance(row.value())
    row.set(next_row)
    transform.modify(fn(value) { value.translation.z = row_z(next_row) })
  })
}

///|
fn toggle_wireframe(config : @app.ResMut[@pbr.WireframeConfig]) -> Unit {
  let current = config.get()
  config.set(current.with_global(!current.global))
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@asset.AssetPlugin::default_nearest()),
  )
  .add_plugins(@pbr.WireframePlugin::default())
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup)))
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(toggle_wireframe)).run_if(
      @input.input_just_pressed(@window.KeyCode::Space),
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param2(rotate)).run_if(
      @input.input_toggle_active(false, @window.KeyCode::KeyR),
    ),
  )
  .add_systems(
    @app.Update,
    @app.system(@app.system_param(advance_rows)).run_if(
      @input.input_just_pressed(@window.KeyCode::Tab),
    ),
  )
  .run()
}
