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
/// Context for reusing dynamic memory allocations.
///
/// Ported from upstream `zeno/src/scratch.rs` (Apache-2.0 OR MIT).
///
/// NOTE: This is currently a minimal subset: it only stores the heap raster
/// storage used by the rasterizer.
pub struct Scratch {
  segments : Array[Segment]
  mut render : HeapStorage
}

///|
pub fn Scratch::new() -> Scratch {
  Scratch::{ segments: [], render: HeapStorage::new() }
}

///|
pub fn Scratch::default() -> Scratch {
  Scratch::new()
}

///|
pub fn Scratch::clear(self : Scratch) -> Unit {
  // Keep allocated storage but clear dynamic arrays.
  self.render.cells.clear()
  self.render.indices.clear()
  self.segments.clear()
}

///|
pub fn Scratch::render_storage(self : Scratch) -> HeapStorage {
  self.render
}

///|
pub fn Scratch::set_render_storage(
  self : Scratch,
  storage : HeapStorage,
) -> Unit {
  self.render = storage
}

///|
/// Applies the style and transform to the path and emits the result to the sink.
///
/// This is a thin wrapper that exists to mirror upstream `Scratch::apply`.
pub fn Scratch::apply(
  self : Scratch,
  data : &PathData,
  style : Style,
  transform : Transform?,
  sink : &PathBuilder,
) -> Fill {
  fn map_commands(cmds : Iter[Command], t : Transform) -> Iter[Command] {
    let buf : Array[Command] = []
    let it = cmds
    while it.next() is Some(cmd) {
      buf.push(cmd.transform(t))
    }
    let mut i = 0
    Iter::new(fn() {
      if i < buf.length() {
        let v = buf[i]
        i = i + 1
        Some(v)
      } else {
        None
      }
    })
  }

  match style {
    Style::Fill(fill) => {
      if transform is Some(t) {
        let ts = TransformSink::{ sink, transform: t }
        data.copy_to(ts)
      } else {
        data.copy_to(sink)
      }
      fill
    }
    Style::Stroke(stroke) => {
      if transform is Some(t) {
        if stroke.scale {
          let ts = TransformSink::{ sink, transform: t }
          stroke_with_storage(data.commands(), stroke, ts, self.segments)
        } else {
          stroke_with_storage(
            map_commands(data.commands(), t),
            stroke,
            sink,
            self.segments,
          )
        }
      } else {
        stroke_with_storage(data.commands(), stroke, sink, self.segments)
      }
      Fill::NonZero
    }
  }
}

///|
/// Computes the bounding box of the path.
///
/// Mirrors upstream `Scratch::bounds` (fill-only accurate until we port stroke).
pub fn Scratch::bounds(
  self : Scratch,
  data : &PathData,
  style : Style,
  transform : Transform?,
) -> Bounds {
  let b = BoundsBuilder::new()
  self.apply(data, style, transform, b) |> ignore
  b.build()
}
