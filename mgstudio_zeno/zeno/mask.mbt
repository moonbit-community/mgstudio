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
/// Mask generator (subset).
///
/// Ported from upstream `zeno/src/mask.rs` (Apache-2.0 OR MIT).
pub(all) enum Format {
  Alpha
  Subpixel
  CustomSubpixel(Array[Double])
}

///|
pub fn Format::subpixel_bgra() -> Format {
  Format::CustomSubpixel([0.3, 0.0, -0.3])
}

///|
pub fn Format::buffer_size(self : Format, width : UInt, height : UInt) -> Int {
  let pixel_size = match self {
    Format::Alpha => 1
    _ => 4
  }
  width.reinterpret_as_int() * height.reinterpret_as_int() * pixel_size
}

///|
/// Builder for configuring and rendering a mask (alpha subset).
///
/// Ported from upstream `zeno/src/mask.rs` (Apache-2.0 OR MIT).
pub struct Mask {
  data : &PathData
  mut style : Style
  mut transform : Transform?
  mut format : Format
  mut origin : Origin
  mut offset : Vector
  mut render_offset : Vector
  mut width : UInt
  mut height : UInt
  mut explicit_size : Bool
  mut has_size : Bool
  mut bounds_offset : Vector
  scratch : Ref[Scratch]?
}

///|
pub fn Mask::new(data : &PathData) -> Mask {
  Mask::{
    data,
    style: Style::default(),
    transform: None,
    format: Format::Alpha,
    origin: Origin::TopLeft,
    offset: Vector::new(0.0, 0.0),
    render_offset: Vector::new(0.0, 0.0),
    width: 0U,
    height: 0U,
    explicit_size: false,
    has_size: false,
    bounds_offset: Vector::new(0.0, 0.0),
    scratch: None,
  }
}

///|
pub fn Mask::with_scratch(data : &PathData, scratch : Ref[Scratch]) -> Mask {
  Mask::{
    data,
    style: Style::default(),
    transform: None,
    format: Format::Alpha,
    origin: Origin::TopLeft,
    offset: Vector::new(0.0, 0.0),
    render_offset: Vector::new(0.0, 0.0),
    width: 0U,
    height: 0U,
    explicit_size: false,
    has_size: false,
    bounds_offset: Vector::new(0.0, 0.0),
    scratch: Some(scratch),
  }
}

///|
pub fn Mask::style(self : Mask, style : Style) -> Mask {
  self.style = style
  self
}

///|
pub fn Mask::transform(self : Mask, transform : Transform?) -> Mask {
  self.transform = transform
  self
}

///|
pub fn Mask::format(self : Mask, format : Format) -> Mask {
  self.format = format
  self
}

///|
pub fn Mask::origin(self : Mask, origin : Origin) -> Mask {
  self.origin = origin
  self
}

///|
pub fn Mask::offset(self : Mask, offset : Vector) -> Mask {
  self.offset = offset
  self
}

///|
pub fn Mask::size(self : Mask, width : UInt, height : UInt) -> Mask {
  self.width = width
  self.height = height
  self.explicit_size = true
  self.has_size = true
  self
}

///|
pub fn Mask::render_offset(self : Mask, offset : Vector) -> Mask {
  self.render_offset = offset
  self
}

///|
fn Mask::placement(self : Mask) -> (Vector, Placement) {
  let mut offset = self.offset
  let mut width = self.width
  let mut height = self.height
  if self.explicit_size {
    let placement = Placement::{ left: 0, top: 0, width, height }
    return (offset, placement)
  } else if !self.has_size {
    let b = if self.scratch is Some(_s) {
      // TODO(zeno): use scratch.bounds for reuse.
      bounds(self.data, self.style, self.transform)
    } else {
      bounds(self.data, self.style, self.transform)
    }
    if !b.empty {
      b.min = (b.min + self.offset).floor()
      b.max = (b.max + self.offset).ceil()
    }
    offset = Vector::new(-b.min.x(), -b.min.y())
    width = b.width().to_int().reinterpret_as_uint()
    height = b.height().to_int().reinterpret_as_uint()
  } else {
    offset = self.bounds_offset
  }
  let left = (-offset.x()).to_int()
  let top = match self.origin {
    Origin::BottomLeft =>
      ((-offset.y()).floor() + height.reinterpret_as_int().to_double()).to_int()
    Origin::TopLeft => (-offset.y()).to_int()
  }
  let placement = Placement::{ left, top, width, height }
  (offset, placement)
}

