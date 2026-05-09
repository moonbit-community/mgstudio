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
priv struct ShapeEntry {
  entity : @core.Entity
  row : Row
}

///|
priv struct ShapesState {
  mut rotating : Bool
  entries : Array[ShapeEntry]
}

///|
let shapes_state : Ref[ShapesState] = Ref({ rotating: true, entries: [] })

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
fn uv_debug_texture() -> @asset.Handle[@asset.Image] {
  let mut palette : Array[Byte] = [
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
    let rotated : Array[Byte] = []
    for i in 0..<palette.length() {
      let source = if i < 4 { palette.length() - 4 + i } else { i - 4 }
      rotated.push(palette[source])
    }
    palette = rotated
  }

  let image = @asset.Image::new(
    TEXTURE_SIZE,
    TEXTURE_SIZE,
    Bytes::from_array(texture_data),
  ).with_format(Rgba8UnormSrgb)
  let images : @ecs.ResourceMut[@asset.Assets[@asset.Image]] = @asset.asset_assets_ref_mut_or_abort()
  images.peek().add(image)
}

///|
fn mesh3d_from_geometry(geometry : @mesh.Mesh3dGeometry) -> @mesh.Mesh3d {
  @mesh.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val.add(
      @mesh.Mesh::from_3d_geometry(geometry),
    ),
  )
}

///|
fn spawn_shape(
  world : @ecs.World,
  mesh : @mesh.Mesh3d,
  material : @asset.Handle[@pbr.StandardMaterial],
  x : Float,
  row : Row,
) -> Unit {
  let entity = @pbr.MeshMaterial3dBundle::new(
    mesh,
    @pbr.MeshMaterial3d::new(material),
    @transform.Transform::from_xyz(x, 2.0F, row_z(row)).with_rotation(
      @math.Quat::from_rotation_x(-PI / 4.0F),
    ),
  ).spawn(world)
  shapes_state.val.entries.push({ entity, row })
}

