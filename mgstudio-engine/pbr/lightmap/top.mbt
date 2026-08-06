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
// Bevy source: `bevy/crates/bevy_pbr/src/lightmap/mod.rs`.

///|
const LIGHTMAP_PLUGIN_NAME : String = "mgstudio.pbr.lightmap.LightmapPlugin"

///|
pub const LIGHTMAPS_PER_SLAB : Int = 4

///|
pub struct LightmapPlugin {}

///|
#warnings("-unnecessary_annotation")
pub fn lightmap_plugin() -> LightmapPlugin {
  LightmapPlugin::{  }
}

///|
pub impl @app.Plugin for LightmapPlugin with fn name(_self) {
  LIGHTMAP_PLUGIN_NAME
}

///|
pub impl @app.Plugin for LightmapPlugin with fn build(self, app) {
  register_embedded_wgsl_sources()
  lightmap_plugin_install_with(app, self)
}

///|
pub struct LightmapPluginState {
  bindless_supported : Bool
  lightmaps_per_slab : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn LightmapPluginState::LightmapPluginState() -> LightmapPluginState {
  { bindless_supported: false, lightmaps_per_slab: LIGHTMAPS_PER_SLAB }
}

///|
pub fn lightmap_plugin_state(bindless_supported : Bool) -> LightmapPluginState {
  { bindless_supported, lightmaps_per_slab: LIGHTMAPS_PER_SLAB }
}

///|
/// Per-mesh lightmap settings aligned with Bevy's `Lightmap`.
pub struct Lightmap {
  image : @asset.Handle[@asset.Image]
  uv_rect : @math.Rect
  bicubic_sampling : Bool
} derive(ToJson, FromJson)

///|
pub fn Lightmap::Lightmap() -> Lightmap {
  {
    image: @asset.Handle::new(-1),
    uv_rect: @math.Rect::new(@math.Vec2::zero(), @math.Vec2::new(1.0F, 1.0F)),
    bicubic_sampling: false,
  }
}

///|
pub fn Lightmap::new(image : @asset.Handle[@asset.Image]) -> Lightmap {
  { ..Lightmap(), image, }
}

///|
pub fn Lightmap::with_uv_rect(
  self : Lightmap,
  uv_rect : @math.Rect,
) -> Lightmap {
  { ..self, uv_rect, }
}

///|
pub fn Lightmap::with_bicubic_sampling(
  self : Lightmap,
  bicubic_sampling : Bool,
) -> Lightmap {
  { ..self, bicubic_sampling, }
}

///|
pub struct LightmapSlabIndex {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
pub struct LightmapSlotIndex {
  value : Int
} derive(Eq, Debug, ToJson, FromJson)

///|
fn non_negative(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
pub fn LightmapSlabIndex::new(value : Int) -> LightmapSlabIndex {
  { value: non_negative(value) }
}

///|
pub fn LightmapSlotIndex::new(value : Int) -> LightmapSlotIndex {
  { value: non_negative(value) }
}

///|
pub fn LightmapSlabIndex::to_int(self : LightmapSlabIndex) -> Int {
  self.value
}

///|
pub fn LightmapSlotIndex::to_int(self : LightmapSlotIndex) -> Int {
  self.value
}

///|
pub struct RenderLightmap {
  uv_rect : @math.Rect
  slab_index : LightmapSlabIndex
  slot_index : LightmapSlotIndex
  bicubic_sampling : Bool
} derive(ToJson, FromJson)

///|
pub fn RenderLightmap::new(
  uv_rect : @math.Rect,
  slab_index : LightmapSlabIndex,
  slot_index : LightmapSlotIndex,
  bicubic_sampling : Bool,
) -> RenderLightmap {
  { uv_rect, slab_index, slot_index, bicubic_sampling }
}

///|
pub fn RenderLightmap::bicubic_sampling(self : RenderLightmap) -> Bool {
  self.bicubic_sampling
}

///|
pub struct LightmapSlab {
  capacity : Int
  allocated : Int
  lightmap_texture_ids : Array[Int]
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn LightmapSlab::new(bindless_supported : Bool) -> LightmapSlab {
  let capacity = if bindless_supported { LIGHTMAPS_PER_SLAB } else { 1 }
  let lightmap_texture_ids : Array[Int] = []
  for _ in 0..<capacity {
    lightmap_texture_ids.push(-1)
  }
  { capacity, allocated: 0, lightmap_texture_ids }
}

///|
pub fn LightmapSlab::is_full(self : LightmapSlab) -> Bool {
  self.allocated >= self.capacity
}

///|
pub fn LightmapSlab::available_slots(self : LightmapSlab) -> Int {
  let free = self.capacity - self.allocated
  if free < 0 {
    0
  } else {
    free
  }
}

///|
pub struct RenderLightmaps {
  render_lightmaps : Map[Int, RenderLightmap]
  slabs : Array[LightmapSlab]
  mut bindless_supported : Bool
  // Change-detection cursor for `extract_lightmaps_system` over the main
  // world, following the `RenderMaterialInstances` idiom.
  mut last_source_change_tick : @core.Tick
}

///|
pub fn RenderLightmaps::RenderLightmaps() -> RenderLightmaps {
  {
    render_lightmaps: Map([]),
    slabs: [LightmapSlab::new(false)],
    bindless_supported: false,
    last_source_change_tick: 0,
  }
}

///|
fn lightmap_clamp_slab_index(slabs : Array[LightmapSlab], index : Int) -> Int {
  if index < 0 {
    0
  } else if index >= slabs.length() {
    slabs.length() - 1
  } else {
    index
  }
}

///|
fn render_lightmaps_allocate_slot(
  render_lightmaps : RenderLightmaps,
  lightmap_texture_id : Int,
) -> (LightmapSlabIndex, LightmapSlotIndex) {
  for index in 0..<render_lightmaps.slabs.length() {
    let slab = render_lightmaps.slabs[index]
    if !slab.is_full() {
      let slot = slab.allocated
      let texture_ids = slab.lightmap_texture_ids
      if slot >= 0 && slot < texture_ids.length() {
        texture_ids[slot] = lightmap_texture_id
      }
      render_lightmaps.slabs[index] = {
        ..slab,
        allocated: slab.allocated + 1,
        lightmap_texture_ids: texture_ids,
      }
      return (LightmapSlabIndex::new(index), LightmapSlotIndex::new(slot))
    }
  }
  render_lightmaps.slabs.push(
    LightmapSlab::new(render_lightmaps.bindless_supported),
  )
  let new_index = render_lightmaps.slabs.length() - 1
  let slab = render_lightmaps.slabs[new_index]
  let slot = slab.allocated
  let texture_ids = slab.lightmap_texture_ids
  if slot >= 0 && slot < texture_ids.length() {
    texture_ids[slot] = lightmap_texture_id
  }
  render_lightmaps.slabs[new_index] = {
    ..slab,
    allocated: slab.allocated + 1,
    lightmap_texture_ids: texture_ids,
  }
  (LightmapSlabIndex::new(new_index), LightmapSlotIndex::new(slot))
}

///|
pub fn RenderLightmaps::clear(self : RenderLightmaps) -> Unit {
  self.render_lightmaps.clear()
  self.slabs.clear()
  self.slabs.push(LightmapSlab::new(self.bindless_supported))
}

///|
pub fn RenderLightmaps::set_bindless_supported(
  self : RenderLightmaps,
  bindless_supported : Bool,
) -> Unit {
  self.bindless_supported = bindless_supported
}

///|
pub fn RenderLightmaps::insert_lightmap(
  self : RenderLightmaps,
  entity : @core.Entity,
  lightmap : Lightmap,
) -> RenderLightmap {
  match self.render_lightmaps.get(entity.id) {
    Some(existing) => return existing
    None => ()
  }
  let (slab_index, slot_index) = render_lightmaps_allocate_slot(
    self,
    lightmap.image.id(),
  )
  let render_lightmap = RenderLightmap::new(
    lightmap.uv_rect,
    slab_index,
    slot_index,
    lightmap.bicubic_sampling,
  )
  self.render_lightmaps.set(entity.id, render_lightmap)
  render_lightmap
}

///|
pub fn RenderLightmaps::get(
  self : RenderLightmaps,
  entity : @core.Entity,
) -> RenderLightmap? {
  self.render_lightmaps.get(entity.id)
}

///|
pub fn RenderLightmaps::remove(
  self : RenderLightmaps,
  entity : @core.Entity,
) -> RenderLightmap? {
  let removed = self.render_lightmaps.get(entity.id)
  self.render_lightmaps.remove(entity.id)
  match removed {
    Some(lightmap) => {
      if self.slabs.length() > 0 {
        let slab_raw_index = lightmap.slab_index.to_int()
        let slab_index = lightmap_clamp_slab_index(self.slabs, slab_raw_index)
        let slab = self.slabs[slab_index]
        let slot_index = lightmap.slot_index.to_int()
        let texture_ids = slab.lightmap_texture_ids
        if slot_index >= 0 && slot_index < texture_ids.length() {
          texture_ids[slot_index] = -1
        }
        self.slabs[slab_index] = {
          ..slab,
          allocated: if slab.allocated <= 0 {
            0
          } else {
            slab.allocated - 1
          },
          lightmap_texture_ids: texture_ids,
        }
      }
      Some(lightmap)
    }
    None => None
  }
}

///|
pub fn RenderLightmaps::entity_count(self : RenderLightmaps) -> Int {
  self.render_lightmaps.length()
}

///|
pub fn RenderLightmaps::slab_texture_ids(
  self : RenderLightmaps,
  slab_index : LightmapSlabIndex,
) -> Array[Int] {
  let texture_ids : Array[Int] = []
  let raw_index = slab_index.to_int()
  if raw_index < 0 || raw_index >= self.slabs.length() {
    return texture_ids
  }
  for id in self.slabs[raw_index].lightmap_texture_ids {
    texture_ids.push(id)
  }
  texture_ids
}

///|
/// Bevy source: `bevy/crates/bevy_pbr/src/lightmap/mod.rs::extract_lightmaps`.
///
/// Change-driven population of the persistent `RenderLightmaps` table during
/// the extract stage: entities whose `ViewVisibility` or `Lightmap` changed
/// allocate a slab slot when visible, and removed `Lightmap` components free
/// theirs. Specialization, queueing, and the draw payload all read the result
/// later in the render schedule, so the table must be complete before the
/// render schedule runs (ISS-488: the previous draw-time allocation left the
/// table empty at specialization time and the `LIGHTMAP` define never
/// activated).
pub fn extract_lightmaps_system(render_world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(render_world)
  guard render_world.get_resource_mut(ecs_key_render_lightmaps)
    is Some(render_lightmaps_ref) else {
    return
  }
  render_lightmaps_ref.modify(fn(render_lightmaps) {
    let system_ticks = @core.SystemTicks::new(
      render_lightmaps.last_source_change_tick,
      source_world.read_change_tick(),
    )
    // `Or<(Changed<ViewVisibility>, Changed<Lightmap>)>`
    let changed : Array[@core.Entity] = []
    let seen : Map[UInt64, Bool] = Map([])
    for
      entity in source_world
      .changed_components(@visibility.ecs_key_view_visibility, system_ticks)
      .read() {
      if !seen.contains(entity.to_bits()) {
        seen.set(entity.to_bits(), true)
        changed.push(entity)
      }
    }
    for
      entity in source_world
      .changed_components(ecs_key_lightmap, system_ticks)
      .read() {
      if !seen.contains(entity.to_bits()) {
        seen.set(entity.to_bits(), true)
        changed.push(entity)
      }
    }
    for entity in changed {
      guard source_world.is_alive(entity) else { continue }
      guard (try! source_world.get_by_key(entity, ecs_key_lightmap))
        is Some(lightmap) else {
        continue
      }
      guard (try! source_world.get_by_key(
          entity, @visibility.ecs_key_view_visibility,
        ))
        is Some(view_visibility) else {
        continue
      }
      // Only process visible entities; already-allocated entries are kept
      // (`insert_lightmap` returns the existing allocation).
      if !view_visibility.get() {
        continue
      }
      if lightmap.image.id() < 0 {
        continue
      }
      ignore(render_lightmaps.insert_lightmap(entity, lightmap))
    }
    for
      entity in source_world
      .removed_components(ecs_key_lightmap, system_ticks)
      .read() {
      ignore(render_lightmaps.remove(entity))
    }
    render_lightmaps.last_source_change_tick = system_ticks.this_run
  })
}

///|
pub let ecs_key_lightmap : @ecs.ComponentKey[Lightmap] = @ecs.register_component(
  debug_name="render3d.lightmap",
)

///|
pub impl @ecs.Component for Lightmap with fn component() {
  ecs_key_lightmap
}

///|
pub let ecs_key_render_lightmaps : @ecs.ResourceKey[RenderLightmaps] = @ecs.register_resource(
  debug_name="render3d.render_lightmaps",
)

///|
let ecs_key_lightmap_plugin_state : @ecs.ResourceKey[LightmapPluginState] = @ecs.register_resource(
  debug_name="mgstudio_pbr::LightmapPluginState",
)

///|
pub impl @app.Resource for LightmapPluginState with fn resource() {
  ecs_key_lightmap_plugin_state
}

///|
pub impl @app.Resource for RenderLightmaps with fn resource() {
  ecs_key_render_lightmaps
}

///|
#warnings("-unnecessary_annotation")
pub fn lightmap_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  lightmap_plugin_install_with(app, LightmapPlugin::{  })
}

///|
pub fn lightmap_plugin_install_with(
  app : @app.App[@ecs.World],
  plugin : LightmapPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  let mut next = @render.with_render_app(app, fn(render_app) {
    let render_world = render_app.world()
    if render_world.get_resource(ecs_key_render_lightmaps) is None {
      render_world.insert_resource(ecs_key_render_lightmaps, RenderLightmaps())
    }
    // Bevy registers `extract_lightmaps` in `ExtractSchedule` (after mesh
    // extraction); every mgstudio consumer reads `RenderLightmaps` in the
    // render schedule, which runs after the whole extract stage.
    render_app.add_systems(
      @render.render_extract_schedule_stage(),
      @app.system(extract_lightmaps_system).named(
        "mgstudio.pbr.lightmap.extract_lightmaps",
      ),
    )
  })
  if !next.contains_resource(ecs_key_lightmap_plugin_state) {
    next = next.insert_world_resource(
      ecs_key_lightmap_plugin_state,
      LightmapPluginState(),
    )
  }
  next
}
