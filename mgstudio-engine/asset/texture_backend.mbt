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
pub(all) struct AssetTextureCapture {
  width : Int
  height : Int
  pixels : Bytes
}

///|
pub fn AssetTextureCapture::new(
  width~ : Int,
  height~ : Int,
  pixels~ : Bytes,
) -> AssetTextureCapture {
  AssetTextureCapture::{ width, height, pixels }
}

///|
pub fn AssetTextureCapture::width(self : AssetTextureCapture) -> Int {
  self.width
}

///|
pub fn AssetTextureCapture::height(self : AssetTextureCapture) -> Int {
  self.height
}

///|
pub fn AssetTextureCapture::pixels(self : AssetTextureCapture) -> Bytes {
  self.pixels
}

///|
pub(all) struct AssetTextureBackend {
  create_render_target_with_formats_fn : (Int, Int, Bool, Int, Int) -> Int
  create_texture_empty_fn : (Int, Int, Int, Bool) -> Int
  create_texture_3d_with_format_fn : (Int, Int, Int, Int, Bytes) -> Int
  create_texture_stacked_2d_with_format_fn : (
    Int,
    Int,
    Int,
    Int,
    Array[Bytes],
    Bool,
  ) -> Int
  create_texture_cube_with_format_fn : (Int, Int, Int, Array[Bytes], Bool) -> Int
  write_texture_region_rgba8_fn : (Int, Int, Int, Int, Int, Bytes) -> Unit
  write_texture_region_rgba8_mip_fn : (Int, Int, Int, Int, Int, Int, Bytes) -> Unit
  create_texture_mip_view_fn : (Int, Int) -> Int
  texture_width_fn : (Int) -> Int
  texture_height_fn : (Int) -> Int
  is_texture_loaded_fn : (Int) -> Bool
  supported_compressed_image_formats_fn : () -> Int
  copy_texture_to_texture_fn : (Int, Int, Int, Int) -> Unit
  set_texture_sampler_fn : (
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Float,
    Float,
    Int,
    Int,
    Int,
  ) -> Unit
  capture_texture_rgba8_fn : (Int) -> AssetTextureCapture?
}

///|
pub fn AssetTextureBackend::new(
  create_render_target_with_formats_fn~ : (Int, Int, Bool, Int, Int) -> Int,
  create_texture_empty_fn~ : (Int, Int, Int, Bool) -> Int,
  create_texture_3d_with_format_fn~ : (Int, Int, Int, Int, Bytes) -> Int,
  create_texture_stacked_2d_with_format_fn~ : (
    Int,
    Int,
    Int,
    Int,
    Array[Bytes],
    Bool,
  ) -> Int,
  create_texture_cube_with_format_fn~ : (Int, Int, Int, Array[Bytes], Bool) -> Int,
  write_texture_region_rgba8_fn~ : (Int, Int, Int, Int, Int, Bytes) -> Unit,
  write_texture_region_rgba8_mip_fn~ : (Int, Int, Int, Int, Int, Int, Bytes) -> Unit,
  create_texture_mip_view_fn~ : (Int, Int) -> Int,
  texture_width_fn~ : (Int) -> Int,
  texture_height_fn~ : (Int) -> Int,
  is_texture_loaded_fn~ : (Int) -> Bool,
  supported_compressed_image_formats_fn~ : () -> Int,
  copy_texture_to_texture_fn~ : (Int, Int, Int, Int) -> Unit,
  set_texture_sampler_fn~ : (
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Int,
    Float,
    Float,
    Int,
    Int,
    Int,
  ) -> Unit,
  capture_texture_rgba8_fn~ : (Int) -> AssetTextureCapture?,
) -> AssetTextureBackend {
  AssetTextureBackend::{
    create_render_target_with_formats_fn,
    create_texture_empty_fn,
    create_texture_3d_with_format_fn,
    create_texture_stacked_2d_with_format_fn,
    create_texture_cube_with_format_fn,
    write_texture_region_rgba8_fn,
    write_texture_region_rgba8_mip_fn,
    create_texture_mip_view_fn,
    texture_width_fn,
    texture_height_fn,
    is_texture_loaded_fn,
    supported_compressed_image_formats_fn,
    copy_texture_to_texture_fn,
    set_texture_sampler_fn,
    capture_texture_rgba8_fn,
  }
}

