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
///
/// Baseline parity:
/// - This example now attaches `ClusteredDecal` components directly with Bevy-
///   aligned texture/tag data.
/// - This port preserves Bevy's control model (selection + drag mode) and
///   scene layout, mapping decals onto textured translucent proxy meshes.

///|
const CUBE_ROTATION_SPEED : Float = 0.02F

///|
const PI : Float = 3.141592653589793F

///|
const MOVE_SPEED : Float = 0.008F

///|
const SCALE_SPEED : Float = 0.05F

///|
const ROLL_SPEED : Float = 0.01F

///|
const BUTTON_BORDER_RADIUS : Float = 12.0F

///|
const BUTTON_HORIZONTAL_PADDING : Float = 12.0F

///|
const BUTTON_VERTICAL_PADDING : Float = 6.0F

///|
pub(all) enum Selection {
  Camera
  DecalA
  DecalB
} derive(Eq, Debug)

///|
pub(all) enum DragMode {
  Move
  Scale
  Roll
} derive(Eq, Debug)

///|
priv struct SelectionWidget {
  button : @core.Entity
  selection : Selection
}

///|
priv struct DragModeWidget {
  button : @core.Entity
  mode : DragMode
}

///|
priv struct ClusteredDecalsState {
  mut camera : @core.Entity?
  mut rotating_cube : @core.Entity?
  mut selection : Selection
  mut drag_mode : DragMode
  mut decal_a : @core.Entity?
  mut decal_b : @core.Entity?
  mut help_text : @core.Entity?
  mut drag_mode_panel : @core.Entity?
  selection_widgets : Array[SelectionWidget]
  drag_mode_widgets : Array[DragModeWidget]
  mut last_mouse : @math.Vec2?
}

///|
let clustered_decals_state : Ref[ClusteredDecalsState] = Ref({
  camera: None,
  rotating_cube: None,
  selection: Selection::Camera,
  drag_mode: DragMode::Move,
  decal_a: None,
  decal_b: None,
  help_text: None,
  drag_mode_panel: None,
  selection_widgets: [],
  drag_mode_widgets: [],
  last_mouse: None,
})

///|
fn selection_text(selection : Selection) -> String {
  match selection {
    Selection::Camera => "camera"
    Selection::DecalA => "decal A"
    Selection::DecalB => "decal B"
  }
}

///|
fn drag_mode_text(mode : DragMode) -> String {
  match mode {
    DragMode::Move => "move"
    DragMode::Scale => "scale"
    DragMode::Roll => "roll"
  }
}

///|
fn create_help_text() -> String {
  "Click and drag to \{drag_mode_text(clustered_decals_state.val.drag_mode)} \{selection_text(clustered_decals_state.val.selection)}"
}

///|
fn update_help_text() -> Unit {
  guard clustered_decals_state.val.help_text is Some(entity) else { return }
  guard @app.current_world() is Some(world) else { return }
  guard (try! world.get_by_key(entity, @text.ecs_key_text)) is Some(text_value) else {
    return
  }
  text_value.content = create_help_text()
  ignore(try! world.replace(entity, @text.ecs_key_text, text_value))
}

///|
fn button_background(selected : Bool) -> @ui.BackgroundColor {
  @ui.BackgroundColor::new(
    if selected {
      @sprite.Color::white()
    } else {
      @sprite.Color::black()
    },
  )
}

///|
fn button_border(selected : Bool) -> @ui.BorderColor {
  @ui.BorderColor::new(
    if selected {
      @sprite.Color::black()
    } else {
      @sprite.Color::white()
    },
  )
}

