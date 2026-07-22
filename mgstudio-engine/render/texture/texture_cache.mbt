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
// Bevy source: `bevy/crates/bevy_render/src/texture/texture_cache.rs`.

///|
pub struct TextureCacheDescriptor {
  label : String?
  width : Int
  height : Int
  depth_or_array_layers : Int
  mip_level_count : Int
  sample_count : Int
  dimension_raw : UInt
  format_raw : UInt
  usage_bits : UInt64
}

///|
pub(all) struct CachedTextureMeta {
  texture : @render_resource.Texture
  default_view : @render_resource.TextureView
  mut taken : Bool
  mut frames_since_last_use : Int
}

///|
pub struct CachedTexture {
  texture : @render_resource.Texture
  default_view : @render_resource.TextureView
}

///|
pub(all) struct TextureCacheEntry {
  descriptor : TextureCacheDescriptor
  textures : Array[CachedTextureMeta]
}

///|
pub struct TextureCache {
  textures : Array[TextureCacheEntry]
}

///|
pub fn TextureCacheDescriptor::new(
  label? : String? = None,
  width~ : Int,
  height~ : Int,
  depth_or_array_layers? : Int = 1,
  mip_level_count? : Int = 1,
  sample_count? : Int = 1,
  dimension_raw? : UInt = @wgpu.TEXTURE_DIMENSION_2D,
  format_raw~ : UInt,
  usage_bits~ : UInt64,
) -> TextureCacheDescriptor {
  {
    label,
    width: texture_cache_positive(width),
    height: texture_cache_positive(height),
    depth_or_array_layers: texture_cache_positive(depth_or_array_layers),
    mip_level_count: texture_cache_positive(mip_level_count),
    sample_count: texture_cache_positive(sample_count),
    dimension_raw,
    format_raw,
    usage_bits,
  }
}