///|
priv struct TextureRecord {
  id : Int
  width : Int
  height : Int
  loaded : Bool
}

///|
priv struct AssetTextureBackendState {
  mut backend : AssetTextureBackend?
}

///|
let asset_texture_backend_state : AssetTextureBackendState = { backend: None }

///|
let texture_records : Array[TextureRecord] = []

///|
pub fn register_asset_texture_backend(backend : AssetTextureBackend) -> Unit {
  asset_texture_backend_state.backend = Some(backend)
}

///|
fn asset_texture_backend() -> AssetTextureBackend? {
  asset_texture_backend_state.backend
}

///|
fn texture_record(texture_id : Int) -> TextureRecord? {
  for record in texture_records {
    if record.id == texture_id {
      return Some(record)
    }
  }
  None
}

///|
fn texture_record_set(
  texture_id : Int,
  width : Int,
  height : Int,
  loaded : Bool,
) -> Unit {
  let record = TextureRecord::{ id: texture_id, width, height, loaded }
  for i in 0..<texture_records.length() {
    if texture_records[i].id == texture_id {
      texture_records[i] = record
      return
    }
  }
  texture_records.push(record)
}

///|
fn asset_texture_cpu_allocate(width : Int, height : Int, loaded : Bool) -> Int {
  let id = next_id()
  texture_record_set(id, width, height, loaded)
  id
}

///|
fn asset_texture_backend_create_render_target_with_formats(
  width~ : Int,
  height~ : Int,
  nearest~ : Bool,
  format_raw~ : Int,
  sample_format_raw~ : Int,
) -> Int {
  nearest |> ignore
  format_raw |> ignore
  sample_format_raw |> ignore
  match asset_texture_backend() {
    Some(backend) =>
      (backend.create_render_target_with_formats_fn)(
        width, height, nearest, format_raw, sample_format_raw,
      )
    None => asset_texture_cpu_allocate(width, height, true)
  }
}

///|
fn asset_texture_backend_create_texture_empty(
  width~ : Int,
  height~ : Int,
  mip_level_count~ : Int,
  nearest~ : Bool,
) -> Int {
  mip_level_count |> ignore
  nearest |> ignore
  match asset_texture_backend() {
    Some(backend) =>
      (backend.create_texture_empty_fn)(width, height, mip_level_count, nearest)
    None => asset_texture_cpu_allocate(width, height, true)
  }
}

///|
fn asset_texture_backend_create_texture_3d_with_format(
  width~ : Int,
  height~ : Int,
  depth~ : Int,
  format_raw~ : Int,
  pixels~ : Bytes,
) -> Int {
  depth |> ignore
  format_raw |> ignore
  match asset_texture_backend() {
    Some(backend) =>
      (backend.create_texture_3d_with_format_fn)(
        width, height, depth, format_raw, pixels,
      )
    None => {
      let id = asset_texture_cpu_allocate(width, height, true)
      set_texture_pixels(id, pixels)
      id
    }
  }
}

///|
fn asset_texture_backend_create_texture_stacked_2d_with_format(
  width~ : Int,
  height_per_slice~ : Int,
  slice_count~ : Int,
  format_raw~ : Int,
  levels~ : Array[Bytes],
  nearest~ : Bool,
) -> Int {
  slice_count |> ignore
  format_raw |> ignore
  nearest |> ignore
  match asset_texture_backend() {
    Some(backend) =>
      (backend.create_texture_stacked_2d_with_format_fn)(
        width, height_per_slice, slice_count, format_raw, levels, nearest,
      )
    None => {
      let id = asset_texture_cpu_allocate(width, height_per_slice, true)
      match levels {
        [first, ..] => set_texture_pixels(id, first)
        [] => ()
      }
      id
    }
  }
}

///|
fn asset_texture_backend_create_texture_cube_with_format(
  width~ : Int,
  height~ : Int,
  format_raw~ : Int,
  levels~ : Array[Bytes],
  nearest~ : Bool,
) -> Int {
  format_raw |> ignore
  nearest |> ignore
  match asset_texture_backend() {
    Some(backend) =>
      (backend.create_texture_cube_with_format_fn)(
        width, height, format_raw, levels, nearest,
      )
    None => {
      let id = asset_texture_cpu_allocate(width, height, true)
      match levels {
        [first, ..] => set_texture_pixels(id, first)
        [] => ()
      }
      id
    }
  }
}