///|
fn same_entity(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn spawn_button(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
) -> @core.Entity {
  let button = world.spawn_empty()
  try! world.set_by_key(
    button,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(parent),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
    .with_padding(
      @ui.UiRect::new(
        @ui.Val::Px(BUTTON_HORIZONTAL_PADDING),
        @ui.Val::Px(BUTTON_HORIZONTAL_PADDING),
        @ui.Val::Px(BUTTON_VERTICAL_PADDING),
        @ui.Val::Px(BUTTON_VERTICAL_PADDING),
      ),
    )
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_border_radius(
      @ui.BorderRadius::all(@ui.Val::Px(BUTTON_BORDER_RADIUS)),
    ),
  )
  try! world.set_by_key(button, @ui.ecs_key_button, @ui.Button::default())
  try! world.set_by_key(
    button,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
    .with_padding(
      @ui.UiRect::new(
        @ui.Val::Px(BUTTON_HORIZONTAL_PADDING),
        @ui.Val::Px(BUTTON_HORIZONTAL_PADDING),
        @ui.Val::Px(BUTTON_VERTICAL_PADDING),
        @ui.Val::Px(BUTTON_VERTICAL_PADDING),
      ),
    )
    .with_justify_content(@ui.JustifyContent::Center)
    .with_align_items(@ui.AlignItems::Center)
    .with_border_radius(
      @ui.BorderRadius::all(@ui.Val::Px(BUTTON_BORDER_RADIUS)),
    ),
  )
  try! world.set_by_key(
    button,
    @ui.ecs_key_background_color,
    button_background(false),
  )
  try! world.set_by_key(button, @ui.ecs_key_border_color, button_border(false))

  let text_entity = world.spawn_empty()
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
  )
  try! world.set_by_key(text_entity, @text.ecs_key_text, @text.Text::new(label))
  try! world.set_by_key(
    text_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(button),
  )
  try! world.set_by_key(
    text_entity,
    @ui.ecs_key_node,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
  )
  try! world.set_by_key(text_entity, @text.ecs_key_text, @text.Text::new(label))
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
  )
  try! world.set_by_key(
    text_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )

  button
}

///|
fn setup_ui(world : @ecs.World, font : @asset.Handle[@asset.Font]) -> Unit {
  @sprite.Camera2dBundle::new(
    @sprite.Camera::default().with_order(100).with_clear_color_none(),
    @transform.Transform::identity(),
  ).spawn(world)
  |> ignore

  let root = world.spawn_empty()
  try! world.set_by_key(root, @ui.ecs_key_ui_root, @ui.UiRoot::default())
  try! world.set_by_key(
    root,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Percent(100.0F))
    .with_height(@ui.Val::Percent(100.0F)),
  )

  let help_entity = world.spawn_empty()
  try! world.set_by_key(
    help_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    help_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
  )
  try! world.set_by_key(help_entity, @text.ecs_key_text, @text.Text::new(""))
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(help_entity, @text.ecs_key_text, @text.Text::new(""))
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )
  try! world.set_by_key(
    help_entity,
    @text.ecs_key_text_layout,
    @text.TextLayout::new_with_justify(@text.Justify::Left),
  )
  clustered_decals_state.val.help_text = Some(help_entity)

  let selection_panel = world.spawn_empty()
  try! world.set_by_key(
    selection_panel,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    selection_panel,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(10.0F))
    .with_bottom(@ui.Val::Px(10.0F))
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_row_gap(@ui.Val::Px(6.0F))
    .with_align_items(@ui.AlignItems::Center),
  )

  let hint_entity = world.spawn_empty()
  try! world.set_by_key(
    hint_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(selection_panel),
  )
  try! world.set_by_key(
    hint_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(selection_panel),
  )
  try! world.set_by_key(
    hint_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(125.0F))
    .with_height(@ui.Val::Auto),
  )
  try! world.set_by_key(
    hint_entity,
    @text.ecs_key_text,
    @text.Text::new("Drag to Move"),
  )
  try! world.set_by_key(
    hint_entity,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(selection_panel),
  )
  try! world.set_by_key(
    hint_entity,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_width(@ui.Val::Px(125.0F))
    .with_height(@ui.Val::Auto),
  )
  try! world.set_by_key(
    hint_entity,
    @text.ecs_key_text,
    @text.Text::new("Drag to Move"),
  )
  try! world.set_by_key(
    hint_entity,
    @text.ecs_key_text_font,
    @text.TextFont::default().with_font(font).with_font_size(16.0F),
  )
  try! world.set_by_key(
    hint_entity,
    @text.ecs_key_text_color,
    @text.TextColor::new(@sprite.Color::white()),
  )

  let camera_button = spawn_button(world, selection_panel, font, "Camera")
  clustered_decals_state.val.selection_widgets.push({
    button: camera_button,
    selection: Selection::Camera,
  })

  let decal_a_button = spawn_button(world, selection_panel, font, "Decal A")
  clustered_decals_state.val.selection_widgets.push({
    button: decal_a_button,
    selection: Selection::DecalA,
  })

  let decal_b_button = spawn_button(world, selection_panel, font, "Decal B")
  clustered_decals_state.val.selection_widgets.push({
    button: decal_b_button,
    selection: Selection::DecalB,
  })

  let drag_mode_panel = world.spawn_empty()
  try! world.set_by_key(
    drag_mode_panel,
    @hierarchy.ecs_key_parent,
    @hierarchy.Parent::new(root),
  )
  try! world.set_by_key(
    drag_mode_panel,
    @ui.ecs_key_node,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_right(@ui.Val::Px(10.0F))
    .with_bottom(@ui.Val::Px(10.0F))
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_row_gap(@ui.Val::Px(6.0F)),
  )
  clustered_decals_state.val.drag_mode_panel = Some(drag_mode_panel)

  let scale_button = spawn_button(world, drag_mode_panel, font, "Scale")
  clustered_decals_state.val.drag_mode_widgets.push({
    button: scale_button,
    mode: DragMode::Scale,
  })

  let roll_button = spawn_button(world, drag_mode_panel, font, "Roll")
  clustered_decals_state.val.drag_mode_widgets.push({
    button: roll_button,
    mode: DragMode::Roll,
  })
}

