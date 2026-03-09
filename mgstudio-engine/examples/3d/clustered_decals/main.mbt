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
/// Port of `bevy/examples/3d/clustered_decals.rs`.
///
/// Baseline parity:
/// - This example now attaches `ClusteredDecal` components directly with Bevy-
///   aligned texture/tag data.
/// - Clustered projected decal rendering and custom decal-extension shader
///   execution are not yet active in this backend.
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
} derive(Eq, Show)

///|
pub(all) enum DragMode {
  Move
  Scale
  Roll
} derive(Eq, Show)

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
  mut help_text : @text.TextHandle?
  mut drag_mode_panel : @core.Entity?
  selection_widgets : Array[SelectionWidget]
  drag_mode_widgets : Array[DragModeWidget]
  mut last_mouse : @math.Vec2?
}

///|
let clustered_decals_state : Ref[ClusteredDecalsState] = Ref::new({
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
  "Click and drag to " +
  drag_mode_text(clustered_decals_state.val.drag_mode) +
  " " +
  selection_text(clustered_decals_state.val.selection)
}

///|
fn update_help_text() -> Unit {
  if clustered_decals_state.val.help_text is Some(handle) {
    @text.text_set_content(handle, create_help_text())
  }
}

///|
fn button_background(selected : Bool) -> @ui.BackgroundColor {
  @ui.BackgroundColor::new(
    if selected {
      @render2d.Color::white()
    } else {
      @render2d.Color::black()
    },
  )
}

///|
fn button_border(selected : Bool) -> @ui.BorderColor {
  @ui.BorderColor::new(
    if selected {
      @render2d.Color::black()
    } else {
      @render2d.Color::white()
    },
  )
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
fn same_entity(a : @core.Entity, b : @core.Entity) -> Bool {
  a.id == b.id && a.generation == b.generation
}

///|
fn spawn_button(
  world : @ecs.World,
  parent : @core.Entity,
  tick : @core.Tick,
  font : @asset.Handle[@asset.Font],
  label : String,
) -> @core.Entity {
  let button = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(button, @hierarchy.Parent::new(parent), tick)
  world
  .component(@ui.ecs_key_button)
  .insert(button, @ui.Button::default(), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    button,
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
    .with_align_items(@ui.AlignItems::Center),
    tick,
  )
  world
  .component(@ui.ecs_key_border_radius)
  .insert(
    button,
    @ui.BorderRadius::all(@ui.Val::Px(BUTTON_BORDER_RADIUS)),
    tick,
  )
  world
  .component(@ui.ecs_key_background_color)
  .insert(button, button_background(false), tick)
  world
  .component(@ui.ecs_key_border_color)
  .insert(button, button_border(false), tick)

  let label_handle = spawn_ui_text_handle(
    label,
    font,
    16.0F,
    @render2d.Color::white(),
  )
  let text_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(text_entity, @hierarchy.Parent::new(button), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    text_entity,
    @ui.Node::default().with_width(@ui.Val::Auto).with_height(@ui.Val::Auto),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(text_entity, @ui.UiText::new(label_handle), tick)

  button
}

///|
fn setup_ui(world : @ecs.World, font : @asset.Handle[@asset.Font]) -> Unit {
  let tick = world.read_change_tick()

  @render2d.Camera2dBundle::new(
    @render2d.Camera::default().with_order(100).with_clear_color_none(),
    @math.Transform::identity(),
  ).spawn(world)
  |> ignore

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

  let help_handle = spawn_ui_text_handle(
    "",
    font,
    16.0F,
    @render2d.Color::white(),
  )
  let help_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(help_entity, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    help_entity,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(12.0F))
    .with_top(@ui.Val::Px(12.0F)),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(help_entity, @ui.UiText::new(help_handle), tick)
  clustered_decals_state.val.help_text = Some(help_handle)

  let selection_panel = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(selection_panel, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    selection_panel,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_left(@ui.Val::Px(10.0F))
    .with_bottom(@ui.Val::Px(10.0F))
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_row_gap(@ui.Val::Px(6.0F))
    .with_align_items(@ui.AlignItems::Center),
    tick,
  )

  let hint_handle = spawn_ui_text_handle(
    "Drag to Move",
    font,
    16.0F,
    @render2d.Color::white(),
  )
  let hint_entity = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(hint_entity, @hierarchy.Parent::new(selection_panel), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    hint_entity,
    @ui.Node::default()
    .with_width(@ui.Val::Px(125.0F))
    .with_height(@ui.Val::Auto),
    tick,
  )
  world
  .component(@ui.ecs_key_ui_text)
  .insert(hint_entity, @ui.UiText::new(hint_handle), tick)

  let camera_button = spawn_button(world, selection_panel, tick, font, "Camera")
  clustered_decals_state.val.selection_widgets.push({
    button: camera_button,
    selection: Selection::Camera,
  })

  let decal_a_button = spawn_button(
    world, selection_panel, tick, font, "Decal A",
  )
  clustered_decals_state.val.selection_widgets.push({
    button: decal_a_button,
    selection: Selection::DecalA,
  })

  let decal_b_button = spawn_button(
    world, selection_panel, tick, font, "Decal B",
  )
  clustered_decals_state.val.selection_widgets.push({
    button: decal_b_button,
    selection: Selection::DecalB,
  })

  let drag_mode_panel = world.spawn_empty()
  world
  .component(@hierarchy.ecs_key_parent)
  .insert(drag_mode_panel, @hierarchy.Parent::new(root), tick)
  world
  .component(@ui.ecs_key_node)
  .insert(
    drag_mode_panel,
    @ui.Node::default()
    .with_position_type(@ui.PositionType::Absolute)
    .with_right(@ui.Val::Px(10.0F))
    .with_bottom(@ui.Val::Px(10.0F))
    .with_flex_direction(@ui.FlexDirection::Row)
    .with_row_gap(@ui.Val::Px(6.0F)),
    tick,
  )
  clustered_decals_state.val.drag_mode_panel = Some(drag_mode_panel)

  let scale_button = spawn_button(world, drag_mode_panel, tick, font, "Scale")
  clustered_decals_state.val.drag_mode_widgets.push({
    button: scale_button,
    mode: DragMode::Scale,
  })

  let roll_button = spawn_button(world, drag_mode_panel, tick, font, "Roll")
  clustered_decals_state.val.drag_mode_widgets.push({
    button: roll_button,
    mode: DragMode::Roll,
  })
}

///|
fn update_ui_state(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
  let background_store = world.component(@ui.ecs_key_background_color)
  let border_store = world.component(@ui.ecs_key_border_color)

  for widget in clustered_decals_state.val.selection_widgets {
    let selected = widget.selection == clustered_decals_state.val.selection
    if background_store.contains(widget.button) {
      background_store.set(widget.button, button_background(selected), tick)
      |> ignore
    } else {
      background_store.insert(widget.button, button_background(selected), tick)
    }
    if border_store.contains(widget.button) {
      border_store.set(widget.button, button_border(selected), tick) |> ignore
    } else {
      border_store.insert(widget.button, button_border(selected), tick)
    }
  }

  for widget in clustered_decals_state.val.drag_mode_widgets {
    let selected = clustered_decals_state.val.drag_mode == widget.mode
    if background_store.contains(widget.button) {
      background_store.set(widget.button, button_background(selected), tick)
      |> ignore
    } else {
      background_store.insert(widget.button, button_background(selected), tick)
    }
    if border_store.contains(widget.button) {
      border_store.set(widget.button, button_border(selected), tick) |> ignore
    } else {
      border_store.insert(widget.button, button_border(selected), tick)
    }
  }

  if clustered_decals_state.val.drag_mode_panel is Some(panel) {
    let node_store = world.component(@ui.ecs_key_node)
    if node_store.get(panel) is Some(node) {
      let show_drag_buttons = clustered_decals_state.val.selection !=
        Selection::Camera
      node_store.set(
        panel,
        node.with_display(
          if show_drag_buttons {
            @ui.Display::Flex
          } else {
            @ui.Display::None
          },
        ),
        tick,
      )
      |> ignore
    }
  }

  update_help_text()
}

///|
fn calculate_initial_decal_transform(
  position : @math.Vec3,
  target : @math.Vec3,
  size : @math.Vec2,
) -> @math.Transform {
  let direction = target.sub(position)
  let center = position.add(direction.mul_scalar(0.5F))
  @math.Transform::from_xyz(center.x, center.y, center.z)
  .with_scale(@math.Vec3::new(size.x * 0.5F, size.y * 0.5F, direction.length()))
  .looking_at(target, @math.Vec3::new(0.0F, 1.0F, 0.0F))
}

///|
fn setup(world : @ecs.World) -> Unit {
  let tick = world.read_change_tick()
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

  let cube_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.75F, 0.75F, 0.75F, 1.0F),
    ),
  )
  let cube = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(3.0F, 3.0F, 3.0F),
    @render3d.MeshMaterial3d::new(cube_material),
    @math.Transform::from_xyz(0.0F, 0.0F, 0.0F).with_rotation(
      @math.Quat::from_rotation_y(1.0471975512F),
    ),
  ).spawn(world)
  clustered_decals_state.val.rotating_cube = Some(cube)

  let camera = @render3d.Camera3dBundle::new(
    @render2d.Camera::default(),
    @math.Transform::from_xyz(0.0F, 2.5F, 9.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
  ).spawn(world)
  clustered_decals_state.val.camera = Some(camera)

  let light = world.spawn_empty()
  world
  .component(@render3d.ecs_key_directional_light)
  .insert(light, @render3d.DirectionalLight::default(), tick)
  world
  .component(@math.ecs_key_transform)
  .insert(
    light,
    @math.Transform::from_xyz(4.0F, 8.0F, 4.0F).looking_at(
      @math.Vec3::zero(),
      @math.Vec3::new(0.0F, 1.0F, 0.0F),
    ),
    tick,
  )

  let decal_texture = asset_server.load("branding/icon.png")
  let decal_a_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(1.0F, 0.27F, 0.0F, 0.80F),
    )
    .with_base_color_texture(Some(decal_texture))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )
  let decal_b_material = @render3d.standard_material_add(
    @render3d.StandardMaterial::from_color(
      @render2d.Color::new(0.0F, 1.0F, 0.0F, 0.80F),
    )
    .with_base_color_texture(Some(decal_texture))
    .with_alpha_mode(@render3d.AlphaMode3d::Blend)
    .with_unlit(true),
  )

  let decal_a = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(decal_a_material),
    calculate_initial_decal_transform(
      @math.Vec3::new(1.0F, 3.0F, 5.0F),
      @math.Vec3::zero(),
      @math.Vec2::new(1.1F, 1.1F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_clustered_decal)
  .insert(
    decal_a,
    @render3d.ClusteredDecal::default()
    .with_base_color_texture(Some(decal_texture))
    .with_tag(1),
    tick,
  )
  clustered_decals_state.val.decal_a = Some(decal_a)

  let decal_b = @render3d.MeshMaterial3dBundle::new(
    @render3d.Mesh3d::from_cuboid(1.0F, 1.0F, 1.0F),
    @render3d.MeshMaterial3d::new(decal_b_material),
    calculate_initial_decal_transform(
      @math.Vec3::new(-2.0F, -1.0F, 4.0F),
      @math.Vec3::zero(),
      @math.Vec2::new(2.0F, 2.0F),
    ),
  ).spawn(world)
  world
  .component(@render3d.ecs_key_clustered_decal)
  .insert(
    decal_b,
    @render3d.ClusteredDecal::default()
    .with_base_color_texture(Some(decal_texture))
    .with_tag(2),
    tick,
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
  transform : @math.Transform,
  translation : @math.Vec3,
) -> @math.Transform {
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
  let tick = world.read_change_tick()
  guard world.component(@math.ecs_key_transform).get(entity) is Some(transform) else {
    return
  }
  let next_translation = spherical_drag_translation(
    transform.translation,
    delta,
    phi_factor,
    theta_factor,
  )
  world
  .component(@math.ecs_key_transform)
  .set(
    entity,
    orient_towards_center_preserve_roll(transform, next_translation),
    tick,
  )
  |> ignore
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
  let tick = world.read_change_tick()
  guard world.component(@math.ecs_key_transform).get(entity) is Some(transform) else {
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
      world
      .component(@math.ecs_key_transform)
      .set(
        entity,
        transform.with_scale(transform.scale.mul_scalar(scale_factor)),
        tick,
      )
      |> ignore
    }
    DragMode::Roll => {
      let rotation = transform.rotation
        .mul(@math.Quat::from_rotation_z(delta.x * ROLL_SPEED))
        .normalize()
      world
      .component(@math.ecs_key_transform)
      .set(entity, transform.with_rotation(rotation), tick)
      |> ignore
    }
  }
}

