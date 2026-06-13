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
fn image_asset_usage_bits(image : Image) -> Int {
  image.texture_usage_bits()
}

///|
fn image_asset_is_srgb(image : Image) -> Bool {
  match image.view_format {
    Some(TextureFormat::Rgba8UnormSrgb) => true
    Some(TextureFormat::Bgra8UnormSrgb) => true
    _ =>
      image.format == TextureFormat::Rgba8UnormSrgb ||
      image.format == TextureFormat::Bgra8UnormSrgb
  }
}

///|
fn image_asset_sync_metadata(handle : Handle[Image], image : Image) -> Unit {
  let asset_server = asset_server_or_abort()
  asset_server.set_image_usage_bits(handle, image_asset_usage_bits(image))
  asset_server.set_image_is_srgb(handle, image_asset_is_srgb(image))
  if image.sampler is Descriptor(_) {
    asset_set_texture_sampler(handle, image.sampler)
  }
}

///|
fn[T : Asset] image_asset_try_cast(value : T) -> Image? {
  value.asset_as_image()
}

///|
fn[T] image_asset_fallback_handle(assets : Assets[T]) -> Handle[T] {
  Handle::new(assets.items.length())
}

///|
fn[T] image_asset_allocate_handle(
  assets : Assets[T],
  image : Image,
) -> Handle[T] {
  let asset_server = asset_server_or_abort()
  let nearest = asset_server.image_sampler_uses_nearest(image.sampler)
  if image.is_target_texture() {
    let id = create_render_target_with_formats(
      width=image.width,
      height=image.height,
      nearest~,
      format=@image.texture_format(image.format),
      image.view_format.map(fn(format) { @image.texture_format(format) }),
    )
    if id > 0 {
      image_asset_sync_metadata(Handle::new(id), image)
      return Handle::new(id)
    }
    return image_asset_fallback_handle(assets)
  }

  let id = image_asset_create_gpu_texture(image, nearest)
  if id > 0 {
    image_asset_sync_metadata(Handle::new(id), image)
    return Handle::new(id)
  }
  image_asset_fallback_handle(assets)
}

///|
fn image_asset_pixel_size(format : TextureFormat) -> Int {
  match format {
    TextureFormat::Rgba8Unorm => 4
    TextureFormat::Rgba8UnormSrgb => 4
    TextureFormat::Bgra8Unorm => 4
    TextureFormat::Bgra8UnormSrgb => 4
    TextureFormat::Rgba16Uint => 8
    TextureFormat::Rgba16Float => 8
    TextureFormat::Rg16Float => 4
  }
}

///|
fn image_asset_mip_dim(size : Int, level : Int) -> Int {
  let shifted = size >> level
  if shifted <= 0 {
    1
  } else {
    shifted
  }
}

///|
fn image_asset_mip_levels(
  image : Image,
  height_per_slice : Int,
  slice_count : Int,
) -> Array[Bytes] {
  let mip_count = image.mip_level_count()
  if mip_count <= 1 {
    return [image.pixels]
  }
  let pixel_size = image_asset_pixel_size(image.format)
  let levels : Array[Bytes] = []
  let mut offset = 0
  for level in 0..<mip_count {
    let width = image_asset_mip_dim(image.width, level)
    let height = image_asset_mip_dim(height_per_slice, level)
    let byte_len = width * height * slice_count * pixel_size
    let level_bytes = Bytes::makei(byte_len, i => {
      match image.pixels.get(offset + i) {
        Some(byte) => byte
        None => (0).to_byte()
      }
    })
    levels.push(level_bytes)
    offset = offset + byte_len
  }
  levels
}

///|
fn image_asset_create_gpu_texture(image : Image, nearest : Bool) -> Int {
  image_asset_create_gpu_texture_with_array_layout(image, None, nearest)
}

///|
fn image_asset_create_gpu_texture_with_array_layout(
  image : Image,
  array_layout : ImageArrayLayout?,
  nearest : Bool,
) -> Int {
  if image.is_target_texture() {
    return 0
  }
  let effective_array_layout = match image.array_layout {
    Some(layout) => Some(layout)
    None => array_layout
  }
  let (height_per_slice, slice_count) = match effective_array_layout {
    Some(layout) =>
      match @image.image_array_layout_layers(image.height, layout) {
        Some(layers) if layers > 1 => (image.height / layers, layers)
        _ => (image.height, 1)
      }
    None => (image.height, 1)
  }
  if image.texture_view_dimension == Some(ImageTextureViewDimension::Cube) &&
    slice_count == 6 &&
    height_per_slice == image.width {
    let id = asset_texture_backend_create_texture_cube_with_format(
      width=image.width,
      height=height_per_slice,
      format=@image.texture_format(image.format),
      levels=image_asset_mip_levels(image, height_per_slice, slice_count),
      nearest~,
    )
    if id > 0 {
      set_texture_pixels(id, image.pixels)
    }
    return id
  }
  let id = asset_texture_backend_create_texture_stacked_2d_with_format(
    width=image.width,
    height_per_slice~,
    slice_count~,
    format=@image.texture_format(image.format),
    levels=image_asset_mip_levels(image, height_per_slice, slice_count),
    nearest~,
    usage_bits=image_asset_usage_bits(image),
  )
  if id > 0 {
    set_texture_pixels(id, image.pixels)
  }
  id
}

