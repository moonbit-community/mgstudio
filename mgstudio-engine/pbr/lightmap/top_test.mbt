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
test "pbr/lightmap: render-lightmaps allocates and removes entries" {
  let render_lightmaps = @lightmap.RenderLightmaps::RenderLightmaps()
  let entity0 = @core.Entity::new(10, 1)
  let entity1 = @core.Entity::new(11, 1)

  let render_lightmap0 = render_lightmaps.insert_lightmap(
    entity0,
    Lightmap::new(@asset.Handle::new(7)).with_bicubic_sampling(true),
  )
  let render_lightmap1 = render_lightmaps.insert_lightmap(
    entity1,
    Lightmap::Lightmap(),
  )

  debug_inspect(render_lightmaps.entity_count(), content="2")
  debug_inspect(render_lightmap0.slab_index.to_int(), content="0")
  debug_inspect(render_lightmap0.slot_index.to_int(), content="0")
  debug_inspect(render_lightmap1.slab_index.to_int(), content="1")
  debug_inspect(render_lightmap1.slot_index.to_int(), content="0")
  debug_inspect(
    render_lightmaps.slab_texture_ids(render_lightmap0.slab_index).length(),
    content="1",
  )
  debug_inspect(
    render_lightmaps.slab_texture_ids(render_lightmap0.slab_index)[0],
    content="7",
  )

  ignore(render_lightmaps.remove(entity0))
  debug_inspect(render_lightmaps.entity_count(), content="1")
  debug_inspect(render_lightmaps.get(entity0) is None, content="true")
  debug_inspect(
    render_lightmaps.slab_texture_ids(render_lightmap0.slab_index)[0],
    content="-1",
  )
}

///|
test "pbr/lightmap: bindless slabs expose four texture slots" {
  let render_lightmaps = @lightmap.RenderLightmaps::RenderLightmaps()
  render_lightmaps.set_bindless_supported(true)
  render_lightmaps.clear()
  let render_lightmap0 = render_lightmaps.insert_lightmap(
    @core.Entity::new(20, 1),
    Lightmap::new(@asset.Handle::new(7)),
  )
  let render_lightmap1 = render_lightmaps.insert_lightmap(
    @core.Entity::new(21, 1),
    Lightmap::new(@asset.Handle::new(8)),
  )
  let texture_ids = render_lightmaps.slab_texture_ids(
    render_lightmap0.slab_index,
  )
  debug_inspect(render_lightmap1.slab_index.to_int(), content="0")
  debug_inspect(render_lightmap1.slot_index.to_int(), content="1")
  debug_inspect(texture_ids.length(), content="4")
  debug_inspect(texture_ids[0], content="7")
  debug_inspect(texture_ids[1], content="8")
  debug_inspect(texture_ids[2], content="-1")
}

///|
test "pbr/lightmap: plugin state keeps bevy-shaped defaults" {
  let state = @lightmap.LightmapPluginState::LightmapPluginState()
  debug_inspect(state.lightmaps_per_slab, content="4")
  debug_inspect(state.bindless_supported, content="false")
}