///|
fn handle_selection_change(world : @ecs.World) -> Bool {
  let mut changed = false
  let system_ticks = world.get_system_context().ticks()
  let interaction_store = world.component(@ui.ecs_key_interaction)
  interaction_store.for_each_changed(system_ticks, fn(entity, interaction) {
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
    let interaction_store = world.component(@ui.ecs_key_interaction)
    for widget in clustered_decals_state.val.drag_mode_widgets {
      if interaction_store.get(widget.button) is Some(interaction) {
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
  guard world.component(@math.ecs_key_transform).get(cube_entity)
    is Some(transform) else {
    return
  }
  let tick = world.read_change_tick()
  let rotation = transform.rotation
    .mul(@math.Quat::from_rotation_y(CUBE_ROTATION_SPEED))
    .normalize()
  world
  .component(@math.ecs_key_transform)
  .set(cube_entity, transform.with_rotation(rotation), tick)
  |> ignore
}

///|
fn main {
  let plugins : Array[@app.Plugin[@ecs.World]] = @mgstudio.default_plugins()
  @app.App::new(@ecs.World::new())
  .add_plugins(plugins)
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(rotate_cube))
  .add_systems(@app.Update, @app.system(process_drag_input))
  .add_system_config(@app.system(process_ui_controls).after(@ui.ui_set_focus))
  .run()
}