///|
fn image_asset_can_update_in_place(previous : Image, next : Image) -> Bool {
  previous.width == next.width &&
  previous.height == next.height &&
  previous.format == next.format &&
  previous.view_format == next.view_format &&
  previous.kind == next.kind &&
  previous.mip_level_count() == next.mip_level_count() &&
  previous.texture_usage_bits() == next.texture_usage_bits() &&
  previous.array_layout == next.array_layout &&
  previous.texture_view_dimension == next.texture_view_dimension
}

///|
fn image_asset_replace_gpu_texture_if_needed(
  handle : Handle[Image],
  image : Image,
) -> Bool {
  let array_layout = image.array_layout
  let (height_per_slice, slice_count) = match array_layout {
    Some(layout) =>
      match @image.image_array_layout_layers(image.height, layout) {
        Some(layers) if layers > 1 => (image.height / layers, layers)
        _ => (image.height, 1)
      }
    None => (image.height, 1)
  }
  if image.texture_view_dimension == Some(ImageTextureViewDimension::Cube) &&
    slice_count == 6 &&
    height_per_slice == image.width {
    asset_texture_backend_replace_texture_cube_with_format(
      texture_id=handle.id(),
      width=image.width,
      height=height_per_slice,
      format=@image.texture_format(image.format),
      levels=image_asset_mip_levels(image, height_per_slice, slice_count),
      nearest=asset_server_or_abort().image_sampler_uses_nearest(image.sampler),
    )
  } else {
    false
  }
}

///|
fn image_asset_sync_dirty(handle : Handle[Image], image : Image) -> Unit {
  if image.is_target_texture() || handle.id() <= 0 {
    image_asset_sync_metadata(handle, image)
    return
  }
  if image_asset_replace_gpu_texture_if_needed(handle, image) {
    image_asset_sync_metadata(handle, image)
    return
  }
  image_asset_sync_metadata(handle, image)
  if asset_texture_width(handle) != image.width ||
    asset_texture_height(handle) != image.height {
    return
  }
  asset_texture_backend_write_texture_region_rgba8_mip(
    texture_id=handle.id(),
    x=0,
    y=0,
    width=image.width,
    height=image.height,
    mip_level=0,
    pixels_rgba8=image.pixels,
  )
}

///|
fn[T : Asset] image_asset_sync_on_set(
  handle : Handle[T],
  previous : T,
  value : T,
) -> Bool? {
  guard image_asset_try_cast(previous) is Some(previous_image) else {
    return None
  }
  guard image_asset_try_cast(value) is Some(next_image) else {
    return Some(false)
  }
  if !image_asset_can_update_in_place(previous_image, next_image) {
    let image_handle : Handle[Image] = Handle::new(handle.id())
    if image_asset_replace_gpu_texture_if_needed(image_handle, next_image) {
      image_asset_sync_metadata(image_handle, next_image)
      return Some(true)
    }
    return Some(false)
  }
  let image_handle : Handle[Image] = Handle::new(handle.id())
  if image_asset_replace_gpu_texture_if_needed(image_handle, next_image) {
    image_asset_sync_metadata(image_handle, next_image)
    return Some(true)
  }
  if !next_image.is_target_texture() && handle.id() > 0 {
    asset_texture_backend_write_texture_region_rgba8_mip(
      texture_id=handle.id(),
      x=0,
      y=0,
      width=next_image.width,
      height=next_image.height,
      mip_level=0,
      pixels_rgba8=next_image.pixels,
    )
  }
  image_asset_sync_metadata(image_handle, next_image)
  Some(true)
}

///|
fn[T] assets_store_insert(
  assets : Assets[T],
  handle : Handle[T],
  value : T,
  existed : Bool,
) -> Bool {
  let id = handle.id()
  if id < 0 {
    return false
  }
  while assets.items.length() <= id {
    assets.items.push(None)
  }
  assets.items[id] = Some(value)
  if existed {
    assets.events.push(AssetEvent::Modified(handle))
  } else {
    assets.alive = assets.alive + 1
    assets.events.push(AssetEvent::Added(handle))
  }
  true
}
