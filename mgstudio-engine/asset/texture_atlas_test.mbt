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
fn rects_overlap(a : @math.URect, b : @math.URect) -> Bool {
  a.min.x < b.max.x &&
  a.max.x > b.min.x &&
  a.min.y < b.max.y &&
  a.max.y > b.min.y
}

///|
test "dynamic texture atlas: packs non-overlapping rects" {
  let atlas_size = @math.UVec2::new(8, 8)
  let builder = DynamicTextureAtlasBuilder::new(atlas_size, 1)
  let layout = TextureAtlasLayout::new_empty(atlas_size)
  let rects : Array[@math.URect] = []
  for _ in 0..<4 {
    let allocation = builder.add_texture(layout, @math.UVec2::new(3, 3))
    inspect(allocation is Some(_), content="true")
    if allocation is Some(value) {
      rects.push(value.1)
    }
  }
  inspect(layout.len(), content="4")
  for rect in rects {
    let size = rect.size()
    inspect(size.x, content="3")
    inspect(size.y, content="3")
    inspect(rect.min.x >= 0, content="true")
    inspect(rect.min.y >= 0, content="true")
    inspect(rect.max.x <= atlas_size.x, content="true")
    inspect(rect.max.y <= atlas_size.y, content="true")
  }
  for i in 0..<rects.length() {
    for j in (i + 1)..<rects.length() {
      inspect(rects_overlap(rects[i], rects[j]), content="false")
    }
  }
}

///|
test "dynamic texture atlas: fails to allocate when atlas too small" {
  let atlas_size = @math.UVec2::new(4, 4)
  let builder = DynamicTextureAtlasBuilder::new(atlas_size, 1)
  let layout = TextureAtlasLayout::new_empty(atlas_size)
  let allocation = builder.add_texture(layout, @math.UVec2::new(4, 4))
  inspect(allocation is None, content="true")
}

///|
test "dynamic texture atlas: stress non-overlap with varied sizes" {
  let atlas_size = @math.UVec2::new(256, 256)
  let builder = DynamicTextureAtlasBuilder::new(atlas_size, 1)
  let layout = TextureAtlasLayout::new_empty(atlas_size)
  let rects : Array[@math.URect] = []
  let mut seed = (0x1234ABCD).reinterpret_as_uint()
  fn next_rand(seed : UInt) -> UInt {
    seed * 1664525U + 1013904223U
  }

  let requested : Array[@math.UVec2] = []
  for _ in 0..<600 {
    seed = next_rand(seed)
    let w = (seed % 31U).reinterpret_as_int() + 1
    seed = next_rand(seed)
    let h = (seed % 31U).reinterpret_as_int() + 1
    let size = @math.UVec2::new(w, h)
    requested.push(size)
    let allocation = builder.add_texture(layout, size)
    match allocation {
      None => ()
      Some(value) => {
        let rect = value.1
        rects.push(rect)
        let rect_size = rect.size()
        inspect(rect_size.x, content=w.to_string())
        inspect(rect_size.y, content=h.to_string())
      }
    }
  }
  for rect in rects {
    inspect(rect.min.x >= 0, content="true")
    inspect(rect.min.y >= 0, content="true")
    inspect(rect.max.x <= atlas_size.x, content="true")
    inspect(rect.max.y <= atlas_size.y, content="true")
  }
  for i in 0..<rects.length() {
    for j in (i + 1)..<rects.length() {
      inspect(rects_overlap(rects[i], rects[j]), content="false")
    }
  }
  inspect(layout.len(), content=rects.length().to_string())
}
