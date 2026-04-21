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
const FOX_PATH : String = "models/animated/Fox.glb"

///|
const MASK_GROUP_HEAD : Int = 0

///|
const MASK_GROUP_LEFT_FRONT_LEG : Int = 1

///|
const MASK_GROUP_RIGHT_FRONT_LEG : Int = 2

///|
const MASK_GROUP_LEFT_HIND_LEG : Int = 3

///|
const MASK_GROUP_RIGHT_HIND_LEG : Int = 4

///|
const MASK_GROUP_TAIL : Int = 5

///|
const HALF_CONTROL_WIDTH : Float = 250.0F

///|
const FULL_CONTROL_WIDTH : Float = 506.0F

///|
fn black() -> @sprite.Color {
  @sprite.Color::srgb(0.0F, 0.0F, 0.0F)
}

///|
fn white() -> @sprite.Color {
  @sprite.Color::srgb(1.0F, 1.0F, 1.0F)
}

///|
fn light_gray() -> @sprite.Color {
  @sprite.Color::srgb(0.83F, 0.83F, 0.83F)
}

///|
pub(all) enum AnimationLabel {
  Idle
  Walk
  Run
  Off
} derive(Eq, Debug, ToJson, FromJson)

///|
fn animation_label_index(label : AnimationLabel) -> Int {
  match label {
    Idle => 0
    Walk => 1
    Run => 2
    Off => 3
  }
}

///|
fn animation_label_text(label : AnimationLabel) -> String {
  match label {
    Idle => "Idle"
    Walk => "Walk"
    Run => "Run"
    Off => "Off"
  }
}

///|
struct AnimationControl {
  group_id : Int
  label : AnimationLabel
  text_entity : @core.Entity
} derive(ToJson, FromJson)

///|
struct AnimationMaskSetup {
  graph_handle : @asset.Handle[@animation.AnimationGraph]
  included_targets : Array[@animation.AnimationTargetId]
  mut initialized : Bool
  nodes : Array[@animation.AnimationNodeIndex]
}

///|
struct AnimationMaskState {
  group_clips : Array[Int]
}

///|
struct PressedControls {
  entities : Array[@core.Entity]
}

///|
let animation_control_key : @ecs.ComponentKey[AnimationControl] = @ecs.register_component(
  debug_name="examples.animation.animation_masks.AnimationControl",
)

///|
let animation_mask_setup_key : @ecs.ResourceKey[AnimationMaskSetup] = @ecs.register_resource(
  debug_name="examples.animation.animation_masks.AnimationMaskSetup",
)

///|
let animation_mask_state_key : @ecs.ResourceKey[AnimationMaskState] = @ecs.register_resource(
  debug_name="examples.animation.animation_masks.AnimationMaskState",
)

///|
let pressed_controls_key : @ecs.ResourceKey[PressedControls] = @ecs.register_resource(
  debug_name="examples.animation.animation_masks.PressedControls",
)

///|
pub impl @ecs.Component for AnimationControl with component() {
  animation_control_key
}

///|
pub impl @app.Resource for AnimationMaskSetup with resource() {
  animation_mask_setup_key
}

///|
pub impl @app.Resource for AnimationMaskState with resource() {
  animation_mask_state_key
}

///|
pub impl @app.Resource for PressedControls with resource() {
  pressed_controls_key
}

///|
impl Default for AnimationMaskState with default() {
  AnimationMaskState::{ group_clips: [0, 0, 0, 0, 0, 0] }
}

///|
impl Default for PressedControls with default() {
  PressedControls::{ entities: [] }
}

///|
fn array_contains_entity(
  entities : Array[@core.Entity],
  entity : @core.Entity,
) -> Bool {
  for existing in entities {
    if existing == entity {
      return true
    }
  }
  false
}

///|
fn array_contains_target_id(
  targets : Array[@animation.AnimationTargetId],
  target : @animation.AnimationTargetId,
) -> Bool {
  for existing in targets {
    if existing == target {
      return true
    }
  }
  false
}

///|
fn push_unique_target_id(
  targets : Array[@animation.AnimationTargetId],
  target : @animation.AnimationTargetId,
) -> Unit {
  if !array_contains_target_id(targets, target) {
    targets.push(target)
  }
}