///|
fn asset_texture_backend_write_texture_region_rgba8(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  match asset_texture_backend() {
    Some(backend) =>
      (backend.write_texture_region_rgba8_fn)(
        texture_id, x, y, width, height, pixels_rgba8,
      )
    None => ()
  }
}

///|
fn asset_texture_backend_write_texture_region_rgba8_mip(
  texture_id~ : Int,
  x~ : Int,
  y~ : Int,
  width~ : Int,
  height~ : Int,
  mip_level~ : Int,
  pixels_rgba8~ : Bytes,
) -> Unit {
  match asset_texture_backend() {
    Some(backend) =>
      (backend.write_texture_region_rgba8_mip_fn)(
        texture_id, x, y, width, height, mip_level, pixels_rgba8,
      )
    None => ()
  }
}

///|
fn asset_texture_backend_create_texture_mip_view(
  texture_id~ : Int,
  mip_level~ : Int,
) -> Int {
  match asset_texture_backend() {
    Some(backend) => (backend.create_texture_mip_view_fn)(texture_id, mip_level)
    None =>
      match texture_record(texture_id) {
        Some(record) =>
          asset_texture_cpu_allocate(record.width, record.height, record.loaded)
        None => 0
      }
  }
}

///|
fn asset_texture_backend_width(texture_id : Int) -> Int {
  match asset_texture_backend() {
    Some(backend) => (backend.texture_width_fn)(texture_id)
    None =>
      match texture_record(texture_id) {
        Some(record) => record.width
        None => 0
      }
  }
}

///|
fn asset_texture_backend_height(texture_id : Int) -> Int {
  match asset_texture_backend() {
    Some(backend) => (backend.texture_height_fn)(texture_id)
    None =>
      match texture_record(texture_id) {
        Some(record) => record.height
        None => 0
      }
  }
}

///|
fn asset_texture_backend_is_loaded(texture_id : Int) -> Bool {
  match asset_texture_backend() {
    Some(backend) => (backend.is_texture_loaded_fn)(texture_id)
    None =>
      match texture_record(texture_id) {
        Some(record) => record.loaded
        None => false
      }
  }
}

///|
fn asset_texture_backend_supported_compressed_image_formats() -> Int {
  match asset_texture_backend() {
    Some(backend) => (backend.supported_compressed_image_formats_fn)()
    None => COMPRESSED_IMAGE_FORMAT_NONE
  }
}

///|
fn asset_texture_backend_copy_texture_to_texture(
  dst_texture_id~ : Int,
  dst_x~ : Int,
  dst_y~ : Int,
  src_texture_id~ : Int,
) -> Unit {
  match asset_texture_backend() {
    Some(backend) =>
      (backend.copy_texture_to_texture_fn)(
        dst_texture_id, dst_x, dst_y, src_texture_id,
      )
    None => ()
  }
}

///|
fn asset_texture_backend_set_texture_sampler(
  texture_id~ : Int,
  address_mode_u~ : Int,
  address_mode_v~ : Int,
  address_mode_w~ : Int,
  mag_filter~ : Int,
  min_filter~ : Int,
  mipmap_filter~ : Int,
  lod_min_clamp~ : Float,
  lod_max_clamp~ : Float,
  compare~ : Int,
  anisotropy_clamp~ : Int,
  border_color~ : Int,
) -> Unit {
  match asset_texture_backend() {
    Some(backend) =>
      (backend.set_texture_sampler_fn)(
        texture_id, address_mode_u, address_mode_v, address_mode_w, mag_filter, min_filter,
        mipmap_filter, lod_min_clamp, lod_max_clamp, compare, anisotropy_clamp, border_color,
      )
    None => ()
  }
}

///|
fn asset_texture_backend_capture_texture_rgba8(
  texture_id : Int,
) -> AssetTextureCapture? {
  match asset_texture_backend() {
    Some(backend) => (backend.capture_texture_rgba8_fn)(texture_id)
    None => None
  }
}
