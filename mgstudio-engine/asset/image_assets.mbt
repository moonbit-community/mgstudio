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
  if image.is_target_texture() {
    IMAGE_USAGE_TEXTURE_BINDING |
    IMAGE_USAGE_COPY_DST |
    IMAGE_USAGE_RENDER_ATTACHMENT
  } else {
    IMAGE_USAGE_TEXTURE_BINDING | IMAGE_USAGE_COPY_DST | IMAGE_USAGE_COPY_SRC
  }
}

///|
fn image_asset_is_srgb(image : Image) -> Bool {
  match image.view_format {
    Some(TextureFormat::Rgba8UnormSrgb) => true
    _ => image.format == TextureFormat::Rgba8UnormSrgb
  }
}

///|
fn image_asset_sync_metadata(handle : Handle[Image], image : Image) -> Unit {
  let asset_server = asset_server_or_abort()
  asset_server.set_image_usage_bits(handle, image_asset_usage_bits(image))
  asset_server.set_image_is_srgb(handle, image_asset_is_srgb(image))
}

///|
fn[T] image_asset_try_cast(value : T) -> Image? {
  @any.of(value).try_to()
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
  let nearest = asset_server_or_abort().default_sampler_nearest.val
  if image.is_target_texture() {
    let id = create_render_target_with_formats(
      width=image.width,
      height=image.height,
      nearest~,
      format_raw=@image.texture_format_raw(image.format),
      image.view_format.map(fn(format) { @image.texture_format_raw(format) }),
    )
    if id > 0 {
      return Handle::new(id)
    }
    return image_asset_fallback_handle(assets)
  }

  let id = create_dynamic_texture(
    width=image.width,
    height=image.height,
    nearest~,
  )
  if id > 0 {
    update_texture_region_mip_bytes(
      texture_id=id,
      x=0,
      y=0,
      width=image.width,
      height=image.height,
      mip_level=0,
      bytes=image.pixels,
    )
    return Handle::new(id)
  }
  image_asset_fallback_handle(assets)
}

///|
fn image_asset_can_update_in_place(previous : Image, next : Image) -> Bool {
  previous.width == next.width &&
  previous.height == next.height &&
  previous.format == next.format &&
  previous.view_format == next.view_format &&
  previous.kind == next.kind
}

///|
fn[T] image_asset_sync_on_set(
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
    return Some(false)
  }
  let image_handle : Handle[Image] = Handle::new(handle.id())
  if !next_image.is_target_texture() && handle.id() > 0 {
    update_texture_region_mip_bytes(
      texture_id=handle.id(),
      x=0,
      y=0,
      width=next_image.width,
      height=next_image.height,
      mip_level=0,
      bytes=next_image.pixels,
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

///|
fn[T] assets_store_insert_silent(
  assets : Assets[T],
  handle : Handle[T],
  value : T,
) -> Bool {
  let id = handle.id()
  if id < 0 {
    return false
  }
  while assets.items.length() <= id {
    assets.items.push(None)
  }
  let existed = assets.items[id] is Some(_)
  assets.items[id] = Some(value)
  if !existed {
    assets.alive = assets.alive + 1
  }
  true
}
