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
// Bevy source: `bevy/examples/3d/blend_modes.rs`.

///|
const CONTROL_TEXT : String = "Up / Down — Increase / Decrease Alpha\nLeft / Right — Rotate Camera\nH - Toggle HDR\nSpacebar — Toggle Unlit\nC — Randomize Colors"

///|
priv struct ExampleControls {
  unlit : Bool
  color : Bool
}

///|
let example_controls_key : @ecs.ComponentKey[ExampleControls] = @ecs.register_component(
  debug_name="examples.3d.blend_modes.ExampleControls",
)

///|
impl @ecs.Component for ExampleControls with fn component() {
  example_controls_key
}

///|
fn ExampleControls::ExampleControls(
  unlit~ : Bool,
  color~ : Bool,
) -> ExampleControls {
  { unlit, color }
}

///|
priv struct ExampleLabel {
  entity : @core.Entity
}

///|
let example_label_key : @ecs.ComponentKey[ExampleLabel] = @ecs.register_component(
  debug_name="examples.3d.blend_modes.ExampleLabel",
)

///|
impl @ecs.Component for ExampleLabel with fn component() {
  example_label_key
}

///|
fn ExampleLabel::ExampleLabel(entity : @core.Entity) -> ExampleLabel {
  { entity, }
}

///|
priv struct ExampleDisplay {}

///|
let example_display_key : @ecs.ComponentKey[ExampleDisplay] = @ecs.register_component(
  debug_name="examples.3d.blend_modes.ExampleDisplay",
)

///|
impl @ecs.Component for ExampleDisplay with fn component() {
  example_display_key
}

///|
priv struct ExampleState {
  mut alpha : Float
  mut unlit : Bool
  rng : @chacha_rng.ChaCha8Rng
}

///|
fn ExampleState::ExampleState() -> ExampleState {
  {
    alpha: 0.9F,
    unlit: false,
    rng: @chacha_rng.ChaCha8Rng::seed_from_u64(19878367467712UL),
  }
}

///|
impl @app.FromWorld for ExampleState with fn from_world(_world) {
  ExampleState()
}