///|
fn split_path(path : String) -> Array[String] {
  let parts : Array[String] = []
  for item in path.split("/") {
    parts.push(item.to_string())
  }
  parts
}

///|
fn collect_chain_target_ids(
  prefix_path : String,
  suffix_path : String,
) -> Array[@animation.AnimationTargetId] {
  let prefix = split_path(prefix_path)
  let suffix = split_path(suffix_path)
  let ids : Array[@animation.AnimationTargetId] = []
  for chain_length in 0..<(suffix.length() + 1) {
    let names : Array[String] = []
    for item in prefix {
      names.push(item)
    }
    for index in 0..<chain_length {
      names.push(suffix[index])
    }
    ids.push(@animation.AnimationTargetId::from_names(names))
  }
  ids
}

///|
fn build_animation_mask_setup(
  asset_server : @asset.AssetServer,
) -> AnimationMaskSetup {
  let graph = @animation.AnimationGraph::new()
  let blend_node = graph.add_additive_blend(1.0F, graph.root())
  let nodes : Array[@animation.AnimationNodeIndex] = []
  for animation_index in 0..<3 {
    let handle = asset_server.load(
      @gltf.GltfAssetLabel::Animation(animation_index).from_asset(FOX_PATH),
    )
    let mask = if animation_index == 0 { 0U } else { 0x3FU }
    nodes.push(graph.add_clip_with_mask(handle, mask, 1.0F, blend_node))
  }

  let included_targets : Array[@animation.AnimationTargetId] = []
  let mask_group_paths : Array[(String, String)] = [
    (
      "root/_rootJoint/b_Root_00/b_Hip_01/b_Spine01_02/b_Spine02_03", "b_Neck_04/b_Head_05",
    ),
    (
      "root/_rootJoint/b_Root_00/b_Hip_01/b_Spine01_02/b_Spine02_03/b_LeftUpperArm_09",
      "b_LeftForeArm_010/b_LeftHand_011",
    ),
    (
      "root/_rootJoint/b_Root_00/b_Hip_01/b_Spine01_02/b_Spine02_03/b_RightUpperArm_06",
      "b_RightForeArm_07/b_RightHand_08",
    ),
    (
      "root/_rootJoint/b_Root_00/b_Hip_01/b_LeftLeg01_015", "b_LeftLeg02_016/b_LeftFoot01_017/b_LeftFoot02_018",
    ),
    (
      "root/_rootJoint/b_Root_00/b_Hip_01/b_RightLeg01_019", "b_RightLeg02_020/b_RightFoot01_021/b_RightFoot02_022",
    ),
    (
      "root/_rootJoint/b_Root_00/b_Hip_01/b_Tail01_012", "b_Tail02_013/b_Tail03_014",
    ),
  ]

  for group_index in 0..<mask_group_paths.length() {
    let (prefix, suffix) = mask_group_paths[group_index]
    for target_id in collect_chain_target_ids(prefix, suffix) {
      graph.add_target_to_mask_group(target_id, group_index) |> ignore
      push_unique_target_id(included_targets, target_id)
    }
  }

  AnimationMaskSetup::{
    graph_handle: @animation.animation_graph_add(graph),
    included_targets,
    initialized: false,
    nodes,
  }
}

///|
fn spawn_text(
  world : @ecs.World,
  parent : @core.Entity,
  content : String,
  font : @asset.Handle[@asset.Font],
  font_size : Float,
  color : @sprite.Color,
) -> @core.Entity {
  let entity = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(entity)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @text.Text::new(content),
        @text.TextFont::from_font_size(@text.FontSize::Px(font_size)).with_font(
          font,
        ),
        @text.TextColor::new(color),
        @ui.Node::default(),
      ),
    ),
  )
  entity
}

