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
// Bevy source: `bevy/crates/bevy_camera/src/visibility/range.rs`.

///|
const VISIBILITY_RANGE_PLUGIN_NAME : String = "mgstudio.camera.visibility.range.VisibilityRangePlugin"

///|
pub struct VisibilityRangePlugin {}

///|
pub fn VisibilityRangePlugin::default() -> VisibilityRangePlugin {
  VisibilityRangePlugin::{  }
}

///|
pub fn visibility_range_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  visibility_range_plugin_with(app, VisibilityRangePlugin::default())
}

///|
pub fn visibility_range_plugin_with(
  app : @app.App[@ecs.World],
  plugin : VisibilityRangePlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app
  .init_resource(fn() { VisibleEntityRanges::default() })
  .add_post_update_system(check_visibility_ranges)
}

///|
pub impl @app.Plugin for VisibilityRangePlugin with name(_self) {
  VISIBILITY_RANGE_PLUGIN_NAME
}

///|
pub impl @app.Plugin for VisibilityRangePlugin with build(self, app) {
  visibility_range_plugin_with(app, self)
}

///|
pub struct VisibleEntityRanges {
  views : @hashmap.HashMap[Int, Int]
  entities : @hashmap.HashMap[Int, Int]
}

///|
pub fn VisibleEntityRanges::default() -> VisibleEntityRanges {
  VisibleEntityRanges::{
    views: @hashmap.HashMap::new(),
    entities: @hashmap.HashMap::new(),
  }
}

///|
pub fn VisibleEntityRanges::clear(self : VisibleEntityRanges) -> Unit {
  self.views.clear()
  self.entities.clear()
}

///|
pub fn VisibleEntityRanges::entity_is_in_range_of_view(
  self : VisibleEntityRanges,
  entity : @core.Entity,
  view : @core.Entity,
) -> Bool {
  let visibility_bitmask = match self.entities.get(entity.id) {
    Some(value) => value
    None => return false
  }
  let view_index = match self.views.get(view.id) {
    Some(value) => value
    None => return false
  }
  (visibility_bitmask & (1 << view_index)) != 0
}

///|
pub fn VisibleEntityRanges::entity_is_in_range_of_any_view(
  self : VisibleEntityRanges,
  entity : @core.Entity,
) -> Bool {
  self.entities.get(entity.id) is Some(_)
}

///|
pub fn check_visibility_ranges(world : @ecs.World) -> Unit {
  let visible_ranges_ref = (world.get_resource_ref_mut(
    ecs_key_visible_entity_ranges,
  ) catch {
    _ => None
  }).unwrap()
  let visible_ranges = visible_ranges_ref.val
  visible_ranges.clear()

  let view_positions : Array[(Int, @math.Vec3)] = []
  let view_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Comp[@transform.GlobalTransform],
      @ecs.Comp[@sprite.Camera],
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! view_query.view(fn(_, data) {
    if view_positions.length() >= 32 {
      return
    }
    let (entity, global_transform_component, _camera) = data
    let view_index = view_positions.length()
    visible_ranges.views.set(entity.id, view_index)
    let view_position = global_transform_component.value().compute_transform().translation
    view_positions.push((view_index, view_position))
  })
  if view_positions.length() == 0 {
    return
  }
  if world.component_count(@root_visibility.ecs_key_visibility_range) == 0 {
    return
  }

  let entity_query : @ecs.Query[
    (
      @core.Entity,
      @ecs.Comp[@transform.GlobalTransform],
      @ecs.Comp[@root_visibility.VisibilityRange],
      @ecs.Comp[@camera_primitives.Aabb]?,
    ),
    @ecs.All,
  ] = @ecs.query(world)
  try! entity_query.view(fn(_, data) {
    let (
      entity,
      global_transform_component,
      visibility_range_component,
      aabb_component,
    ) = data
    let global_transform = global_transform_component.value()
    let visibility_range = visibility_range_component.value()
    let model_position = if visibility_range.use_aabb() {
      match aabb_component {
        Some(aabb) => global_transform.transform_point(aabb.value().center())
        None => global_transform.compute_transform().translation
      }
    } else {
      global_transform.compute_transform().translation
    }
    let mut visibility = 0
    for index in 0..<view_positions.length() {
      let (view_index, view_position) = view_positions[index]
      if visibility_range.is_visible_at_all(
          view_position.sub(model_position).length(),
        ) {
        visibility = visibility | (1 << view_index)
      }
    }
    if visibility != 0 {
      visible_ranges.entities.set(entity.id, visibility)
    }
  })
}

///|
pub fn visibility_range_always_visible() -> @root_visibility.VisibilityRange {
  @root_visibility.VisibilityRange::always_visible()
}

///|
pub fn visibility_range_invisible() -> @root_visibility.VisibilityRange {
  @root_visibility.VisibilityRange::invisible()
}

///|
pub fn visibility_range_new(
  start_margin_min : Float,
  start_margin_max : Float,
  end_margin_min : Float,
  end_margin_max : Float,
  use_aabb : Bool,
) -> @root_visibility.VisibilityRange {
  @root_visibility.VisibilityRange::new(
    start_margin_min, start_margin_max, end_margin_min, end_margin_max, use_aabb,
  )
}

///|
pub fn visibility_range_abrupt(
  start : Float,
  end : Float,
) -> @root_visibility.VisibilityRange {
  @root_visibility.VisibilityRange::abrupt(start, end)
}

///|
pub fn visibility_range_is_visible_at_all(
  visibility_range : @root_visibility.VisibilityRange,
  camera_distance : Float,
) -> Bool {
  visibility_range.is_visible_at_all(camera_distance)
}

///|
pub fn visibility_range_is_culled(
  visibility_range : @root_visibility.VisibilityRange,
  camera_distance : Float,
) -> Bool {
  visibility_range.is_culled(camera_distance)
}

///|
pub fn visibility_range_component_key() -> @ecs.ComponentKey[
  @root_visibility.VisibilityRange,
] {
  @root_visibility.VisibilityRange::component()
}

///|
pub let ecs_key_visible_entity_ranges : @ecs.ResourceKey[VisibleEntityRanges] = @ecs.register_resource(
  debug_name="mgstudio.camera.visibility.range.visible_entity_ranges",
)

///|
pub impl @app.Resource for VisibleEntityRanges with resource() {
  ecs_key_visible_entity_ranges
}
