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
test "texture atlas: with_index preserves inline value semantics" {
  let atlas = TextureAtlas::new(Handle::new(9), 3)
  let next = atlas.with_index(4)
  debug_inspect(atlas.layout().id(), content="9")
  debug_inspect(atlas.index(), content="3")
  debug_inspect(next.layout().id(), content="9")
  debug_inspect(next.index(), content="4")
}

///|
test "dynamic texture atlas: packs non-overlapping rects" {
  let atlas_size = @math.UVec2::new(8, 8)
  let builder = DynamicTextureAtlasBuilder::new(atlas_size, 1)
  let layout = TextureAtlasLayout::new_empty(atlas_size)
  let rects : Array[@math.URect] = []
  for _ in 0..<4 {
    let allocation = builder.add_texture(layout, @math.UVec2::new(3, 3))
    debug_inspect(allocation is Some(_), content="true")
    if allocation is Some(value) {
      rects.push(value.1)
    }
  }
  debug_inspect(layout.len(), content="4")
  for rect in rects {
    let size = rect.size()
    debug_inspect(size.x, content="3")
    debug_inspect(size.y, content="3")
    debug_inspect(rect.min.x >= 0, content="true")
    debug_inspect(rect.min.y >= 0, content="true")
    debug_inspect(rect.max.x <= atlas_size.x, content="true")
    debug_inspect(rect.max.y <= atlas_size.y, content="true")
  }
  for i in 0..<rects.length() {
    for j in (i + 1)..<rects.length() {
      debug_inspect(rects_overlap(rects[i], rects[j]), content="false")
    }
  }
}

///|
test "dynamic texture atlas: fails to allocate when atlas too small" {
  let atlas_size = @math.UVec2::new(4, 4)
  let builder = DynamicTextureAtlasBuilder::new(atlas_size, 1)
  let layout = TextureAtlasLayout::new_empty(atlas_size)
  let allocation = builder.add_texture(layout, @math.UVec2::new(4, 4))
  debug_inspect(allocation is None, content="true")
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
        debug_inspect(rect_size.x, content=w.to_string())
        debug_inspect(rect_size.y, content=h.to_string())
      }
    }
  }
  for rect in rects {
    debug_inspect(rect.min.x >= 0, content="true")
    debug_inspect(rect.min.y >= 0, content="true")
    debug_inspect(rect.max.x <= atlas_size.x, content="true")
    debug_inspect(rect.max.y <= atlas_size.y, content="true")
  }
  for i in 0..<rects.length() {
    for j in (i + 1)..<rects.length() {
      debug_inspect(rects_overlap(rects[i], rects[j]), content="false")
    }
  }
  debug_inspect(layout.len(), content=rects.length().to_string())
}

///|
fn atlas_test_rect(layout : TextureAtlasLayout, index : Int) -> @math.URect {
  match layout.texture(index) {
    Some(rect) => rect
    None => abort("missing texture atlas rect")
  }
}

///|
fn atlas_expect_rect(
  layout : TextureAtlasLayout,
  index : Int,
  min_x : Int,
  min_y : Int,
  max_x : Int,
  max_y : Int,
) -> Unit raise {
  let rect = atlas_test_rect(layout, index)
  debug_inspect(rect.min.x, content=min_x.to_string())
  debug_inspect(rect.min.y, content=min_y.to_string())
  debug_inspect(rect.max.x, content=max_x.to_string())
  debug_inspect(rect.max.y, content=max_y.to_string())
}

///|
fn atlas_expect_source(
  sources : TextureAtlasSources,
  texture : Handle[Image],
  index : Int,
) -> Unit raise {
  debug_inspect(
    sources.texture_index(texture).unwrap_or(-1),
    content=index.to_string(),
  )
}

///|
test "texture atlas builder: matches Bevy rectangle_pack placements without padding" {
  let a = asset_create_dynamic_texture(@math.UVec2::new(100, 40), false)
  let b = asset_create_dynamic_texture(@math.UVec2::new(20, 120), false)
  let c = asset_create_dynamic_texture(@math.UVec2::new(60, 60), false)
  let d = asset_create_dynamic_texture(@math.UVec2::new(30, 30), false)
  let builder = TextureAtlasBuilder::TextureAtlasBuilder()
    .initial_size(@math.UVec2::new(128, 128))
    .max_size(@math.UVec2::new(256, 256))
    .add_texture(a)
    .add_texture(b)
    .add_texture(c)
    .add_texture(d)
  let (layout, sources, atlas_texture) = match builder.try_build() {
    Some(value) => value
    None => abort("expected texture atlas build")
  }
  debug_inspect(layout.size().x, content="256")
  debug_inspect(layout.size().y, content="256")
  debug_inspect(asset_texture_width(atlas_texture), content="256")
  debug_inspect(asset_texture_height(atlas_texture), content="256")
  atlas_expect_rect(layout, 0, 0, 0, 100, 40)
  atlas_expect_rect(layout, 1, 0, 100, 20, 220)
  atlas_expect_rect(layout, 2, 0, 40, 60, 100)
  atlas_expect_rect(layout, 3, 20, 100, 50, 130)
  atlas_expect_source(sources, a, 0)
  atlas_expect_source(sources, b, 1)
  atlas_expect_source(sources, c, 2)
  atlas_expect_source(sources, d, 3)
}

///|
test "texture atlas builder: matches Bevy rectangle_pack placements with padding" {
  let a = asset_create_dynamic_texture(@math.UVec2::new(64, 32), false)
  let b = asset_create_dynamic_texture(@math.UVec2::new(32, 64), false)
  let c = asset_create_dynamic_texture(@math.UVec2::new(16, 16), false)
  let d = asset_create_dynamic_texture(@math.UVec2::new(48, 20), false)
  let e = asset_create_dynamic_texture(@math.UVec2::new(20, 48), false)
  let builder = TextureAtlasBuilder::TextureAtlasBuilder()
    .initial_size(@math.UVec2::new(128, 128))
    .max_size(@math.UVec2::new(256, 256))
    .padding(@math.UVec2::new(6, 6))
    .add_texture(a)
    .add_texture(b)
    .add_texture(c)
    .add_texture(d)
    .add_texture(e)
  let (layout, sources, atlas_texture) = match builder.try_build() {
    Some(value) => value
    None => abort("expected padded texture atlas build")
  }
  debug_inspect(layout.size().x, content="128")
  debug_inspect(layout.size().y, content="128")
  debug_inspect(asset_texture_width(atlas_texture), content="128")
  debug_inspect(asset_texture_height(atlas_texture), content="128")
  atlas_expect_rect(layout, 0, 0, 0, 64, 32)
  atlas_expect_rect(layout, 1, 0, 38, 32, 102)
  atlas_expect_rect(layout, 2, 64, 64, 80, 80)
  atlas_expect_rect(layout, 3, 38, 38, 86, 58)
  atlas_expect_rect(layout, 4, 38, 64, 58, 112)
  atlas_expect_source(sources, a, 0)
  atlas_expect_source(sources, b, 1)
  atlas_expect_source(sources, c, 2)
  atlas_expect_source(sources, d, 3)
  atlas_expect_source(sources, e, 4)
}