///|
fn Mask::ensure_size(self : Mask) -> Unit {
  if self.has_size {
    return
  }
  let (offset, placement) = self.placement()
  self.bounds_offset = offset
  self.width = placement.width
  self.height = placement.height
  self.explicit_size = false
  self.has_size = true
}

///|
pub fn Mask::inspect(self : Mask, f : (Format, UInt, UInt) -> Unit) -> Mask {
  self.ensure_size()
  f(self.format, self.width, self.height)
  self
}

///|
/// Renders the mask into a target buffer (tightly packed; alpha only for now).
pub fn Mask::render_into(
  self : Mask,
  buffer : Array[Byte],
  pitch? : Int,
) -> Placement {
  let (offset, placement) = self.placement()
  let pitch_value = match pitch {
    Some(p) => p
    None =>
      placement.width.reinterpret_as_int() *
      (match self.format {
        Format::Alpha => 1
        _ => 4
      })
  }
  let y_up = match self.origin {
    Origin::BottomLeft => true
    _ => false
  }
  let (is_subpx, subpx) = match self.format {
    Format::Alpha =>
      (
        false,
        [Vector::new(0.0, 0.0), Vector::new(0.0, 0.0), Vector::new(0.0, 0.0)],
      )
    Format::Subpixel =>
      (
        true,
        [Vector::new(-0.3, 0.0), Vector::new(0.0, 0.0), Vector::new(0.3, 0.0)],
      )
    Format::CustomSubpixel(sp) =>
      (
        true,
        [
          Vector::new(sp[0], 0.0),
          Vector::new(sp[1], 0.0),
          Vector::new(sp[2], 0.0),
        ],
      )
  }
  let fill = match self.style {
    Style::Fill(f) => f
    _ => Fill::NonZero
  }
  let shift = offset + self.render_offset

  // Subpixel formats are TODO; for now only alpha writes to buffer.
  let maybe_scratch = self.scratch
  let storage = match maybe_scratch {
    Some(s) => s.val.render_storage()
    None => HeapStorage::new()
  }
  let ras = Rasterizer::new(storage)
  if is_subpx {
    fn write_channel(
      buffer : Array[Byte],
      channel : Int,
      row_offset : Int,
      x : Int,
      count : Int,
      coverage : Byte,
    ) -> Unit {
      let mut j = row_offset + x * 4 + channel
      for _i in 0..<count {
        buffer[j] = coverage
        j = j + 4
      }
    }

    ras.rasterize_write(
      shift + subpx[0],
      placement.width,
      placement.height,
      fn(r) { apply(self.data, self.style, self.transform, r) |> ignore },
      fill,
      pitch_value,
      y_up,
      fn(row_offset, x, count, coverage) {
        write_channel(buffer, 0, row_offset, x, count, coverage)
      },
    )
    ras.rasterize_write(
      shift + subpx[1],
      placement.width,
      placement.height,
      fn(r) { apply(self.data, self.style, self.transform, r) |> ignore },
      fill,
      pitch_value,
      y_up,
      fn(row_offset, x, count, coverage) {
        write_channel(buffer, 1, row_offset, x, count, coverage)
      },
    )
    ras.rasterize_write(
      shift + subpx[2],
      placement.width,
      placement.height,
      fn(r) { apply(self.data, self.style, self.transform, r) |> ignore },
      fill,
      pitch_value,
      y_up,
      fn(row_offset, x, count, coverage) {
        write_channel(buffer, 2, row_offset, x, count, coverage)
      },
    )
  } else {
    ras.rasterize(
      shift,
      placement.width,
      placement.height,
      fn(r) { apply(self.data, self.style, self.transform, r) |> ignore },
      fill,
      buffer,
      pitch_value,
      y_up,
    )
  }
  match maybe_scratch {
    Some(s) => s.val.set_render_storage(ras.storage())
    None => ()
  }
  placement
}
