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
const ANIMATION_GRAPH_PATH : String = "animation_graphs/Fox.animgraph.ron"

///|
fn clip_node_indices() -> Array[Int] {
  [2, 3, 4]
}

///|
const NODE_WIDTH : Float = 112.0F

///|
const NODE_HEIGHT : Float = 56.0F

///|
const HELP_TEXT : String = "Click and drag inside a clip node to change its weight"

///|
struct ExampleAnimationGraph {
  clip_nodes : Array[@animation.AnimationNodeIndex]
  graph_handle : @asset.Handle[@animation.AnimationGraph]
}

///|
let example_animation_graph_key : @ecs.ResourceKey[ExampleAnimationGraph] = @ecs.register_resource(
  debug_name="examples.animation.animation_graph.ExampleAnimationGraph",
)

///|
pub impl @app.Resource for ExampleAnimationGraph with resource() {
  example_animation_graph_key
}

///|
struct ExampleAnimationWeights {
  weights : Array[Float]
}

///|
let example_animation_weights_key : @ecs.ComponentKey[ExampleAnimationWeights] = @ecs.register_component(
  debug_name="examples.animation.animation_graph.ExampleAnimationWeights",
)

///|
pub impl @ecs.Component for ExampleAnimationWeights with component() {
  example_animation_weights_key
}

///|
pub impl Default for ExampleAnimationWeights with default() {
  { weights: [1.0F, 1.0F, 1.0F] }
}

///|
struct ClipNode {
  index : Int
}

///|
let clip_node_key : @ecs.ComponentKey[ClipNode] = @ecs.register_component(
  debug_name="examples.animation.animation_graph.ClipNode",
)

///|
pub impl @ecs.Component for ClipNode with component() {
  clip_node_key
}

///|
struct ClipNodeFill {
  index : Int
}

///|
let clip_node_fill_key : @ecs.ComponentKey[ClipNodeFill] = @ecs.register_component(
  debug_name="examples.animation.animation_graph.ClipNodeFill",
)

///|
pub impl @ecs.Component for ClipNodeFill with component() {
  clip_node_fill_key
}

///|
struct ClipNodeLabel {
  index : Int
  text : String
}

///|
let clip_node_label_key : @ecs.ComponentKey[ClipNodeLabel] = @ecs.register_component(
  debug_name="examples.animation.animation_graph.ClipNodeLabel",
)

///|
pub impl @ecs.Component for ClipNodeLabel with component() {
  clip_node_label_key
}

///|
struct NodeRect {
  bottom : Float
  left : Float
}

///|
fn clip_title(index : Int) -> String {
  match index {
    0 => "Idle"
    1 => "Walk"
    _ => "Run"
  }
}

///|
fn clip_node_rect(index : Int) -> NodeRect {
  match index {
    0 => { left: 24.0F, bottom: 260.0F }
    1 => { left: 24.0F, bottom: 172.0F }
    _ => { left: 24.0F, bottom: 84.0F }
  }
}

///|
fn spawn_line(
  commands : @app.Commands,
  root : @core.Entity,
  left : Float,
  bottom : Float,
  width : Float,
  height : Float,
) -> Unit {
  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(left))
      .with_bottom(@ui.Val::Px(bottom))
      .with_width(@ui.Val::Px(width))
      .with_height(@ui.Val::Px(height)),
      @ui.BackgroundColor::new(@sprite.Color::white()),
    ),
  )
  |> ignore
}

///|
fn spawn_clip_node(
  commands : @app.Commands,
  root : @core.Entity,
  font : @asset.Handle[@asset.Font],
  index : Int,
) -> Unit {
  let rect = clip_node_rect(index)
  let label = clip_title(index)
  let container = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Button::default(),
      @ui.Interaction::None,
      @ui.RelativeCursorPosition::default(),
      ClipNode::{ index, },
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(rect.left))
      .with_bottom(@ui.Val::Px(rect.bottom))
      .with_width(@ui.Val::Px(NODE_WIDTH))
      .with_height(@ui.Val::Px(NODE_HEIGHT))
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BorderColor::new(@sprite.Color::white()),
    ),
  )
  let fill = commands.spawn(
    (
      @hierarchy.Parent::new(container),
      ClipNodeFill::{ index, },
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(0.0F))
      .with_bottom(@ui.Val::Px(0.0F))
      .with_width(@ui.Val::Px(NODE_WIDTH))
      .with_height(@ui.Val::Px(NODE_HEIGHT)),
      @ui.BackgroundColor::new(@sprite.Color::srgb(0.0F, 0.39F, 0.0F)),
    ),
  )
  let text_entity = commands.spawn(
    (
      @hierarchy.Parent::new(container),
      ClipNodeLabel::{ index, text: label },
      @text.Text::new(label),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(16.0F)),
      @text.TextColor::new(@sprite.Color::srgb(0.98F, 0.92F, 0.84F)),
      @text.TextLayout::new_with_justify(@text.Justify::Center),
      @ui.Node::default(),
    ),
  )
  ignore(fill)
  ignore(text_entity)
}