///|
fn update_ui_state(world : @ecs.World) -> Unit {
  for widget in clustered_decals_state.val.selection_widgets {
    let selected = widget.selection == clustered_decals_state.val.selection
    if (try! world.contains_by_key(widget.button, @ui.ecs_key_background_color)) {
      try! (world.replace(
        widget.button,
        @ui.ecs_key_background_color,
        button_background(selected),
      )
      |> ignore)
    } else {
      try! world.set_by_key(
        widget.button,
        @ui.ecs_key_background_color,
        button_background(selected),
      )
    }
    if (try! world.contains_by_key(widget.button, @ui.ecs_key_border_color)) {
      try! (world.replace(
        widget.button,
        @ui.ecs_key_border_color,
        button_border(selected),
      )
      |> ignore)
    } else {
      try! world.set_by_key(
        widget.button,
        @ui.ecs_key_border_color,
        button_border(selected),
      )
    }
  }

  for widget in clustered_decals_state.val.drag_mode_widgets {
    let selected = clustered_decals_state.val.drag_mode == widget.mode
    if (try! world.contains_by_key(widget.button, @ui.ecs_key_background_color)) {
      try! (world.replace(
        widget.button,
        @ui.ecs_key_background_color,
        button_background(selected),
      )
      |> ignore)
    } else {
      try! world.set_by_key(
        widget.button,
        @ui.ecs_key_background_color,
        button_background(selected),
      )
    }
    if (try! world.contains_by_key(widget.button, @ui.ecs_key_border_color)) {
      try! (world.replace(
        widget.button,
        @ui.ecs_key_border_color,
        button_border(selected),
      )
      |> ignore)
    } else {
      try! world.set_by_key(
        widget.button,
        @ui.ecs_key_border_color,
        button_border(selected),
      )
    }
  }

  if clustered_decals_state.val.drag_mode_panel is Some(panel) {
    if (try! world.get_by_key(panel, @ui.ecs_key_node)) is Some(node) {
      let show_drag_buttons = clustered_decals_state.val.selection !=
        Selection::Camera
      try! (world.replace(
        panel,
        @ui.ecs_key_node,
        node.with_display(
          if show_drag_buttons {
            @ui.Display::Flex
          } else {
            @ui.Display::None
          },
        ),
      )
      |> ignore)
    }
  }

  update_help_text()
}