///|
fn setup(world : @ecs.World) -> Unit {
  shapes_state.val.entries.clear()
  shapes_state.val.rotating = true

  let debug_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::white()).with_base_color_texture(
      Some(uv_debug_texture()),
    ),
  )

  let shapes = [
    mesh3d_from_geometry(
      @mesh_primitives_dim3.cuboid_mesh(@math.Cuboid::new(1.0F, 1.0F, 1.0F)),
    ),
    mesh3d_from_geometry(
      @mesh_primitives_dim3.tetrahedron_mesh(@math.Tetrahedron::default()),
    ),
    mesh3d_from_geometry(
      @mesh_primitives_dim3.capsule3d_mesh(@math.Capsule3d::default()),
    ),
    mesh3d_from_geometry(
      @mesh_primitives_dim3.torus_mesh(@math.Torus::default()),
    ),
    mesh3d_from_geometry(
      @mesh_primitives_dim3.cylinder_mesh(@math.Cylinder::default()),
    ),
    mesh3d_from_geometry(@mesh_primitives_dim3.cone_mesh(@math.Cone::default())),
    mesh3d_from_geometry(
      @mesh_primitives_dim3.conical_frustum_mesh(
        @math.ConicalFrustum::default(),
      ),
    ),
    mesh3d_from_geometry(@mesh_primitives_dim3.icosphere_mesh(0.5F, 5)),
    mesh3d_from_geometry(@mesh_primitives_dim3.uv_sphere_mesh(0.5F, 32, 18)),
    mesh3d_from_geometry(
      @mesh_primitives_dim3.segment3d_line_list(
        @math.Segment3d::new(
          @math.Vec3::new(-0.5F, 0.0F, 0.0F),
          @math.Vec3::new(0.5F, 0.0F, 0.0F),
        ),
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives_dim3.polyline3d_line_list(
        @math.Polyline3d::new([
          @math.Vec3::new(-0.5F, 0.0F, 0.0F),
          @math.Vec3::new(0.5F, 0.0F, 0.0F),
          @math.Vec3::new(0.0F, 0.5F, 0.0F),
        ]),
      ),
    ),
  ]

  let shape_count = shapes.length()
  for i in 0..<shape_count {
    spawn_shape(
      world,
      shapes[i],
      debug_material,
      spacing_at(i, shape_count, SHAPES_X_EXTENT),
      Front,
    )
  }

  let extrusions = [
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_rectangle_mesh(
        @math.Rectangle::default(),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_capsule2d_mesh(
        @math.Capsule2d::default(),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_annulus_mesh(@math.Annulus::default(), 1.0F),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_circle_mesh(@math.Circle::default(), 1.0F),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_ellipse_mesh(@math.Ellipse::default(), 1.0F),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_regular_polygon_mesh(
        @math.RegularPolygon::default(),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_triangle2d_mesh(
        @math.Triangle2d::default(),
        1.0F,
      ),
    ),
  ]

  let extrusion_count = extrusions.length()
  for i in 0..<extrusion_count {
    spawn_shape(
      world,
      extrusions[i],
      debug_material,
      spacing_at(i, extrusion_count, EXTRUSION_X_EXTENT),
      Middle,
    )
  }

  let ring_extrusions = [
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_rectangle_ring_mesh(
        @math.Rectangle::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_capsule2d_ring_mesh(
        @math.Capsule2d::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_ring2d_mesh(
        @math.Ring2d::new(1.0F, 0.5F),
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_circle_ring_mesh(
        @math.Circle::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_ellipse_ring_mesh(
        @math.Ellipse::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_regular_polygon_ring_mesh(
        @math.RegularPolygon::default(),
        THICKNESS,
        1.0F,
      ),
    ),
    mesh3d_from_geometry(
      @mesh_primitives.extrusion_triangle2d_ring_mesh(
        @math.Triangle2d::default(),
        1.0F,
      ),
    ),
  ]

  let ring_count = ring_extrusions.length()
  for i in 0..<ring_count {
    spawn_shape(
      world,
      ring_extrusions[i],
      debug_material,
      spacing_at(i, ring_count, EXTRUSION_X_EXTENT),
      Rear,
    )
  }

  let point_light = world.spawn_empty()
  try! world.set_by_key(
    point_light,
    @pbr.ecs_key_point_light,
    @pbr.PointLight::new(@sprite.Color::white(), 10_000_000.0F, 100.0F, true).with_shadow_depth_bias(
      0.2F,
    ),
  )
  try! world.set_by_key(
    point_light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(8.0F, 16.0F, 8.0F),
  )

  @pbr.MeshMaterial3dBundle::new(
    @mesh.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @mesh.Mesh::from_3d_geometry(
          @mesh_primitives_dim3.plane3d_mesh_from_size(50.0F, 50.0F, 10),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(
      @pbr.standard_material_add(
        @pbr.StandardMaterial::from_color(
          @sprite.Color::srgb(0.7529412F, 0.7529412F, 0.7529412F),
        ),
      ),
    ),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let _camera = @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 7.0F, 14.0F).looking_at(
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)

  let ui_camera = @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(100).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  try! world.set_by_key(
    ui_camera,
    @ui.ecs_key_is_default_ui_camera,
    @ui.IsDefaultUiCamera::default(),
  )

  let root = try! world.spawn_bundle(
    (
      @ui.UiRoot::default(),
      @ui.Node::default()
      .with_width(Percent(100.0F))
      .with_height(Percent(100.0F)),
      @ui.UiTargetCamera::new(ui_camera),
    ),
  )
  try! (world.spawn_bundle(
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
  )
  |> ignore)
}

///|
fn toggle_rotation(_world : @ecs.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    shapes_state.val.rotating = !shapes_state.val.rotating
  }
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in 3d_shapes example")
  }
}

///|
fn rotate(world : @ecs.World) -> Unit {
  if !shapes_state.val.rotating {
    return
  }
  let delta = world_time(world).delta_seconds() / 2.0F
  let spin = @math.Quat::from_rotation_y(delta)
  for entry in shapes_state.val.entries {
    if (try! world.get_by_key(entry.entity, @transform.ecs_key_transform))
      is Some(transform) {
      let next = transform.with_rotation(
        transform.rotation.mul(spin).normalize(),
      )
      try! (world.replace(entry.entity, @transform.ecs_key_transform, next)
      |> ignore)
    }
  }
}

///|
fn advance_rows(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Tab) {
    return
  }
  let count = shapes_state.val.entries.length()
  for i in 0..<count {
    let entry = shapes_state.val.entries[i]
    let next_row = row_advance(entry.row)
    shapes_state.val.entries[i] = { ..entry, row: next_row }
    if (try! world.get_by_key(entry.entity, @transform.ecs_key_transform))
      is Some(transform) {
      let next = transform.with_translation(
        @math.Vec3::new(
          transform.translation.x,
          transform.translation.y,
          row_z(next_row),
        ),
      )
      try! (world.replace(entry.entity, @transform.ecs_key_transform, next)
      |> ignore)
    }
  }
}

///|
fn toggle_wireframe(world : @ecs.World) -> Unit {
  if !@input.key_just_pressed(@window.KeyCode::Space) {
    return
  }
  let config = try world.get_resource(@pbr.ecs_key_wireframe_config) catch {
    _ => @pbr.WireframeConfig::default().with_global(true)
  } noraise {
    Some(value) => value.with_global(!value.global)
    None => @pbr.WireframeConfig::default().with_global(true)
  }
  world.insert_resource(@pbr.ecs_key_wireframe_config, config)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(
    @mgstudio.DefaultPlugins::set(@asset.AssetPlugin::default_nearest()),
  )
  .add_plugins(@pbr.WireframePlugin::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(toggle_rotation))
  .add_systems(@app.Update, @app.system(rotate))
  .add_systems(@app.Update, @app.system(advance_rows))
  .add_systems(@app.Update, @app.system(toggle_wireframe))
  .run()
}
