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
// Bevy source: `bevy/crates/bevy_render/src/view/visibility/range.rs`.

///|
pub const VISIBILITY_RANGES_STORAGE_BUFFER_COUNT : Int = 4

///|
pub const VISIBILITY_RANGE_UNIFORM_BUFFER_SIZE : Int = 64

///|
pub const RENDER_VISIBILITY_RANGE_PLUGIN_ID : String = "bevy_render::view::visibility::range::RenderVisibilityRangePlugin"

///|
pub struct RenderVisibilityRangePlugin {}

///|
pub fn RenderVisibilityRangePlugin::default() -> RenderVisibilityRangePlugin {
  RenderVisibilityRangePlugin::{  }
}

///|
pub fn render_visibility_range_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  render_visibility_range_plugin_with(
    app,
    RenderVisibilityRangePlugin::default(),
  )
}

///|
pub fn render_visibility_range_plugin_with(
  app : @app.App[@ecs.World],
  plugin : RenderVisibilityRangePlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app.init_resource(fn() { RenderVisibilityRanges::default() })
}

///|
pub impl @app.PluginReplacement for RenderVisibilityRangePlugin with replacement_id(
  _self,
) {
  RENDER_VISIBILITY_RANGE_PLUGIN_ID
}

///|
pub impl @app.PluginReplacement for RenderVisibilityRangePlugin with world_plugin(
  self,
) {
  fn(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
    render_visibility_range_plugin_with(app, self)
  }
}

///|
pub struct RenderVisibilityRanges {
  mut entity_count : Int
  mut range_count : Int
  mut buffer_dirty : Bool
}

///|
pub fn RenderVisibilityRanges::default() -> RenderVisibilityRanges {
  RenderVisibilityRanges::{
    entity_count: 0,
    range_count: 0,
    buffer_dirty: true,
  }
}

///|
pub fn RenderVisibilityRanges::clear(self : RenderVisibilityRanges) -> Unit {
  self.entity_count = 0
  self.range_count = 0
  self.buffer_dirty = true
}

///|
pub fn RenderVisibilityRanges::insert(
  self : RenderVisibilityRanges,
  _entity_id : Int,
  _visibility_range : @root_visibility.VisibilityRange,
) -> Unit {
  self.entity_count = self.entity_count + 1
  self.range_count = self.range_count + 1
  self.buffer_dirty = true
}

///|
pub fn RenderVisibilityRanges::mark_flushed(
  self : RenderVisibilityRanges,
) -> Unit {
  self.buffer_dirty = false
}

///|
pub fn RenderVisibilityRanges::entity_count(
  self : RenderVisibilityRanges,
) -> Int {
  self.entity_count
}

///|
pub fn RenderVisibilityRanges::range_count(
  self : RenderVisibilityRanges,
) -> Int {
  self.range_count
}

///|
pub fn RenderVisibilityRanges::buffer_dirty(
  self : RenderVisibilityRanges,
) -> Bool {
  self.buffer_dirty
}

///|
pub fn visibility_ranges_should_use_uniform_buffer(
  range_count : Int,
  read_only_binding_type_uniform : Bool,
) -> Bool {
  read_only_binding_type_uniform &&
  range_count <= VISIBILITY_RANGE_UNIFORM_BUFFER_SIZE
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
pub fn visibility_range_always_visible() -> @root_visibility.VisibilityRange {
  @root_visibility.VisibilityRange::always_visible()
}

///|
pub fn visibility_range_invisible() -> @root_visibility.VisibilityRange {
  @root_visibility.VisibilityRange::invisible()
}

///|
pub let ecs_key_render_visibility_ranges : @ecs.ResourceKey[
  RenderVisibilityRanges,
] = @ecs.register_resource(
  debug_name="render.view.visibility.render_visibility_ranges",
)

///|
pub impl @app.Resource for RenderVisibilityRanges with resource() {
  ecs_key_render_visibility_ranges
}