///|
fn spawn_animation_button(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  group_id : Int,
  label : AnimationLabel,
  first : Bool,
) -> @core.Entity {
  let button = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(button)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @ui.Button::default(),
        @ui.Interaction::None,
        @ui.BackgroundColor::new(black()),
        @ui.BorderColor::new(white()),
      ),
    ),
  )
  ignore(
    try! world
    .entity_mut(button)
    .insert_component(
      @ui.Node::default()
      .with_flex_grow(1.0F)
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center)
      .with_border(
        if first {
          @ui.UiRect::default()
        } else {
          @ui.UiRect::new(
            @ui.Val::Px(1.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
          )
        },
      ),
    ),
  )
  let text_entity = spawn_text(
    world,
    button,
    animation_label_text(label),
    font,
    14.0F,
    white(),
  )
  ignore(
    try! world
    .entity_mut(button)
    .insert_component(AnimationControl::{ group_id, label, text_entity }),
  )
  button
}

///|
fn spawn_mask_group_control(
  world : @ecs.World,
  parent : @core.Entity,
  font : @asset.Handle[@asset.Font],
  label : String,
  width : Float,
  group_id : Int,
) -> @core.Entity {
  let container = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(container)
    .insert(
      (
        @hierarchy.Parent::new(parent),
        @ui.Node::default()
        .with_width(@ui.Val::Px(width))
        .with_flex_direction(@ui.FlexDirection::Column)
        .with_align_items(@ui.AlignItems::Center)
        .with_justify_content(@ui.JustifyContent::Center)
        .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F))),
        @ui.BorderColor::new(white()),
        @ui.BackgroundColor::new(black()),
      ),
    ),
  )

  let title = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(title)
    .insert(
      (
        @hierarchy.Parent::new(container),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_justify_content(@ui.JustifyContent::Center)
        .with_align_items(@ui.AlignItems::Center),
        @ui.BackgroundColor::new(black()),
      ),
    ),
  )
  ignore(spawn_text(world, title, label, font, 14.0F, light_gray()))

  let buttons = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(buttons)
    .insert(
      (
        @hierarchy.Parent::new(container),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_flex_direction(@ui.FlexDirection::Row)
        .with_justify_content(@ui.JustifyContent::Center)
        .with_align_items(@ui.AlignItems::Center)
        .with_border(
          @ui.UiRect::new(
            @ui.Val::Px(0.0F),
            @ui.Val::Px(1.0F),
            @ui.Val::Px(0.0F),
            @ui.Val::Px(0.0F),
          ),
        ),
        @ui.BorderColor::new(white()),
      ),
    ),
  )

  ignore(spawn_animation_button(world, buttons, font, group_id, Run, true))
  ignore(spawn_animation_button(world, buttons, font, group_id, Walk, false))
  ignore(spawn_animation_button(world, buttons, font, group_id, Idle, false))
  ignore(spawn_animation_button(world, buttons, font, group_id, Off, false))
  container
}