///|
fn spawn_blend_node(
  commands : @app.Commands,
  root : @core.Entity,
  font : @asset.Handle[@asset.Font],
  left : Float,
  bottom : Float,
  label : String,
) -> Unit {
  let node = commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_left(@ui.Val::Px(left))
      .with_bottom(@ui.Val::Px(bottom))
      .with_width(@ui.Val::Px(NODE_WIDTH))
      .with_height(@ui.Val::Px(NODE_HEIGHT))
      .with_border(@ui.UiRect::all(@ui.Val::Px(1.0F)))
      .with_justify_content(@ui.JustifyContent::Center)
      .with_align_items(@ui.AlignItems::Center),
      @ui.BorderColor::new(@sprite.Color::white()),
    ),
  )
  let text_entity = commands.spawn(
    (
      @hierarchy.Parent::new(node),
      @text.Text::new(label),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(16.0F)),
      @text.TextColor::new(@sprite.Color::srgb(0.98F, 0.92F, 0.84F)),
      @text.TextLayout::new_with_justify(@text.Justify::Center),
      @ui.Node::default(),
    ),
  )
  ignore(node)
  ignore(text_entity)
}

///|
fn setup_assets(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
) -> Unit {
  let server = asset_server.get()
  let graph_handle : @asset.Handle[@animation.AnimationGraph] = server.load(
    ANIMATION_GRAPH_PATH,
  )
  let clip_nodes : Array[@animation.AnimationNodeIndex] = []
  for node_index in clip_node_indices() {
    clip_nodes.push(@animation.AnimationNodeIndex::new(node_index))
  }
  commands.insert_resource(ExampleAnimationGraph::{
    clip_nodes,
    graph_handle,
  })
}

///|
fn setup_scene(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  meshes : @app.ResMut[@asset.Assets[@mesh.Mesh]],
  materials : @app.ResMut[@asset.Assets[@pbr.StandardMaterial]],
) -> Unit {
  let server = asset_server.get()
  let mesh_assets = meshes.get_ref().val
  let material_assets = materials.get_ref().val

  commands.spawn(
    (
      @pbr.Camera3d::default(),
      @transform.Transform::from_xyz(-10.0F, 5.0F, 13.0F).looking_at(
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
        @math.Vec3::new(0.0F, 1.0F, 0.0F),
      ),
    ),
  )
  |> ignore
  commands.spawn((@sprite.Camera2d::default(), @sprite.Camera::default()))
  |> ignore
  commands.spawn(
    (
      @pbr.PointLight::default()
      .with_intensity(10_000_000.0F)
      .with_shadow_maps_enabled(true),
      @transform.Transform::from_xyz(-4.0F, 8.0F, 13.0F),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @scene.SceneRoot::new(
        server.load(@gltf.GltfAssetLabel::Scene(0).from_asset(FOX_PATH)),
      ),
      @transform.Transform::identity().with_scale(@math.Vec3::splat(0.07F)),
    ),
  )
  |> ignore
  commands.spawn(
    (
      @pbr.Mesh3d::new(
        mesh_assets |> @pbr.add_mesh(@math.Cuboid::new(14.0F, 0.1F, 14.0F)),
      ),
      @pbr.MeshMaterial3d::new(
        material_assets
        |> @pbr.add_material(@sprite.Color::srgb(0.3F, 0.5F, 0.3F)),
      ),
      @transform.Transform::from_xyz(0.0F, -0.05F, 0.0F),
    ),
  )
  |> ignore
}

///|
fn setup_ui(
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

  commands.spawn(
    (
      @hierarchy.Parent::new(root),
      @text.Text::new(HELP_TEXT),
      @text.TextFont::default()
      .with_font(font)
      .with_font_size(@text.FontSize::Px(16.0F)),
      @text.TextColor::new(@sprite.Color::white()),
      @ui.Node::default()
      .with_position_type(@ui.PositionType::Absolute)
      .with_top(@ui.Val::Px(12.0F))
      .with_left(@ui.Val::Px(12.0F)),
    ),
  )
  |> ignore

  spawn_line(commands, root, 136.0F, 288.0F, 88.0F, 1.0F)
  spawn_line(commands, root, 136.0F, 200.0F, 88.0F, 1.0F)
  spawn_line(commands, root, 136.0F, 112.0F, 88.0F, 1.0F)
  spawn_line(commands, root, 224.0F, 156.0F, 1.0F, 132.0F)
  spawn_line(commands, root, 224.0F, 156.0F, 88.0F, 1.0F)
  spawn_line(commands, root, 312.0F, 156.0F, 1.0F, 88.0F)

  spawn_blend_node(commands, root, font, 268.0F, 216.0F, "Root".to_string())
  spawn_blend_node(
    commands,
    root,
    font,
    180.0F,
    128.0F,
    "Blend\n0.5".to_string(),
  )
  for index in 0..<3 {
    spawn_clip_node(commands, root, font, index)
  }
}