///|
fn texture_cache_positive(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
fn texture_cache_descriptor_equal(
  lhs : TextureCacheDescriptor,
  rhs : TextureCacheDescriptor,
) -> Bool {
  lhs.label == rhs.label &&
  lhs.width == rhs.width &&
  lhs.height == rhs.height &&
  lhs.depth_or_array_layers == rhs.depth_or_array_layers &&
  lhs.mip_level_count == rhs.mip_level_count &&
  lhs.sample_count == rhs.sample_count &&
  lhs.dimension_raw == rhs.dimension_raw &&
  lhs.format_raw == rhs.format_raw &&
  lhs.usage_bits == rhs.usage_bits
}

///|
pub fn TextureCacheDescriptor::label(self : TextureCacheDescriptor) -> String? {
  self.label
}

///|
pub fn TextureCacheDescriptor::width(self : TextureCacheDescriptor) -> Int {
  self.width
}

///|
pub fn TextureCacheDescriptor::height(self : TextureCacheDescriptor) -> Int {
  self.height
}

///|
pub fn TextureCacheDescriptor::depth_or_array_layers(
  self : TextureCacheDescriptor,
) -> Int {
  self.depth_or_array_layers
}

///|
pub fn TextureCacheDescriptor::mip_level_count(
  self : TextureCacheDescriptor,
) -> Int {
  self.mip_level_count
}

///|
pub fn TextureCacheDescriptor::sample_count(
  self : TextureCacheDescriptor,
) -> Int {
  self.sample_count
}

///|
pub fn TextureCacheDescriptor::dimension_raw(
  self : TextureCacheDescriptor,
) -> UInt {
  self.dimension_raw
}

///|
pub fn TextureCacheDescriptor::format_raw(
  self : TextureCacheDescriptor,
) -> UInt {
  self.format_raw
}

///|
pub fn TextureCacheDescriptor::usage_bits(
  self : TextureCacheDescriptor,
) -> UInt64 {
  self.usage_bits
}

///|
pub fn CachedTexture::texture(self : CachedTexture) -> @render_resource.Texture {
  self.texture
}

///|
pub fn CachedTexture::default_view(
  self : CachedTexture,
) -> @render_resource.TextureView {
  self.default_view
}

///|
pub fn CachedTexture::texture_id(
  self : CachedTexture,
) -> @render_resource.TextureId {
  self.texture.id()
}

///|
pub fn CachedTexture::default_view_id(
  self : CachedTexture,
) -> @render_resource.TextureViewId {
  self.default_view.id()
}

///|
pub fn TextureCache::new() -> TextureCache {
  { textures: [] }
}

///|
pub let texture_cache_resource_key : @ecs.ResourceKey[TextureCache] = @ecs.register_resource(
  debug_name="mgstudio_render::TextureCache",
)

///|
pub impl @app.Resource for TextureCache with fn resource() {
  texture_cache_resource_key
}

///|
fn TextureCache::entry_index(
  self : TextureCache,
  descriptor : TextureCacheDescriptor,
) -> Int {
  for index, entry in self.textures {
    if texture_cache_descriptor_equal(entry.descriptor, descriptor) {
      return index
    }
  }
  -1
}

///|
fn texture_cache_create_texture(
  render_device : @renderer.RenderDevice,
  descriptor : TextureCacheDescriptor,
) -> CachedTextureMeta {
  let device = render_device.wgpu_device()
  let texture = device.create_texture_u32(
    descriptor.width().reinterpret_as_uint(),
    descriptor.height().reinterpret_as_uint(),
    descriptor.depth_or_array_layers().reinterpret_as_uint(),
    @wgpu.TextureUsage::from_u64(descriptor.usage_bits()),
    @wgpu.TextureDimension::from_u32(descriptor.dimension_raw()),
    @wgpu.TextureFormat::from_u32(descriptor.format_raw()),
    mip_level_count=descriptor.mip_level_count().reinterpret_as_uint(),
    sample_count=descriptor.sample_count().reinterpret_as_uint(),
  )
  if descriptor.label() is Some(label) {
    texture.set_label(label)
  }
  let default_view = texture.create_view()
  {
    texture: @render_resource.Texture::from_wgpu(texture),
    default_view: @render_resource.TextureView::from_wgpu(default_view),
    taken: true,
    frames_since_last_use: 0,
  }
}

///|
fn cached_texture_from_meta(meta : CachedTextureMeta) -> CachedTexture {
  { texture: meta.texture, default_view: meta.default_view }
}

///|
pub fn TextureCache::get(
  self : TextureCache,
  render_device : @renderer.RenderDevice,
  descriptor : TextureCacheDescriptor,
) -> CachedTexture {
  let entry_index = self.entry_index(descriptor)
  if entry_index >= 0 {
    let entry = self.textures[entry_index]
    for texture in entry.textures {
      if !texture.taken {
        texture.frames_since_last_use = 0
        texture.taken = true
        return cached_texture_from_meta(texture)
      }
    }
    let created = texture_cache_create_texture(render_device, descriptor)
    entry.textures.push(created)
    return cached_texture_from_meta(created)
  }
  let created = texture_cache_create_texture(render_device, descriptor)
  self.textures.push({ descriptor, textures: [created] })
  cached_texture_from_meta(created)
}

///|
pub fn TextureCache::is_empty(self : TextureCache) -> Bool {
  self.textures.is_empty()
}

///|
pub fn TextureCache::len(self : TextureCache) -> Int {
  let mut count = 0
  for entry in self.textures {
    count += entry.textures.length()
  }
  count
}

///|
pub fn TextureCache::descriptor_count(self : TextureCache) -> Int {
  self.textures.length()
}

///|
pub fn TextureCache::taken_count(self : TextureCache) -> Int {
  let mut count = 0
  for entry in self.textures {
    for texture in entry.textures {
      if texture.taken {
        count += 1
      }
    }
  }
  count
}

///|
pub fn TextureCache::update(self : TextureCache) -> Unit {
  let retained_entries : Array[TextureCacheEntry] = []
  for entry in self.textures {
    let retained_textures : Array[CachedTextureMeta] = []
    for texture in entry.textures {
      texture.frames_since_last_use += 1
      texture.taken = false
      if texture.frames_since_last_use < 3 {
        retained_textures.push(texture)
      }
    }
    if !retained_textures.is_empty() {
      retained_entries.push({
        descriptor: entry.descriptor,
        textures: retained_textures,
      })
    }
  }
  self.textures.clear()
  for entry in retained_entries {
    self.textures.push(entry)
  }
}

///|
pub fn update_texture_cache_system(world : @ecs.World) -> Unit {
  match world.get_resource(TextureCache::resource()) {
    Some(texture_cache) => texture_cache.update()
    None => ()
  }
}