///|
fn calculate_initial_decal_transform(
  position : @math.Vec3,
  target : @math.Vec3,
  size : @math.Vec2,
) -> @transform.Transform {
  let direction = target.sub(position)
  let center = position.add(direction.mul_scalar(0.5F))
  @transform.Transform::from_xyz(center.x, center.y, center.z)
  .with_scale(@math.Vec3::new(size.x * 0.5F, size.y * 0.5F, direction.length()))
  .looking_at(target, @math.Vec3::new(0.0F, 1.0F, 0.0F))
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  clustered_decals_state.val.camera = None
  clustered_decals_state.val.rotating_cube = None
  clustered_decals_state.val.selection = Selection::Camera
  clustered_decals_state.val.drag_mode = DragMode::Move
  clustered_decals_state.val.decal_a = None
  clustered_decals_state.val.decal_b = None
  clustered_decals_state.val.help_text = None
  clustered_decals_state.val.drag_mode_panel = None
  clustered_decals_state.val.selection_widgets.clear()
  clustered_decals_state.val.drag_mode_widgets.clear()
  clustered_decals_state.val.last_mouse = None

  let cube_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.75F, 0.75F, 0.75F, 1.0F),
    ),
  )
  let cube = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(3.0F, 3.0F, 3.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(cube_material),
    @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(1.0471975512F),
    ),
  ).spawn(world)
  clustered_decals_state.val.rotating_cube = Some(cube)

  let camera = @camera.Camera3dBundle::new(
    @sprite.Camera::default(),
    @transform.Transform::from_xyz(0.0F, 2.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  clustered_decals_state.val.camera = Some(camera)

  let light = world.spawn_empty()
  try! world.set_by_key(
    light,
    @pbr.ecs_key_directional_light,
    @pbr.DirectionalLight::default(),
  )
  try! world.set_by_key(
    light,
    @transform.ecs_key_transform,
    @transform.Transform::from_xyz(4.0F, 8.0F, 4.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  )

  let decal_texture = asset_server.load("branding/icon.png")
  let decal_a_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(1.0F, 0.27F, 0.0F, 0.80F),
    )
    .with_base_color_texture(Some(decal_texture))
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let decal_b_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(
      @sprite.Color::new(0.0F, 1.0F, 0.0F, 0.80F),
    )
    .with_base_color_texture(Some(decal_texture))
    .with_alpha_mode(@pbr.AlphaMode3d::Blend)
    .with_unlit(true),
  )

  let decal_a = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(decal_a_material),
    calculate_initial_decal_transform(
      @math.Vec3::new(1.0F, 3.0F, 5.0F),
      @math.Vec3::zero(),
      @math.Vec2::new(1.1F, 1.1F),
    ),
  ).spawn(world)
  try! world.set_by_key(
    decal_a,
    @pbr.ecs_key_clustered_decal,
    @pbr.ClusteredDecal::default()
    .with_base_color_texture(Some(decal_texture))
    .with_tag(1),
  )
  clustered_decals_state.val.decal_a = Some(decal_a)

  let decal_b = @pbr.MeshMaterial3dBundle::new(
    @pbr.Mesh3d::new(
      @pbr.mesh_assets_mut_or_abort().val.add(
        @pbr.Mesh::from_3d_geometry(
          @pbr.mesh3d_geometry_cuboid(1.0F, 1.0F, 1.0F),
        ),
      ),
    ),
    @pbr.MeshMaterial3d::new(decal_b_material),
    calculate_initial_decal_transform(
      @math.Vec3::new(-2.0F, -1.0F, 4.0F),
      @math.Vec3::zero(),
      @math.Vec2::new(2.0F, 2.0F),
    ),
  ).spawn(world)
  try! world.set_by_key(
    decal_b,
    @pbr.ecs_key_clustered_decal,
    @pbr.ClusteredDecal::default()
    .with_base_color_texture(Some(decal_texture))
    .with_tag(2),
  )
  clustered_decals_state.val.decal_b = Some(decal_b)

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  setup_ui(world, font)
  update_ui_state(world)
}

