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
/// Glyph rasterization cache key (ported from `cosmic-text/src/glyph_cache.rs`).
///
/// This file is backend-agnostic; it can be unit-tested on wasm-gc.

///|
/// Flags that change rendering.
pub type CacheKeyFlags = UInt

///|
pub const CACHE_KEY_FLAG_FAKE_ITALIC : CacheKeyFlags = 1U

///|
pub const CACHE_KEY_FLAG_DISABLE_HINTING : CacheKeyFlags = 2U

///|
pub const CACHE_KEY_FLAG_PIXEL_FONT : CacheKeyFlags = 4U

///|
fn has_flag(flags : CacheKeyFlags, flag : CacheKeyFlags) -> Bool {
  (flags & flag) != 0U
}

///|
/// Binning of subpixel position for cache optimization.
pub enum SubpixelBin {
  Zero
  One
  Two
  Three
}

///|
fn SubpixelBin::to_int(self : SubpixelBin) -> Int {
  match self {
    Zero => 0
    One => 1
    Two => 2
    Three => 3
  }
}

///|
pub impl Eq for SubpixelBin with equal(self, other) {
  self.to_int() == other.to_int()
}

///|
pub impl Hash for SubpixelBin with hash_combine(self, hasher) {
  hasher.combine_int(self.to_int())
}

///|
pub impl Show for SubpixelBin with output(self, logger) {
  logger.write_string(
    match self {
      Zero => "Zero"
      One => "One"
      Two => "Two"
      Three => "Three"
    },
  )
}

///|
pub fn SubpixelBin::as_float(self : SubpixelBin) -> Float {
  match self {
    Zero => 0.0F
    One => 0.25F
    Two => 0.5F
    Three => 0.75F
  }
}

///|
/// Returns (integral pixel position, bin for fractional part).
///
/// Matches upstream `cosmic-text` binning behavior, including negative positions.
pub fn SubpixelBin::new(pos : Float) -> (Int, SubpixelBin) {
  let trunc = pos.to_int()
  let fract = pos - Float::from_double(trunc.to_double())

  // Note: treat -0.0 as negative for parity with upstream.
  let is_neg = if pos == 0.0F { 1.0F / pos < 0.0F } else { pos < 0.0F }
  if is_neg {
    if fract > -0.125F {
      (trunc, Zero)
    } else if fract > -0.375F {
      (trunc - 1, Three)
    } else if fract > -0.625F {
      (trunc - 1, Two)
    } else if fract > -0.875F {
      (trunc - 1, One)
    } else {
      (trunc - 1, Zero)
    }
  } else if fract < 0.125F {
    (trunc, Zero)
  } else if fract < 0.375F {
    (trunc, One)
  } else if fract < 0.625F {
    (trunc, Two)
  } else if fract < 0.875F {
    (trunc, Three)
  } else {
    (trunc + 1, Zero)
  }
}

///|
/// Key for building a glyph cache.
///
/// NOTE: we keep this as a plain struct (instead of bitfields) to match the
/// conceptual model of `cosmic-text`.
pub struct CacheKey {
  /// Font ID (implementation-defined; see FontSystem)
  font_id : Int
  /// Glyph ID
  glyph_id : Int
  /// `f32` bits of font size
  font_size_bits : UInt
  /// Binning of fractional X offset
  x_bin : SubpixelBin
  /// Binning of fractional Y offset
  y_bin : SubpixelBin
  /// Font weight (implementation-defined; see Weight)
  font_weight : Int
  /// CacheKeyFlags bitset
  flags : CacheKeyFlags
}

///|
pub impl Eq for CacheKey with equal(self, other) {
  self.font_id == other.font_id &&
  self.glyph_id == other.glyph_id &&
  self.font_size_bits == other.font_size_bits &&
  self.x_bin == other.x_bin &&
  self.y_bin == other.y_bin &&
  self.font_weight == other.font_weight &&
  self.flags == other.flags
}

///|
pub impl Hash for CacheKey with hash_combine(self, hasher) {
  hasher.combine_int(self.font_id)
  hasher.combine_int(self.glyph_id)
  hasher.combine_uint(self.font_size_bits)
  hasher.combine_int(self.x_bin.to_int())
  hasher.combine_int(self.y_bin.to_int())
  hasher.combine_int(self.font_weight)
  hasher.combine_uint(self.flags)
}

///|
pub impl Show for CacheKey with output(self, logger) {
  logger.write_string("CacheKey{")
  logger.write_string("font_id=")
  logger.write_string(self.font_id.to_string())
  logger.write_string(", glyph_id=")
  logger.write_string(self.glyph_id.to_string())
  logger.write_string(", font_size_bits=")
  logger.write_string(self.font_size_bits.to_string())
  logger.write_string(", x_bin=")
  logger.write_string(self.x_bin.to_string())
  logger.write_string(", y_bin=")
  logger.write_string(self.y_bin.to_string())
  logger.write_string(", font_weight=")
  logger.write_string(self.font_weight.to_string())
  logger.write_string(", flags=")
  logger.write_string(self.flags.to_string())
  logger.write_string("}")
}

///|
fn u32_from_be_bytes(b : Bytes) -> UInt {
  let b0 = if b.get(0) is Some(v) { v } else { 0x00 }
  let b1 = if b.get(1) is Some(v) { v } else { 0x00 }
  let b2 = if b.get(2) is Some(v) { v } else { 0x00 }
  let b3 = if b.get(3) is Some(v) { v } else { 0x00 }
  let u0 = b0.to_int().reinterpret_as_uint()
  let u1 = b1.to_int().reinterpret_as_uint()
  let u2 = b2.to_int().reinterpret_as_uint()
  let u3 = b3.to_int().reinterpret_as_uint()
  (u0 << 24) | (u1 << 16) | (u2 << 8) | u3
}

///|
pub fn CacheKey::new(
  font_id : Int,
  glyph_id : Int,
  font_size : Float,
  pos : (Float, Float),
  font_weight : Int,
  flags : CacheKeyFlags,
) -> (CacheKey, Int, Int) {
  let (x, x_bin) = SubpixelBin::new(pos.0)
  let (y, y_bin) = SubpixelBin::new(pos.1)
  let font_size_bits = u32_from_be_bytes(Float::to_be_bytes(font_size))
  (
    CacheKey::{
      font_id,
      glyph_id,
      font_size_bits,
      x_bin,
      y_bin,
      font_weight,
      flags,
    },
    x,
    y,
  )
}

///|
pub fn CacheKey::has_fake_italic(self : CacheKey) -> Bool {
  has_flag(self.flags, CACHE_KEY_FLAG_FAKE_ITALIC)
}

///|
pub fn CacheKey::has_disable_hinting(self : CacheKey) -> Bool {
  has_flag(self.flags, CACHE_KEY_FLAG_DISABLE_HINTING)
}

///|
pub fn CacheKey::has_pixel_font(self : CacheKey) -> Bool {
  has_flag(self.flags, CACHE_KEY_FLAG_PIXEL_FONT)
}

///|
pub fn CacheKey::x_bin(self : CacheKey) -> SubpixelBin {
  self.x_bin
}

///|
pub fn CacheKey::y_bin(self : CacheKey) -> SubpixelBin {
  self.y_bin
}
