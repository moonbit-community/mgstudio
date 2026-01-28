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
/// Minimal image decoder for the native runtime.
///
/// We currently only need RGBA8 pixels for uploading into a WebGPU texture.
/// The implementation is backed by a small C stub using stb_image.

///|
pub struct DecodedImage {
  raw : @wgpu_c.OpaquePtr
}

///|
pub fn DecodedImage::is_null(self : DecodedImage) -> Bool {
  c_image_is_null(self.raw)
}

///|
pub fn decode_rgba8(bytes : Bytes) -> DecodedImage? {
  let raw = c_decode_rgba8(bytes)
  if c_image_is_null(raw) {
    None
  } else {
    Some(DecodedImage::{ raw, })
  }
}

///|
pub fn DecodedImage::width(self : DecodedImage) -> Int {
  c_image_width(self.raw)
}

///|
pub fn DecodedImage::height(self : DecodedImage) -> Int {
  c_image_height(self.raw)
}

///|
pub fn DecodedImage::pixels_rgba8(self : DecodedImage) -> Bytes {
  c_image_pixels_rgba8(self.raw)
}

///|
pub fn DecodedImage::destroy(self : DecodedImage) -> Unit {
  c_image_destroy(self.raw)
}

///|
#borrow(bytes)
extern "C" fn c_decode_rgba8(bytes : Bytes) -> @wgpu_c.OpaquePtr = "mgimg_decode_rgba8"

///|
extern "C" fn c_image_is_null(img : @wgpu_c.OpaquePtr) -> Bool = "mgimg_image_is_null"

///|
extern "C" fn c_image_width(img : @wgpu_c.OpaquePtr) -> Int = "mgimg_image_width"

///|
extern "C" fn c_image_height(img : @wgpu_c.OpaquePtr) -> Int = "mgimg_image_height"

///|
extern "C" fn c_image_pixels_rgba8(img : @wgpu_c.OpaquePtr) -> Bytes = "mgimg_image_pixels_rgba8"

///|
extern "C" fn c_image_destroy(img : @wgpu_c.OpaquePtr) -> Unit = "mgimg_image_destroy"
