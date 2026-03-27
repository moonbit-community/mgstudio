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
const TREE_DEPTH : Int = 6

///|
const BRANCH_WIDTH : Int = 4

///|
const MAX_VISIBLE_NODES : Int = 900

///|
struct NodeMotion {
  depth : Int
  phase : Float
  speed : Float
}

///|
let node_motion_key : @ecs.ComponentKey[NodeMotion] = @ecs.register_component(
  debug_name="examples.stress_tests.transform_hierarchy.NodeMotion",
)

///|
pub impl @ecs.Component for NodeMotion with component() {
  node_motion_key
}

///|
struct HierarchyStats {
  mut nodes : Int
  mut print_timer : Float
}

///|
let hierarchy_stats_key : @ecs.ResourceKey[HierarchyStats] = @ecs.register_resource(
  debug_name="examples.stress_tests.transform_hierarchy.HierarchyStats",
)

///|
impl @app.Resource for HierarchyStats with resource() {
  hierarchy_stats_key
}

///|
fn HierarchyStats::default() -> HierarchyStats {
  { nodes: 0, print_timer: 0.0F }
}

///|
fn float_from_int(value : Int) -> Float {
  Float::from_double(value.to_double())
}

///|
fn spawn_tree(
  commands : @app.Commands,
  texture : @asset.Handle[@asset.Image],
  stats : @app.ResMut[HierarchyStats],
) -> Unit {
  let root = commands.spawn(
    (
      @transform.Transform::from_xyz(0.0F, 0.0F, 0.0F),
      NodeMotion::{ depth: 0, phase: 0.0F, speed: 0.6F },
      @sprite.Sprite::from_image(texture).with_custom_size(
        Some(@math.Vec2::new(12.0F, 12.0F)),
      ),
    ),
  )

  let stats_ref = stats.get_ref()
  stats_ref.val.nodes += 1
  let mut visible_count = 1
  let mut parents = [root]
  for depth in 1..<(TREE_DEPTH + 1) {
    let radius = 18.0F + float_from_int(depth) * 8.0F
    let next_level = [root]
    next_level.clear()
    for parent_index in 0..<parents.length() {
      let parent = parents[parent_index]
      for branch in 0..<BRANCH_WIDTH {
        let denom = float_from_int(BRANCH_WIDTH * max_int(parents.length(), 1))
        let numerator = float_from_int(parent_index * BRANCH_WIDTH + branch)
        let angle = numerator / denom * 6.283185307179586F
        let child = commands.spawn(
          (
            @hierarchy.Parent::new(parent),
            @transform.Transform::from_xyz(
              @math.cos(angle) * radius,
              @math.sin(angle) * radius,
              0.0F,
            ),
            NodeMotion::{
              depth,
              phase: angle,
              speed: 0.4F + float_from_int((depth + branch) % 7) * 0.1F,
            },
          ),
        )
        if visible_count < MAX_VISIBLE_NODES {
          commands
          .entity(child)
          .insert_component(
            @sprite.Sprite::sized(@math.Vec2::new(6.0F, 6.0F)).with_color(
              @sprite.Color::hsl(
                float_from_int((depth * 43 + branch * 17) % 360),
                0.8F,
                0.58F,
              ),
            ),
          )
          visible_count += 1
        }
        stats_ref.val.nodes += 1
        if depth < TREE_DEPTH {
          next_level.push(child)
        }
      }
    }
    parents = next_level
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn setup(
  commands : @app.Commands,
  asset_server : @app.Res[@asset.AssetServer],
  stats : @app.ResMut[HierarchyStats],
) -> Unit {
  ignore(commands.spawn_component(@sprite.Camera2d::default()))
  let icon = asset_server.get().load("branding/icon.png")
  spawn_tree(commands, icon, stats)
}

///|
fn update_transforms(
  time : @app.Res[@time.Time[Unit]],
  nodes : @ecs.Query[
    (@ecs.Comp[NodeMotion], @ecs.Mut[@transform.Transform]),
    @ecs.All,
  ],
) -> Unit {
  let t = time.get().elapsed_secs()
  try! nodes.for_each(fn(_entity, data) {
    let (motion, transform) = data
    let motion_value = motion.value()
    let transform_ref = transform.get_ref()
    let depth_f = float_from_int(motion_value.depth)
    let radius = 8.0F + depth_f * 2.4F
    let angle = motion_value.phase + t * motion_value.speed
    transform_ref.val.translation.x = @math.cos(angle) * radius
    transform_ref.val.translation.y = @math.sin(angle) * radius
    transform_ref.val.rotation = @math.Quat::from_rotation_z(angle * 0.25F)
  })
}

///|
fn print_stats(
  time : @app.Res[@time.Time[Unit]],
  stats : @app.ResMut[HierarchyStats],
) -> Unit {
  let stats_ref = stats.get_ref()
  stats_ref.val.print_timer += time.get().delta_secs()
  if stats_ref.val.print_timer < 1.0F {
    return
  }
  stats_ref.val.print_timer -= 1.0F
  println("Hierarchy nodes: \{stats_ref.val.nodes}")
}

///|
fn main {
  @app.App::new(@ecs.World::new())
  .insert_resource(HierarchyStats::default())
  .insert_resource(@winit.WinitSettings::continuous())
  .add_plugins(
    [
      ..@mgstudio.default_plugins(),
      @diagnostic.frame_time_diagnostics_plugin,
      @diagnostic.log_diagnostics_plugin,
    ],
  )
  .add_systems(@app.Startup, @app.system(@app.system_param3(setup)))
  .add_systems(@app.Update, @app.system(@app.system_param2(update_transforms)))
  .add_systems(@app.Update, @app.system(@app.system_param2(print_stats)))
  .run()
}