///|
fn selected_entity() -> @core.Entity? {
  match clustered_decals_state.val.selection {
    Selection::Camera => clustered_decals_state.val.camera
    Selection::DecalA => clustered_decals_state.val.decal_a
    Selection::DecalB => clustered_decals_state.val.decal_b
  }
}

///|
fn clampf(value : Float, min_value : Float, max_value : Float) -> Float {
  if value < min_value {
    min_value
  } else if value > max_value {
    max_value
  } else {
    value
  }
}

///|
fn spherical_drag_translation(
  position : @math.Vec3,
  delta : @math.Vec2,
  phi_factor : Float,
  theta_factor : Float,
) -> @math.Vec3 {
  let radius = position.length()
  let safe_radius = if radius < 0.001F { 0.001F } else { radius }
  let horizontal = @math.sqrt(position.x * position.x + position.z * position.z)
  let mut theta = @math.atan2(horizontal, position.y)
  let mut phi = @math.atan2(position.z, position.x)
  phi = phi + phi_factor * delta.x * MOVE_SPEED
  theta = clampf(
    theta + theta_factor * delta.y * MOVE_SPEED,
    0.001F,
    PI - 0.001F,
  )
  let sin_theta = @math.sin(theta)
  @math.Vec3::new(
    safe_radius * sin_theta * @math.cos(phi),
    safe_radius * @math.cos(theta),
    safe_radius * sin_theta * @math.sin(phi),
  )
}

