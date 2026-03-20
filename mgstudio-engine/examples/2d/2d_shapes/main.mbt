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
  .add_systems(@app.Startup, @app.system(shapes_setup))
  .add_systems(@app.Startup, @app.system(setup_wireframe2d_config))
  .add_system_query2_ecs(
    @transform.ecs_key_transform, @sprite.ecs_key_mesh2d, shapes_rotate,
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
let rotation_enabled : Ref[Bool] = Ref::new(false)

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
) -> @sprite.Color {
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
  @sprite.Color::new(r1 + m, g1 + m, b1 + m, 1.0F)
}

///|
fn shape_palette_color(index : Int, count : Int) -> @sprite.Color {
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
  world : @ecs.World,
  mesh : @sprite.Mesh2d,
  position : @math.Vec2,
  color : @sprite.Color,
) -> Unit {
  let material = @sprite.ColorMaterial::new(color)
  let transform = @transform.Transform::from_xy_rotation_scale(
    position,
    0.0F,
    @math.Vec2::new(1.0F, 1.0F),
  )
  @sprite.Mesh2dBundle::new(mesh, material, transform).spawn(world) |> ignore
}

///|
fn spawn_ui_text_handle(
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
) -> @text.TextHandle {
  @text.Text2dBundle::new(
    @text.Text2d::new(content),
    @text.TextFont::default().with_font(font).with_font_size(font_size),
    @transform.Transform::identity(),
  )
  .with_color(@text.TextColor::new(color))
  .with_layout(@text.TextLayout::new_with_justify(@text.Justify::Left))
  .spawn()
}

///|
fn spawn_help_overlay(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let text_handle = spawn_ui_text_handle(
    "Press 'R' to pause/resume rotation\nPress 'Space' to toggle wireframes",
    font,
    20.0F,
    @sprite.Color::white(),
  )
  let tick = world.read_change_tick()
  let root = world.spawn_empty()
  world.component(@ui.ecs_key_ui_root).insert(root, @ui.UiRoot::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    root,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
    tick,
  )
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(text_handle), tick)
}

///|
fn shapes_setup(world : @ecs.World) -> Unit {
  rotation_enabled.val = false

  let top_shapes : Array[@sprite.Mesh2d] = [
    @sprite.Mesh2d::from_circle(@sprite.Circle::new(50.0F)),
    @sprite.Mesh2d::from_circular_sector(
      @sprite.CircularSector::new(50.0F, 1.0F),
    ),
    @sprite.Mesh2d::from_circular_segment(
      @sprite.CircularSegment::new(50.0F, 1.25F),
    ),
    @sprite.Mesh2d::from_ellipse(@sprite.Ellipse::new(25.0F, 50.0F)),
    @sprite.Mesh2d::from_annulus(@sprite.Annulus::new(25.0F, 50.0F)),
    @sprite.Mesh2d::from_capsule(@sprite.Capsule2d::new(25.0F, 25.0F, 16)),
    @sprite.Mesh2d::from_rhombus(@sprite.Rhombus::new(75.0F, 100.0F)),
    @sprite.Mesh2d::from_rectangle(@sprite.Rectangle::new(50.0F, 100.0F)),
    @sprite.Mesh2d::from_regular_polygon(@sprite.RegularPolygon::new(50.0F, 6)),
    @sprite.Mesh2d::from_triangle(
      @sprite.Triangle2d::new(
        @math.Vec2::new(0.0F, 50.0F),
        @math.Vec2::new(-50.0F, -50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    @sprite.Mesh2d::from_segment(
      @sprite.Segment2d::new(
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(50.0F, -50.0F),
      ),
    ),
    @sprite.Mesh2d::from_polyline(
      @sprite.Polyline2d::new([
        @math.Vec2::new(-50.0F, 50.0F),
        @math.Vec2::new(0.0F, -50.0F),
        @math.Vec2::new(50.0F, 50.0F),
      ]),
    ),
  ]
  let rings : Array[@sprite.Mesh2d] = [
    @sprite.Mesh2d::from_ring(@sprite.Circle::new(50.0F).to_ring(THICKNESS)),
    @sprite.Mesh2d::from_circular_sector_ring(
      @sprite.CircularSectorRing::new(
        @sprite.CircularSector::new(50.0F, 1.0F),
        @sprite.CircularSector::new(45.0F, 1.0F),
      ),
    ),
    @sprite.Mesh2d::from_circular_segment_ring(
      @sprite.CircularSegment::new(50.0F, 1.25F).to_ring(THICKNESS),
    ),
    @sprite.Mesh2d::from_ellipse_ring(
      @sprite.EllipseRing::new(
        @sprite.Ellipse::new(25.0F, 50.0F),
        @sprite.Ellipse::new(25.0F - THICKNESS, 50.0F - THICKNESS),
      ),
    ),
    @sprite.Mesh2d::from_ring(@sprite.Ring2d::new(50.0F, 25.0F)),
    @sprite.Mesh2d::from_capsule_ring(
      @sprite.Capsule2d::new(25.0F, 25.0F, 16).to_ring(THICKNESS),
    ),
    @sprite.Mesh2d::from_rhombus_ring(
      @sprite.Rhombus::new(75.0F, 100.0F).to_ring(THICKNESS),
    ),
    @sprite.Mesh2d::from_rectangle_ring(
      @sprite.Rectangle::new(50.0F, 100.0F).to_ring(THICKNESS),
    ),
    @sprite.Mesh2d::from_regular_polygon_ring(
      @sprite.RegularPolygon::new(50.0F, 6).to_ring(THICKNESS),
    ),
    @sprite.Mesh2d::from_triangle_ring(
      @sprite.Triangle2d::new(
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
  let camera = @sprite.Camera::default()
  @sprite.Camera2dBundle::new(camera, @transform.Transform::identity()).spawn(
    world,
  )
  |> ignore

  spawn_help_overlay(world)
}

///|
fn setup_wireframe2d_config(world : @ecs.World) -> Unit {
  let config = @sprite.Wireframe2dConfig::new(false, @sprite.Color::white())
  world.insert_resource(@sprite.ecs_key_wireframe2d_config, config)
}

///|
fn world_time(world : @ecs.World) -> @time.Time[Unit] {
  match (try! world.get_resource(@time.default_time_resource_key())) {
    Some(time) => time
    None => abort("Missing Time<Unit> resource in 2d_shapes example")
  }
}

///|
fn shapes_rotate(
  query : @ecs.Query2[@transform.Transform, @sprite.Mesh2d],
  world : @ecs.World,
) -> Unit {
  if @input.key_just_pressed(@window.KeyCode::Space) {
    if (try? world.get_resource(@sprite.ecs_key_wireframe2d_config))
      is Ok(Some(config)) {
      world.insert_resource(
        @sprite.ecs_key_wireframe2d_config,
        config.with_global(!config.global),
      )
    }
  }
  if @input.key_just_pressed(@window.KeyCode::KeyR) {
    rotation_enabled.val = !rotation_enabled.val
  }

  if !rotation_enabled.val {
    return
  }

  let delta_secs = world_time(world).delta_seconds()
  let speed = 0.5F
  try! query.for_each(fn(_entity, transform, _mesh) {
    let next_rotation = transform.rotation_z() + speed * delta_secs
    transform.rotation = @math.Quat::from_rotation_z(next_rotation)
  })
}
