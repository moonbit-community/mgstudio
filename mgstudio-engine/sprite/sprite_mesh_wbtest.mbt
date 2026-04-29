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
fn sprite_mesh_test_u32le_word(bytes : Bytes, index : Int) -> UInt {
  let offset = index * 4
  bytes[offset].to_uint() |
  (bytes[offset + 1].to_uint() << 8) |
  (bytes[offset + 2].to_uint() << 16) |
  (bytes[offset + 3].to_uint() << 24)
}

///|
test "sprite mesh wb: SpriteMaterial uniform applies Bevy atlas uv transform" {
  let image = @asset.asset_create_dynamic_texture(
    @math.UVec2::new(100, 50),
    true,
  )
  let layout = @asset.TextureAtlasLayout::new_empty(@math.UVec2::new(100, 50))
  ignore(
    layout.add_texture(
      @math.URect::new(@math.UVec2::new(10, 5), @math.UVec2::new(60, 25)),
    ),
  )
  let material = SpriteMaterial::from_sprite_mesh(SpriteMesh::from_image(image)).with_texture_atlas_layout(
    Some(layout),
    0,
  )
  let bytes = sprite_material_uniform_bytes(material)

  debug_inspect(bytes.length(), content="144")
  debug_inspect(
    sprite_mesh_test_u32le_word(bytes, 6) == material2d_f32_bits(50.0F),
    content="true",
  )
  debug_inspect(
    sprite_mesh_test_u32le_word(bytes, 7) == material2d_f32_bits(20.0F),
    content="true",
  )
  debug_inspect(
    sprite_mesh_test_u32le_word(bytes, 12) == material2d_f32_bits(0.5F),
    content="true",
  )
  debug_inspect(
    sprite_mesh_test_u32le_word(bytes, 17) == material2d_f32_bits(0.4F),
    content="true",
  )
  debug_inspect(
    sprite_mesh_test_u32le_word(bytes, 20) == material2d_f32_bits(0.1F),
    content="true",
  )
  debug_inspect(
    sprite_mesh_test_u32le_word(bytes, 21) == material2d_f32_bits(0.1F),
    content="true",
  )
}