///|
fn orient_towards_center_preserve_roll(
  transform : @transform.Transform,
  translation : @math.Vec3,
) -> @transform.Transform {
  let roll = transform.rotation.to_rotation_z_angle()
  let oriented = transform
    .with_translation(translation)
    .looking_at(@math.Vec3::zero(), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  oriented.with_rotation(
    oriented.rotation.mul(@math.Quat::from_rotation_z(roll)).normalize(),
  )
}

///|
fn apply_drag_translation(
  world : @ecs.World,
  entity : @core.Entity,
  delta : @math.Vec2,
  phi_factor : Float,
  theta_factor : Float,
) -> Unit {
  guard (try! world.get_by_key(entity, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  let next_translation = spherical_drag_translation(
    transform.translation,
    delta,
    phi_factor,
    theta_factor,
  )
  try! (world.replace(
    entity,
    @transform.ecs_key_transform,
    orient_towards_center_preserve_roll(transform, next_translation),
  )
  |> ignore)
}

///|
fn apply_camera_drag(
  world : @ecs.World,
  camera_entity : @core.Entity,
  delta : @math.Vec2,
) -> Unit {
  apply_drag_translation(world, camera_entity, delta, 1.0F, -1.0F)
}

///|
fn apply_decal_drag(
  world : @ecs.World,
  entity : @core.Entity,
  delta : @math.Vec2,
) -> Unit {
  guard (try! world.get_by_key(entity, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  match clustered_decals_state.val.drag_mode {
    DragMode::Move => apply_drag_translation(world, entity, delta, -1.0F, 1.0F)
    DragMode::Scale => {
      let scale_factor = if 1.0F + delta.x * SCALE_SPEED < 0.05F {
        0.05F
      } else {
        1.0F + delta.x * SCALE_SPEED
      }
      try! (world.replace(
        entity,
        @transform.ecs_key_transform,
        transform.with_scale(transform.scale.mul_scalar(scale_factor)),
      )
      |> ignore)
    }
    DragMode::Roll => {
      let rotation = transform.rotation
        .mul(@math.Quat::from_rotation_z(delta.x * ROLL_SPEED))
        .normalize()
      try! (world.replace(
        entity,
        @transform.ecs_key_transform,
        transform.with_rotation(rotation),
      )
      |> ignore)
    }
  }
}

///|
fn handle_selection_change(world : @ecs.World) -> Bool {
  let mut changed = false
  world.for_each_component(@ui.ecs_key_interaction, fn(entity, interaction) {
    if interaction != @ui.Interaction::Pressed {
      return
    }
    for widget in clustered_decals_state.val.selection_widgets {
      if same_entity(widget.button, entity) &&
        clustered_decals_state.val.selection != widget.selection {
        clustered_decals_state.val.selection = widget.selection
        changed = true
        break
      }
    }
  })
  changed
}

///|
fn switch_drag_mode(world : @ecs.World) -> Bool {
  let mut next_mode = DragMode::Move
  let mut hover_resize_cursor = false
  if clustered_decals_state.val.selection != Selection::Camera &&
    !@input.mouse_button_pressed(@window.MouseButton::Left) {
    for widget in clustered_decals_state.val.drag_mode_widgets {
      if (try! world.get_by_key(widget.button, @ui.ecs_key_interaction))
        is Some(interaction) {
        if interaction == @ui.Interaction::Hovered {
          next_mode = widget.mode
          hover_resize_cursor = true
          break
        }
      }
    }
  }
  @window.window_set_cursor_icon(
    icon=if hover_resize_cursor {
      @window.CursorIcon::from(@window.SystemCursorIcon::EwResize)
    } else {
      @window.CursorIcon::from(@window.SystemCursorIcon::Default)
    },
  )

  if clustered_decals_state.val.drag_mode == next_mode {
    false
  } else {
    clustered_decals_state.val.drag_mode = next_mode
    true
  }
}

///|
fn process_ui_controls(world : @ecs.World) -> Unit {
  let selection_changed = handle_selection_change(world)
  let drag_mode_changed = switch_drag_mode(world)
  if selection_changed || drag_mode_changed {
    update_ui_state(world)
  }
}

///|
fn process_drag_input(world : @ecs.World) -> Unit {
  if @input.mouse_button_just_pressed(@window.MouseButton::Left) {
    clustered_decals_state.val.last_mouse = @input.mouse_position()
  }
  if @input.mouse_button_just_released(@window.MouseButton::Left) {
    clustered_decals_state.val.last_mouse = None
  }
  if !@input.mouse_button_pressed(@window.MouseButton::Left) {
    return
  }

  guard @input.mouse_position() is Some(current_mouse) else { return }
  guard clustered_decals_state.val.last_mouse is Some(previous_mouse) else {
    clustered_decals_state.val.last_mouse = Some(current_mouse)
    return
  }

  let delta = current_mouse.sub(previous_mouse)
  clustered_decals_state.val.last_mouse = Some(current_mouse)

  guard selected_entity() is Some(entity) else { return }
  if clustered_decals_state.val.selection == Selection::Camera {
    apply_camera_drag(world, entity, delta)
  } else {
    apply_decal_drag(world, entity, delta)
  }
}

///|
fn rotate_cube(world : @ecs.World) -> Unit {
  guard clustered_decals_state.val.rotating_cube is Some(cube_entity) else {
    return
  }
  guard (try! world.get_by_key(cube_entity, @transform.ecs_key_transform))
    is Some(transform) else {
    return
  }
  let rotation = transform.rotation
    .mul(@math.Quat::from_rotation_y(CUBE_ROTATION_SPEED))
    .normalize()
  try! (world.replace(
    cube_entity,
    @transform.ecs_key_transform,
    transform.with_rotation(rotation),
  )
  |> ignore)
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotate_cube))
  .add_systems(@app.Update, @app.system(process_drag_input))
  .add_system_config(@app.system(process_ui_controls).after(@ui.ui_set_focus))
  .run()
}
