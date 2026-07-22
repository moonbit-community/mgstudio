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
fn color_material_close(a : Float, b : Float) -> Bool {
  (a - b).abs() < 0.0001F
}

///|
test "color material: add_material stores color authoring values" {
  let materials : @asset.Assets[ColorMaterial] = @asset.Assets::new()
  let expected_color = @color.Color::srgb(0.25F, 0.5F, 0.75F)
  let material_handle = add_material(materials, expected_color)
  let ok = match materials.get(material_handle) {
    Some(material) =>
      color_material_close(material.color.r, expected_color.r) &&
      color_material_close(material.color.g, expected_color.g) &&
      color_material_close(material.color.b, expected_color.b) &&
      material.alpha_mode is Opaque
    None => false
  }
  debug_inspect(ok, content="true")
}