///|
fn min_float(a : Float, b : Float) -> Float {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_float(a : Float, b : Float) -> Float {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn format_fixed(value : Float, decimals : Int) -> String {
  let clamped_decimals = if decimals < 0 { 0 } else { decimals }
  let mut scale = 1.0F
  for _ in 0..<clamped_decimals {
    scale = scale * 10.0F
  }
  let rounded = (value * scale).round().to_int()
  let sign = if rounded < 0 { "-" } else { "" }
  let abs_value = if rounded < 0 { -rounded } else { rounded }
  let whole = abs_value / scale.to_int()
  if clamped_decimals == 0 {
    "\{sign}\{whole}"
  } else {
    let frac_value = abs_value % scale.to_int()
    let mut frac = frac_value.to_string()
    while frac.length() < clamped_decimals {
      frac = "0" + frac
    }
    "\{sign}\{whole}.\{frac}"
  }
}

///|
fn random_color(rng : @chacha_rng.ChaCha8Rng, alpha : Float) -> @color.Color {
  @color.Color::srgba(
    rng.random_float(),
    rng.random_float(),
    rng.random_float(),
    alpha,
  )
}

///|
fn material_with_alpha(
  material : @pbr.StandardMaterial,
  alpha : Float,
) -> @pbr.StandardMaterial {
  material.with_base_color(material.base_color.with_alpha(alpha))
}

///|
fn add_standard_material(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  material : @pbr.StandardMaterial,
) -> @asset.Handle[@pbr.StandardMaterial] {
  materials.modify(fn(assets) { assets.add(material) })
}

///|
fn add_mesh(
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  mesh : @mesh.Mesh,
) -> @asset.Handle[@mesh.Mesh] {
  meshes.modify(fn(assets) { assets.add(mesh) })
}

///|
fn spawn_sphere(
  commands : @app.Commands,
  mesh : @asset.Handle[@mesh.Mesh],
  material : @asset.Handle[@pbr.StandardMaterial],
  translation : @math.Vec3,
) -> @core.Entity {
  commands.spawn(
    (
      @mesh.Mesh3d::new(mesh),
      @pbr.MeshMaterial3dTyped::new(material),
      @transform.Transform::from_translation(translation),
      ExampleControls::ExampleControls(unlit=true, color=true),
    ),
  )
}

///|
fn spawn_chessboard_square(
  commands : @app.Commands,
  mesh : @asset.Handle[@mesh.Mesh],
  material : @asset.Handle[@pbr.StandardMaterial],
  x : Int,
  z : Int,
) -> Unit {
  ignore(
    commands.spawn(
      (
        @mesh.Mesh3d::new(mesh),
        @pbr.MeshMaterial3dTyped::new(material),
        @transform.Transform::from_xyz(
          Float::from_int(x) * 2.0F,
          -1.0F,
          Float::from_int(z) * 2.0F,
        ),
        ExampleControls::ExampleControls(unlit=false, color=true),
      ),
    ),
  )
}

///|
fn spawn_label(
  commands : @app.Commands,
  font : @asset.Handle[@asset.Font],
  entity : @core.Entity,
  label : String,
) -> Unit {
  let label_node = commands.spawn(
    (
      @ui.Node::Node().with_position_type(Absolute),
      ExampleLabel::ExampleLabel(entity),
    ),
  )
  ignore(
    commands.spawn(
      (
        @hierarchy.Parent::new(label_node),
        @text.Text::new(label),
        @text.TextFont::TextFont().with_font(font),
        @text.TextColor::new(@palettes.css_orange()),
        @ui.Node::Node().with_position_type(Absolute).with_bottom(Px(0.0F)),
        @text.TextLayout::new_with_no_wrap(),
      ),
    ),
  )
}

///|
fn setup(
  commands : @app.Commands,
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let base_color = @color.Color::srgb(0.9F, 0.2F, 0.3F)
  let icosphere_mesh = add_mesh(
    meshes,
    @mesh.Mesh::from_3d_geometry(
      @mesh_primitives_dim3.SphereMeshBuilder::from_sphere(
        @math.Sphere::new(0.9F),
      ).ico(7) catch {
        _ => abort("blend_modes icosphere mesh generation failed")
      },
    ),
  )

  let opaque_entity = spawn_sphere(
    commands,
    icosphere_mesh,
    add_standard_material(
      materials,
      @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(Opaque),
    ),
    @math.Vec3::new(-4.0F, 0.0F, 0.0F),
  )

  let blend = spawn_sphere(
    commands,
    icosphere_mesh,
    add_standard_material(
      materials,
      @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(Blend),
    ),
    @math.Vec3::new(-2.0F, 0.0F, 0.0F),
  )

  let premultiplied = spawn_sphere(
    commands,
    icosphere_mesh,
    add_standard_material(
      materials,
      @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(
        Premultiplied,
      ),
    ),
    @math.Vec3::zero(),
  )

  let add = spawn_sphere(
    commands,
    icosphere_mesh,
    add_standard_material(
      materials,
      @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(Add),
    ),
    @math.Vec3::new(2.0F, 0.0F, 0.0F),
  )

  let multiply = spawn_sphere(
    commands,
    icosphere_mesh,
    add_standard_material(
      materials,
      @pbr.StandardMaterial::from_color(base_color).with_alpha_mode(Multiply),
    ),
    @math.Vec3::new(4.0F, 0.0F, 0.0F),
  )

  let black_material = add_standard_material(
    materials,
    @pbr.StandardMaterial::from_color(@color.Color::black()),
  )
  let white_material = add_standard_material(
    materials,
    @pbr.StandardMaterial::from_color(@color.Color::white()),
  )
  let plane_mesh = add_mesh(
    meshes,
    @mesh.Mesh::from_3d_geometry(
      @mesh_primitives_dim3.PlaneMeshBuilder::from_size(
        @math.Vec2::new(2.0F, 2.0F),
      ).build(),
    ),
  )

  for x in -3..<4 {
    for z in -3..<4 {
      spawn_chessboard_square(
        commands,
        plane_mesh,
        if (x + z) % 2 == 0 {
          black_material
        } else {
          white_material
        },
        x,
        z,
      )
    }
  }

  ignore(
    commands.spawn(
      (
        @pbr.PointLight::PointLight(),
        @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F),
      ),
    ),
  )

  let camera = commands.spawn(
    @pbr.Camera3dBundle::new(
      Camera(),
      @transform.Transform::from_xyz(0.0F, 2.5F, 10.0F).looking_at(
        @math.Vec3::zero(),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  commands.entity(camera).insert_component(@pbr.Hdr::Hdr())

  let font = asset_server.get().load_font("fonts/FiraMono-Medium.ttf")
  ignore(
    commands.spawn(
      (
        @text.Text::new(CONTROL_TEXT),
        @text.TextFont::TextFont().with_font(font),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_top(Px(12.0F))
        .with_left(Px(12.0F)),
      ),
    ),
  )
  ignore(
    commands.spawn(
      (
        @text.Text::Text(),
        @text.TextFont::TextFont().with_font(font),
        @ui.Node::Node()
        .with_position_type(Absolute)
        .with_top(Px(12.0F))
        .with_right(Px(12.0F)),
        ExampleDisplay::{  },
      ),
    ),
  )

  spawn_label(
    commands, font, opaque_entity, "┌─ Opaque\n│\n│\n│\n│",
  )
  spawn_label(commands, font, blend, "┌─ Blend\n│\n│\n│")
  spawn_label(commands, font, premultiplied, "┌─ Premultiplied\n│\n│")
  spawn_label(commands, font, add, "┌─ Add\n│")
  spawn_label(commands, font, multiply, "┌─ Multiply")
}

///|
fn update_materials(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  controllable : @ecs.Query[
    (@ecs.Read[@pbr.MeshMaterial3d], @ecs.Read[ExampleControls]),
    @ecs.All,
  ],
  state : ExampleState,
  randomize_colors : Bool,
) -> Unit {
  materials.modify(fn(assets) {
    try! controllable.view(fn(_entity, item) {
      let (mesh_material, controls) = item
      let handle = mesh_material.value().material
      guard assets.get(handle) is Some(material) else { return }
      let mut updated = if controls.value().color && randomize_colors {
        material.with_base_color(random_color(state.rng, state.alpha))
      } else {
        material_with_alpha(material, state.alpha)
      }
      if controls.value().unlit {
        updated = updated.with_unlit(state.unlit)
      }
      ignore(assets.insert(handle, updated))
    })
  })
}

///|
fn update_labels(
  labels : @ecs.Query[(@ecs.Write[@ui.Node], @ecs.Read[ExampleLabel]), @ecs.All],
  labeled : @ecs.Query[@ecs.Read[@transform.GlobalTransform], @ecs.All],
  camera : @camera_camera.Camera,
  projection : @pbr.Projection,
  camera_transform : @transform.Transform,
) -> Unit {
  let target_size = @math.IVec2::new(
    @window.window_width(),
    @window.window_height(),
  )
  let scale_factor = @window.window_scale_factor()
  try! labels.view(fn(_entity, item) {
    let (node, label) = item
    guard (labeled.get(label.value().entity) catch { _ => None })
      is Some(target_transform) else {
      return
    }
    let world_position = target_transform
      .value()
      .translation()
      .add(@math.Vec3::new(0.0F, 1.0F, 0.0F))
    guard @camera.camera_world_to_viewport(
        world_position, camera, projection, camera_transform, target_size, scale_factor,
      )
      is Some(viewport_position) else {
      return
    }
    node.set(
      node
      .value()
      .with_top(Px(viewport_position.y))
      .with_left(Px(viewport_position.x)),
    )
  })
}

///|
fn example_control_system(
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
  controllable : @ecs.Query[
    (@ecs.Read[@pbr.MeshMaterial3d], @ecs.Read[ExampleControls]),
    @ecs.All,
  ],
  camera : @app.Single[
    (
      @core.Entity,
      @ecs.Read[@camera_camera.Camera],
      @ecs.Write[@transform.Transform],
      @ecs.Read[@transform.GlobalTransform],
      @ecs.Read[@pbr.Projection],
      @ecs.Has[@pbr.Hdr],
    ),
    @ecs.With[@camera.Camera3d],
  ],
  labels : @ecs.Query[(@ecs.Write[@ui.Node], @ecs.Read[ExampleLabel]), @ecs.All],
  display : @app.Single[@ecs.Write[@text.Text], @ecs.With[ExampleDisplay]],
  labeled : @ecs.Query[@ecs.Read[@transform.GlobalTransform], @ecs.All],
  state_param : @app.Local[ExampleState],
  time : @app.Res[@time.Time[Unit]],
  input : @input.ButtonInput[@window.KeyCode],
  commands : @app.Commands,
) -> Unit {
  let delta = time.get().delta_seconds()
  let state = state_param.get()
  if input.pressed(ArrowUp) {
    state.alpha = min_float(state.alpha + delta, 1.0F)
  } else if input.pressed(ArrowDown) {
    state.alpha = max_float(state.alpha - delta, 0.0F)
  }

  if input.just_pressed(Space) {
    state.unlit = !state.unlit
  }

  let randomize_colors = input.just_pressed(KeyC)
  update_materials(materials, controllable, state, randomize_colors)

  let camera_data = camera.get()
  let (
    camera_entity,
    camera_component,
    camera_transform,
    _camera_global_transform,
    projection,
    hdr,
  ) = camera_data
  let hdr_enabled = hdr.present()
  if input.just_pressed(KeyH) {
    if hdr_enabled {
      commands.entity(camera_entity).remove(@pbr.ecs_key_hdr)
    } else {
      commands.entity(camera_entity).insert_component(@pbr.Hdr::Hdr())
    }
  }

  let rotation = if input.pressed(ArrowLeft) {
    delta
  } else if input.pressed(ArrowRight) {
    -delta
  } else {
    0.0F
  }

  camera_transform.modify(fn(value) {
    value.rotate_around(
      @math.Vec3::zero(),
      @math.Quat::from_rotation_y(rotation),
    )
  })

  update_labels(
    labels,
    labeled,
    camera_component.value(),
    projection.value(),
    camera_transform.value(),
  )

  display
  .get()
  .set(
    @text.Text::new(
      "  HDR: \{if hdr_enabled { "ON " } else { "OFF" }}\nAlpha: \{format_fixed(state.alpha, 2)}",
    ),
  )
  state_param.set(state)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::DefaultPlugins())
  .add_systems_param4(Startup, setup)
  .add_systems_param10(Update, example_control_system)
  .run()
}
