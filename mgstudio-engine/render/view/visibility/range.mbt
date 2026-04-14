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
const RENDER_VISIBILITY_RANGE_PLUGIN_NAME : String = "mgstudio.render.view.visibility.range.RenderVisibilityRangePlugin"

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
  @render.with_render_app(app, fn(sub_app : @app.SubApp[@ecs.World]) {
    let world = sub_app.world()
    ensure_render_visibility_ranges_resource(world)
    sub_app
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(extract_visibility_ranges_system).in_set(
        @render.render_system_set_extract_commands,
      ),
    )
    .add_systems(
      @render.render_schedule_stage(),
      @app.system(write_render_visibility_ranges_system).in_set(
        @render.render_system_set_prepare_resources_flush,
      ),
    )
  })
}

///|
pub impl @app.PluginReplacement for RenderVisibilityRangePlugin with plugin_name(
  _self,
) {
  RENDER_VISIBILITY_RANGE_PLUGIN_NAME
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
pub(all) struct RenderVisibilityEntityInfo {
  buffer_index : Int
  is_abrupt : Bool
}

///|
pub struct RenderVisibilityRanges {
  entities : @hashmap.HashMap[Int, RenderVisibilityEntityInfo]
  range_to_index : @hashmap.HashMap[String, Int]
  buffer : Array[@math.Vec4]
  mut entity_count : Int
  mut range_count : Int
  mut buffer_dirty : Bool
}

///|
pub fn RenderVisibilityRanges::default() -> RenderVisibilityRanges {
  RenderVisibilityRanges::{
    entities: @hashmap.HashMap::new(),
    range_to_index: @hashmap.HashMap::new(),
    buffer: [],
    entity_count: 0,
    range_count: 0,
    buffer_dirty: true,
  }
}

///|
pub fn RenderVisibilityRanges::clear(self : RenderVisibilityRanges) -> Unit {
  self.entities.clear()
  self.range_to_index.clear()
  self.buffer.clear()
  self.entity_count = 0
  self.range_count = 0
  self.buffer_dirty = true
}

///|
fn visibility_range_key(
  visibility_range : @root_visibility.VisibilityRange,
) -> String {
  let use_aabb = if visibility_range.use_aabb() { "1" } else { "0" }
  "\{visibility_range.start_margin_min()}|\{visibility_range.start_margin_max()}|\{visibility_range.end_margin_min()}|\{visibility_range.end_margin_max()}|\{use_aabb}"
}

///|
pub fn RenderVisibilityRanges::insert(
  self : RenderVisibilityRanges,
  entity_id : Int,
  visibility_range : @root_visibility.VisibilityRange,
) -> Unit {
  if self.entities.get(entity_id) is None {
    self.entity_count = self.entity_count + 1
  }
  let range_key = visibility_range_key(visibility_range)
  let buffer_index = match self.range_to_index.get(range_key) {
    Some(index) => index
    None => {
      let next_index = self.buffer.length()
      self.buffer.push(
        @math.Vec4::new(
          visibility_range.start_margin_min(),
          visibility_range.start_margin_max(),
          visibility_range.end_margin_min(),
          visibility_range.end_margin_max(),
        ),
      )
      self.range_to_index.set(range_key, next_index)
      self.range_count = self.range_count + 1
      next_index
    }
  }
  self.entities.set(entity_id, RenderVisibilityEntityInfo::{
    buffer_index,
    is_abrupt: visibility_range.is_abrupt(),
  })
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
pub fn RenderVisibilityRanges::lod_index_for_entity(
  self : RenderVisibilityRanges,
  entity_id : Int,
) -> Int? {
  self.entities.get(entity_id).map(fn(info) { info.buffer_index })
}

///|
pub fn RenderVisibilityRanges::entity_has_crossfading_visibility_ranges(
  self : RenderVisibilityRanges,
  entity_id : Int,
) -> Bool {
  match self.entities.get(entity_id) {
    Some(info) => !info.is_abrupt
    None => false
  }
}

///|
pub fn RenderVisibilityRanges::buffer(
  self : RenderVisibilityRanges,
) -> Array[@math.Vec4] {
  self.buffer
}

///|
fn ensure_render_visibility_ranges_resource(world : @ecs.World) -> Unit {
  if (world.get_resource(ecs_key_render_visibility_ranges) catch { _ => None })
    is None {
    world.insert_resource(
      ecs_key_render_visibility_ranges,
      RenderVisibilityRanges::default(),
    )
  }
}

///|
fn extract_visibility_ranges_system(render_world : @ecs.World) -> Unit {
  ensure_render_visibility_ranges_resource(render_world)
  let main_world = @render.render_source_world(render_world)
  let system_sequence = @app.current_system_sequence()
  let changed_ranges = main_world.changed_components(
    @root_visibility.ecs_key_visibility_range, system_sequence,
  )
  let removed_ranges = main_world.removed_components(
    @root_visibility.ecs_key_visibility_range, system_sequence,
  )
  let ranges_ref = (render_world.get_resource_ref_mut(
    ecs_key_render_visibility_ranges,
  ) catch {
    _ => None
  }).unwrap()
  let ranges = ranges_ref.val
  if changed_ranges.is_empty() && removed_ranges.is_empty() {
    return
  }
  let query : @ecs.QueryState[
    @core.Entity,
    @ecs.With[@root_visibility.VisibilityRange],
  ] = main_world.query_filtered(
    @ecs.With::new(@root_visibility.ecs_key_visibility_range),
  )
  let iter = query.iter(main_world)
  ranges.clear()
  while (iter.fetch_next() catch { _ => None }) is Some((entity, _)) {
    if (main_world.get_by_key(entity, @root_visibility.ecs_key_visibility_range) catch {
        _ => None
      })
      is Some(visibility_range) {
      ranges.insert(entity.id, visibility_range)
    }
  }
}

///|
fn render_visibility_ranges_write(
  ranges : RenderVisibilityRanges,
  read_only_binding_type_uniform : Bool,
) -> Unit {
  if !ranges.buffer_dirty() {
    return
  }
  if visibility_ranges_should_use_uniform_buffer(
      ranges.range_count(),
      read_only_binding_type_uniform,
    ) {
    while ranges.buffer.length() > VISIBILITY_RANGE_UNIFORM_BUFFER_SIZE {
      ranges.buffer.pop() |> ignore
    }
    while ranges.buffer.length() < VISIBILITY_RANGE_UNIFORM_BUFFER_SIZE {
      ranges.buffer.push(@math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F))
    }
  } else if ranges.buffer.is_empty() {
    ranges.buffer.push(@math.Vec4::new(0.0F, 0.0F, 0.0F, 0.0F))
  }
  ranges.mark_flushed()
}

///|
fn write_render_visibility_ranges_system(render_world : @ecs.World) -> Unit {
  if (render_world.get_resource_ref_mut(ecs_key_render_visibility_ranges) catch {
      _ => None
    })
    is Some(ranges_ref) {
    render_visibility_ranges_write(
      ranges_ref.val,
      @render.host_gpu_read_only_binding_type_uniform(
        VISIBILITY_RANGES_STORAGE_BUFFER_COUNT,
      ),
    )
  }
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