///|
fn setup(world : @ecs.World) -> Unit {
  let asset_server = @asset.AssetServer::new()
  world.insert_resource(
    animation_mask_setup_key,
    build_animation_mask_setup(asset_server),
  )
  world.insert_resource(animation_mask_state_key, AnimationMaskState::default())
  world.insert_resource(pressed_controls_key, PressedControls::default())
  world.insert_resource(
    @pbr.ecs_key_global_ambient_light,
    @pbr.GlobalAmbientLight::new(white(), 100.0F),
  )

  ignore(
    @camera.Camera3dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::from_xyz(-15.0F, 10.0F, 20.0F).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ).spawn(world),
  )

  let point_light = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(point_light)
    .insert(
      (
        @pbr.PointLight::new(white(), 10000000.0F, 100.0F, true),
        @transform.Transform::from_xyz(-4.0F, 8.0F, 13.0F),
      ),
    ),
  )

  let ground = world.spawn_empty()
  let ground_mesh = @pbr.Mesh3d::new(
    @pbr.mesh_assets_mut_or_abort().val
    |> @pbr.add_mesh(@math.Cylinder::new(7.0F, 0.05F)),
  )
  let ground_material = @pbr.standard_material_add(
    @pbr.StandardMaterial::from_color(@sprite.Color::srgb(0.3F, 0.5F, 0.3F)),
  )
  ignore(
    try! world
    .entity_mut(ground)
    .insert(
      (
        ground_mesh,
        @pbr.MeshMaterial3d::new(ground_material),
        @transform.Transform::identity(),
      ),
    ),
  )

  ignore(
    try! world
    .entity_mut(world.spawn_empty())
    .insert(
      (
        @scene.SceneRoot::new(
          asset_server.load(@gltf.GltfAssetLabel::Scene(0).from_asset(FOX_PATH)),
        ),
        @transform.Transform::identity().with_scale(@math.Vec3::splat(0.07F)),
      ),
    ),
  )

  ignore(
    @sprite.Camera2dBundle::new(
      @sprite.Camera::default(),
      @transform.Transform::identity(),
    ).spawn(world),
  )

  let root = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(root)
    .insert(
      (
        @ui.UiRoot::default(),
        @ui.Node::default()
        .with_width(@ui.Val::Percent(100.0F))
        .with_height(@ui.Val::Percent(100.0F)),
      ),
    ),
  )

  let font = asset_server.load_font("fonts/FiraSans-Bold.ttf")
  let help = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(help)
    .insert(
      (
        @hierarchy.Parent::new(root),
        @text.Text::new(
          "Click a button to switch the active animation for each mask group",
        ),
        @text.TextFont::from_font_size(@text.FontSize::Px(18.0F)).with_font(
          font,
        ),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_top(@ui.Val::Px(12.0F)),
      ),
    ),
  )

  let panel = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(panel)
    .insert(
      (
        @hierarchy.Parent::new(root),
        @ui.Node::default()
        .with_position_type(@ui.PositionType::Absolute)
        .with_left(@ui.Val::Px(12.0F))
        .with_bottom(@ui.Val::Px(12.0F))
        .with_flex_direction(@ui.FlexDirection::Column)
        .with_row_gap(@ui.Val::Px(6.0F)),
      ),
    ),
  )

  ignore(
    spawn_mask_group_control(
      world,
      panel,
      font,
      "Head",
      FULL_CONTROL_WIDTH,
      MASK_GROUP_HEAD,
    ),
  )

  let front_row = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(front_row)
    .insert(
      (
        @hierarchy.Parent::new(panel),
        @ui.Node::default()
        .with_flex_direction(@ui.FlexDirection::Row)
        .with_column_gap(@ui.Val::Px(6.0F)),
      ),
    ),
  )
  ignore(
    spawn_mask_group_control(
      world,
      front_row,
      font,
      "Left Front Leg",
      HALF_CONTROL_WIDTH,
      MASK_GROUP_LEFT_FRONT_LEG,
    ),
  )
  ignore(
    spawn_mask_group_control(
      world,
      front_row,
      font,
      "Right Front Leg",
      HALF_CONTROL_WIDTH,
      MASK_GROUP_RIGHT_FRONT_LEG,
    ),
  )

  let hind_row = world.spawn_empty()
  ignore(
    try! world
    .entity_mut(hind_row)
    .insert(
      (
        @hierarchy.Parent::new(panel),
        @ui.Node::default()
        .with_flex_direction(@ui.FlexDirection::Row)
        .with_column_gap(@ui.Val::Px(6.0F)),
      ),
    ),
  )
  ignore(
    spawn_mask_group_control(
      world,
      hind_row,
      font,
      "Left Hind Leg",
      HALF_CONTROL_WIDTH,
      MASK_GROUP_LEFT_HIND_LEG,
    ),
  )
  ignore(
    spawn_mask_group_control(
      world,
      hind_row,
      font,
      "Right Hind Leg",
      HALF_CONTROL_WIDTH,
      MASK_GROUP_RIGHT_HIND_LEG,
    ),
  )

  ignore(
    spawn_mask_group_control(
      world,
      panel,
      font,
      "Tail",
      FULL_CONTROL_WIDTH,
      MASK_GROUP_TAIL,
    ),
  )
}