///|
fn init_animations(
  commands : @app.Commands,
  players : @ecs.Query[
    (@core.Entity, @ecs.Mut[@animation.AnimationPlayer]),
    @ecs.All,
  ],
  animation_graph : @app.Res[ExampleAnimationGraph],
  initialized : @app.Local[Bool],
) -> Unit {
  if initialized.get() {
    return
  }
  let clip_nodes = animation_graph.get().clip_nodes
  try! players.view(fn(_entity, data) {
    let (entity, player_mut) = data
    let player_ref = player_mut.get_ref()
    commands
    .entity(entity)
    .insert(
      (
        @animation.AnimationGraphHandle::new(animation_graph.get().graph_handle),
        ExampleAnimationWeights::default(),
      ),
    )
    for node in clip_nodes {
      player_ref.val.play(node).repeat() |> ignore
    }
    initialized.set(true)
  })
}

///|
fn handle_weight_drag(
  controls : @ecs.Query[
    (
      @ecs.Comp[@ui.Interaction],
      @ecs.Comp[@ui.RelativeCursorPosition],
      @ecs.Comp[ClipNode],
    ),
    @ecs.All,
  ],
  weights_query : @ecs.Query[@ecs.Mut[ExampleAnimationWeights], @ecs.All],
) -> Unit {
  guard (weights_query.single() catch { _ => None }) is Some(weights_mut) else {
    return
  }
  let weights_ref = weights_mut.get_ref()
  try! controls.view(fn(_entity, data) {
    let (interaction, relative_cursor_position, clip_node) = data
    if interaction.value() != @ui.Interaction::Pressed {
      return
    }
    guard relative_cursor_position.value().normalized is Some(normalized) else {
      return
    }
    let weight = normalized.x.clamp(min=0.0F, max=1.0F)
    weights_ref.val.weights[clip_node.value().index] = weight
  })
}

///|
fn update_ui(
  weights_query : @ecs.Query[@ecs.Comp[ExampleAnimationWeights], @ecs.All],
  labels : @ecs.Query[
    (@ecs.Comp[ClipNodeLabel], @ecs.Mut[@text.Text]),
    @ecs.All,
  ],
  fills : @ecs.Query[(@ecs.Comp[ClipNodeFill], @ecs.Mut[@ui.Node]), @ecs.All],
) -> Unit {
  guard (weights_query.single() catch { _ => None }) is Some(weights_comp) else {
    return
  }
  let weights = weights_comp.value().weights
  try! labels.view(fn(_entity, data) {
    let (label, text) = data
    let clip = label.value()
    let content = "\{clip.text}\n\{weights[clip.index].to_string()}"
    text.set(@text.Text::new(content))
  })
  try! fills.view(fn(_entity, data) {
    let (fill, node) = data
    let current = node.value()
    node.set(@ui.Node::{
      ..current,
      width: @ui.Val::Px(NODE_WIDTH * weights[fill.value().index]),
    })
  })
}

///|
fn sync_weights(
  players : @ecs.Query[
    (@ecs.Mut[@animation.AnimationPlayer], @ecs.Comp[ExampleAnimationWeights]),
    @ecs.All,
  ],
  animation_graph : @app.Res[ExampleAnimationGraph],
) -> Unit {
  let clip_nodes = animation_graph.get().clip_nodes
  try! players.view(fn(_entity, data) {
    let (player_mut, weights_comp) = data
    let player_ref = player_mut.get_ref()
    let weights = weights_comp.value().weights
    for index in 0..<clip_nodes.length() {
      let node = clip_nodes[index]
      if !player_ref.val.is_playing_animation(node) {
        player_ref.val.play(node).repeat() |> ignore
      }
      if player_ref.val.animation_mut(node) is Some(animation_entry) {
        animation_entry.set_weight(weights[index]) |> ignore
      }
    }
  })
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .add_plugins(@mgstudio.default_plugins())
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup_assets)))
  .add_systems(@app.Startup, @app.system(@app.system_param4(setup_scene)))
  .add_systems(@app.Startup, @app.system(@app.system_param2(setup_ui)))
  .add_systems(@app.Update, @app.system(@app.system_param4(init_animations)))
  .add_systems(@app.Update, @app.system(@app.system_param2(handle_weight_drag)))
  .add_systems(@app.Update, @app.system(@app.system_param3(update_ui)))
  .add_systems(@app.Update, @app.system(@app.system_param2(sync_weights)))
  .run()
}
