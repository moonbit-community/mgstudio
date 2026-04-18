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
test "pbr/decal: clustered render-table deduplicates texture indices" {
  let render_decals = RenderClusteredDecals::default()
  let entity0 = @core.Entity::new(20, 1)
  let entity1 = @core.Entity::new(21, 1)

  let decal0 = ClusteredDecal::new()
    .with_base_color_texture(Some(@asset.Handle::new(100)))
    .with_normal_map_texture(Some(@asset.Handle::new(200)))
    .with_tag(7)
  let decal1 = ClusteredDecal::new()
    .with_base_color_texture(Some(@asset.Handle::new(100)))
    .with_emissive_texture(Some(@asset.Handle::new(300)))
    .with_tag(9)

  ignore(render_decals.insert_decal(entity0, decal0))
  ignore(render_decals.insert_decal(entity1, decal1))

  debug_inspect(render_decals.binding_index_to_textures.length(), content="3")
  debug_inspect(render_decals.get_decal_index(entity1), content="Some(1)")
}

///|
test "pbr/decal: clustered tag is clamped to non-negative" {
  let decal = ClusteredDecal::new().with_tag(-5)
  debug_inspect(decal.tag, content="0")
}

///|
test "pbr/decal: upload_decals keeps gpu buffer non-empty" {
  let render_decals = RenderClusteredDecals::default()
  let decals_buffer = DecalsBuffer::default()

  render3d_upload_decals(render_decals, decals_buffer)
  debug_inspect(decals_buffer.is_empty(), content="false")

  let entity = @core.Entity::new(99, 1)
  ignore(
    render_decals.insert_decal(
      entity,
      ClusteredDecal::new().with_base_color_texture(
        Some(@asset.Handle::new(123)),
      ),
    ),
  )
  render3d_upload_decals(render_decals, decals_buffer)
  debug_inspect(decals_buffer.decals.length(), content="1")
}

///|
test "pbr/decal: bind-group entries pad textures when partial binding is unavailable" {
  let render_decals = RenderClusteredDecals::default()
  let decals_buffer = DecalsBuffer::default()
  let entity = @core.Entity::new(42, 1)

  ignore(
    render_decals.insert_decal(
      entity,
      ClusteredDecal::new().with_base_color_texture(Some(@asset.Handle::new(7))),
    ),
  )
  render3d_upload_decals(render_decals, decals_buffer)

  guard RenderViewClusteredDecalBindGroupEntries::get(
      render_decals,
      decals_buffer,
      -1,
      partially_bound_binding_array=false,
      decals_supported=true,
    )
    is Some(entries) else {
    abort("expected clustered decal bind-group entries")
  }
  debug_inspect(entries.texture_ids.length(), content="8")
  debug_inspect(entries.sampler_texture_id, content="7")
}
