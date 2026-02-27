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
///
/// Notes:
/// - Bevy uses GPU polygon line mode for wireframe toggling.
/// - mgstudio currently maps this to a gizmo-based wireframe overlay path.
pub fn game_app() -> Unit {
  let plugins : Array[@app.Plugin[@ecs_world.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs_world.World::new())
  .add_plugins(plugins)
  .add_startup_system(shapes_setup)
  .add_system(shapes_rotate)
  .run()
}

///|
const X_EXTENT : Float = 1000.0F

///|
const Y_EXTENT : Float = 150.0F

///|
const THICKNESS : Float = 5.0F

///|
let rotation_enabled : Ref[Bool] = Ref::new(false)

///|
let wireframe_enabled : Ref[Bool] = Ref::new(false)

///|
fn absf(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn hsl_to_color(
  hue_degrees : Float,
  saturation : Float,
  lightness : Float,
) -> @render2d.Color {
  let chroma = (1.0F - absf(2.0F * lightness - 1.0F)) * saturation
  let hue_section = hue_degrees / 60.0F
  let x = if hue_section < 1.0F {
    chroma * hue_section
  } else if hue_section < 2.0F {
    chroma * (2.0F - hue_section)
  } else if hue_section < 3.0F {
    chroma * (hue_section - 2.0F)
  } else if hue_section < 4.0F {
    chroma * (4.0F - hue_section)
  } else if hue_section < 5.0F {
    chroma * (hue_section - 4.0F)
  } else {
    chroma * (6.0F - hue_section)
  }

  let mut r1 = 0.0F
  let mut g1 = 0.0F
  let mut b1 = 0.0F
  if hue_section < 1.0F {
    r1 = chroma
    g1 = x
  } else if hue_section < 2.0F {
    r1 = x
    g1 = chroma
  } else if hue_section < 3.0F {
    g1 = chroma
    b1 = x
  } else if hue_section < 4.0F {
    g1 = x
    b1 = chroma
  } else if hue_section < 5.0F {
    r1 = x
    b1 = chroma
  } else {
    r1 = chroma
    b1 = x
  }

  let m = lightness - chroma / 2.0F
  @render2d.Color::new(r1 + m, g1 + m, b1 + m, 1.0F)
}

///|
fn shape_palette_color(index : Int, count : Int) -> @render2d.Color {
  let safe_count = if count <= 0 { 1 } else { count }
  let hue = 360.0F *
    Float::from_double(index.to_double()) /
    Float::from_double(safe_count.to_double())
  hsl_to_color(hue, 0.95F, 0.7F)
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
  world : @ecs_world.World,
  mesh : @render2d.Mesh2d,
  position : @math.Vec2,
  color : @render2d.Color,
) -> Unit {
  let material = @render2d.ColorMaterial::new(color)
  let transform = @math.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @render2d.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @render2d.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @math.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn spawn_help_overlay(world : @ecs_world.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = spawn_ui_text_handle(
    "Press 'R' to pause/resume rotation\nPress 'Space' to toggle wireframes",
    font,
    20.0F,
    @render2d.Color::white(),
  )
  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.get_ui_root_store().insert(root, @ui.UiRoot::default(), tick)
  world
  .get_node_store()
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  let text_entity = world.spawn_empty()
  world
  .get_parent_store()
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .get_node_store()
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .get_ui_text_store()
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn shapes_setup(world : @ecs_world.World) -> Unit {
  rotation_enabled.val = false
  wireframe_enabled.val = false

  let top_shapes : Array[@render2d.Mesh2d] = [
    @render2d.Mesh2d::from_circle(@render2d.Circle::new(50.0F)),
    @render2d.Mesh2d::from_circular_sector(
      @render2d.CircularSector::new(50.0F, 1.0F),
    ),
    @render2d.Mesh2d::from_circular_segment(
      @render2d.CircularSegment::new(50.0F, 1.25F),
    ),
    @render2d.Mesh2d::from_ellipse(@render2d.Ellipse::new(25.0F, 50.0F)),
    @render2d.Mesh2d::from_annulus(@render2d.Annulus::new(25.0F, 50.0F)),
    @render2d.Mesh2d::from_capsule(@render2d.Capsule2d::new(25.0F, 25.0F, 16)),
    @render2d.Mesh2d::from_rhombus(@render2d.Rhombus::new(75.0F, 100.0F)),
    @render2d.Mesh2d::from_rectangle(@render2d.Rectangle::new(50.0F, 100.0F)),
    @render2d.Mesh2d::from_regular_polygon(
      @render2d.RegularPolygon::new(50.0F, 6),
    ),
    @render2d.Mesh2d::from_triangle(
      @render2d.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    @render2d.Mesh2d::from_segment(
      @render2d.Segment2d::new(
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    @render2d.Mesh2d::from_polyline(
      @render2d.Polyline2d::new([
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(0.0F, -50.0F),
        @math.Vec2::new(50.0F, 50.0F),
      ]),
    ),
  ]
  let rings : Array[@render2d.Mesh2d] = [
    @render2d.Mesh2d::from_ring(@render2d.Circle::new(50.0F).to_ring(THICKNESS)),
    @render2d.Mesh2d::from_circular_sector_ring(
      @render2d.CircularSectorRing::new(
        @render2d.CircularSector::new(50.0F, 1.0F),
        @render2d.CircularSector::new(45.0F, 1.0F),
      ),
    ),
    @render2d.Mesh2d::from_circular_segment_ring(
      @render2d.CircularSegment::new(50.0F, 1.25F).to_ring(THICKNESS),
    ),
    @render2d.Mesh2d::from_ellipse_ring(
      @render2d.EllipseRing::new(
        @render2d.Ellipse::new(25.0F, 50.0F),
        @render2d.Ellipse::new(25.0F - THICKNESS, 50.0F - THICKNESS),
      ),
    ),
    @render2d.Mesh2d::from_ring(@render2d.Ring2d::new(50.0F, 25.0F)),
    @render2d.Mesh2d::from_capsule_ring(
      @render2d.Capsule2d::new(25.0F, 25.0F, 16).to_ring(THICKNESS),
    ),
    @render2d.Mesh2d::from_rhombus_ring(
      @render2d.Rhombus::new(75.0F, 100.0F).to_ring(THICKNESS),
    ),
    @render2d.Mesh2d::from_rectangle_ring(
      @render2d.Rectangle::new(50.0F, 100.0F).to_ring(THICKNESS),
    ),
    @render2d.Mesh2d::from_regular_polygon_ring(
      @render2d.RegularPolygon::new(50.0F, 6).to_ring(THICKNESS),
    ),
    @render2d.Mesh2d::from_triangle_ring(
      @render2d.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ).to_ring(THICKNESS),
    ),
  ]

  let num_shapes = top_shapes.length()
  for i in 0..<num_shapes {
    spawn_shape(
      world,
      top_shapes[i],
      @math.Vec2::new(lane_x(i, num_shapes, X_EXTENT), Y_EXTENT / 2.0F),
      shape_palette_color(i, num_shapes),
    )
  }
  let num_rings = rings.length() + 2
  for i in 0..<rings.length() {
    spawn_shape(
      world,
      rings[i],
      @math.Vec2::new(lane_x(i, num_rings, X_EXTENT), -Y_EXTENT / 2.0F),
      shape_palette_color(i, num_rings),
    )
  }
  let camera = @render2d.Camera::default()
  @render2d.Camera2dBundle::new(camera, @math.Transform::identity()).spawn(
    world,
  )
  |> ignore

  spawn_help_overlay(world)
}

///|
fn shapes_rotate(world : @ecs_world.World) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    wireframe_enabled.val = !wireframe_enabled.val
  }
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    rotation_enabled.val = !rotation_enabled.val
  }

  if wireframe_enabled.val {
    let gizmos = @render2d.Gizmos::new()
    let transform_store = world.get_transform_store()
    let mesh_store = world.get_mesh2d_store()
    @core.query2(transform_store, mesh_store, fn(_entity, transform, mesh2d) {
      if @render2d.render_mesh_asset_get(mesh2d.mesh) is Some(mesh_asset) {
        match mesh_asset.geometry {
          @mesh.MeshGeometry::Geometry2d(geometry2d) =>
            gizmos.mesh_wireframe_2d(
              geometry2d,
              transform,
              @render2d.Color::white(),
            )
          _ => ()
        }
      }
    })
  }

  if !rotation_enabled.val {
    return
  }

  let delta_secs = @time.time_delta_seconds()
  let speed = 0.5F
  let tick = world.read_change_tick()
  let transform_store = world.get_transform_store()
  let mesh_store = world.get_mesh2d_store()
  let entities : Array[(@core.Entity, @math.Transform)] = []
  @core.query2(transform_store, mesh_store, fn(entity, transform, _mesh) {
    entities.push((entity, transform))
  })
  for entry in entities {
    let entity = entry.0
    let transform = entry.1
    let next_rotation = transform.rotation_z() + speed * delta_secs
    let next_transform = @math.Transform::from_xy_rotation_scale(
      @math.Vec2::new(transform.translation.x, transform.translation.y),
      next_rotation,
      @math.Vec2::new(transform.scale.x, transform.scale.y),
      z=transform.translation.z,
    )
    transform_store.set(entity, next_transform, tick) |> ignore
  }
}