///|
fn setup_animation_graph_once_loaded(world : @ecs.World) -> Unit {
  guard (try! world.get_resource_ref_mut(animation_mask_setup_key))
    is Some(setup_ref) else {
    return
  }
  if setup_ref.val.initialized {
    return
  }

  let players : @ecs.Query[
    (@core.Entity, @ecs.Mut[@animation.AnimationPlayer]),
    @ecs.All,
  ] = @ecs.query(world)
  guard (players.single() catch { _ => None })
    is Some((player_entity, player_mut)) else {
    return
  }

  player_mut.modify(fn(value) {
    for node in setup_ref.val.nodes {
      value.play(node).repeat() |> ignore
    }
  })
  ignore(
    try! world
    .entity_mut(player_entity)
    .insert_component(
      @animation.AnimationGraphHandle::new(setup_ref.val.graph_handle),
    ),
  )

  let targets : @ecs.Query[
    (@core.Entity, @ecs.Comp[@animation.AnimationTargetId]),
    @ecs.All,
  ] = @ecs.query(world)
  let targets_to_strip : Array[@core.Entity] = []
  try! targets.view(fn(_ignored, pair) {
    let (target_entity, target_id) = pair
    if !array_contains_target_id(
        setup_ref.val.included_targets,
        target_id.value(),
      ) {
      targets_to_strip.push(target_entity)
    }
  })

  for entity in targets_to_strip {
    ignore(try! world.take(entity, @animation.AnimationTargetId::component()))
    ignore(try! world.take(entity, @animation.AnimatedBy::component()))
  }

  setup_ref.val.initialized = true
}

///|
fn apply_group_selection(
  graph : @animation.AnimationGraph,
  nodes : Array[@animation.AnimationNodeIndex],
  group_id : Int,
  label_index : Int,
) -> Unit {
  for clip_index in 0..<nodes.length() {
    let node = nodes[clip_index]
    if label_index == clip_index {
      graph.remove_node_mask_group(node, group_id) |> ignore
    } else {
      graph.add_node_mask_group(node, group_id) |> ignore
    }
  }
}

///|
fn handle_button_toggles(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(animation_mask_setup_key)) is Some(setup) else {
    return
  }
  if !setup.initialized {
    return
  }
  guard (try! world.get_resource_ref_mut(animation_mask_state_key))
    is Some(state_ref) else {
    return
  }
  guard (try! world.get_resource_ref_mut(pressed_controls_key))
    is Some(pressed_ref) else {
    return
  }
  guard @animation.animation_graph_get(setup.graph_handle) is Some(graph) else {
    return
  }

  let next_pressed : Array[@core.Entity] = []
  let mut graph_changed = false
  let controls : @ecs.Query[
    (@ecs.Comp[@ui.Interaction], @ecs.Comp[AnimationControl]),
    @ecs.All,
  ] = @ecs.query(world)
  try! controls.view(fn(entity, pair) {
    let (interaction, control) = pair
    let is_pressed = interaction.value() == @ui.Interaction::Pressed
    if is_pressed {
      next_pressed.push(entity)
    }
    if !is_pressed || array_contains_entity(pressed_ref.val.entities, entity) {
      return
    }
    let resolved = animation_label_index(control.value().label)
    state_ref.val.group_clips[control.value().group_id] = resolved
    apply_group_selection(
      graph,
      setup.nodes,
      control.value().group_id,
      resolved,
    )
    graph_changed = true
  })

  pressed_ref.val.entities.clear()
  for entity in next_pressed {
    pressed_ref.val.entities.push(entity)
  }
  if graph_changed {
    @animation.animation_graph_set(setup.graph_handle, graph) |> ignore
  }
}

///|
fn update_ui(world : @ecs.World) -> Unit {
  guard (try! world.get_resource(animation_mask_state_key)) is Some(state) else {
    return
  }
  let controls : @ecs.Query[
    (@ecs.Comp[AnimationControl], @ecs.Mut[@ui.BackgroundColor]),
    @ecs.All,
  ] = @ecs.query(world)
  try! controls.view(fn(_entity, pair) {
    let (control, background) = pair
    let enabled = state.group_clips[control.value().group_id] ==
      animation_label_index(control.value().label)
    background.set(
      @ui.BackgroundColor::new(if enabled { white() } else { black() }),
    )
    let text_entity_mut = try! world.entity_mut(control.value().text_entity)
    guard (try! text_entity_mut.get_mut(key=@text.TextColor::component()))
      is Some(text_color) else {
      return
    }
    text_color.set(
      @text.TextColor::new(if enabled { black() } else { white() }),
    )
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.DefaultPlugins::default())
  .add_systems(@app.Startup, @app.system(setup))
  .add_systems(@app.Update, @app.system(setup_animation_graph_once_loaded))
  .add_systems(@app.Update, @app.system(handle_button_toggles))
  .add_systems(@app.Update, @app.system(update_ui))
  .run()
}
