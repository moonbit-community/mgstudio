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
fn abs_float(value : Float) -> Float {
  if value < 0.0F {
    -value
  } else {
    value
  }
}

///|
fn approx_eq(a : Float, b : Float) -> Bool {
  abs_float(a - b) < 0.0001F
}

///|
test "render2d: Assets::add accepts mesh geometry and color authoring values" {
  let meshes : @asset.Assets[@mesh.Mesh] = @asset.Assets::new()
  let materials : @asset.Assets[
    @sprite_render_mesh2d_color_material.ColorMaterial,
  ] = @asset.Assets::new()
  let expected_color = @color.Color::srgb(0.25F, 0.5F, 0.75F)
  let mesh_handle = meshes
    |> @mesh_primitives.add_mesh(@math.Rectangle::new(10.0F, 20.0F))
  let material_handle = @sprite_render_mesh2d_color_material.add_material(
    materials, expected_color,
  )
  let ok = if meshes.get(mesh_handle) is Some(mesh) {
    if materials.get(material_handle) is Some(material) {
      let geometry_ok = match mesh.as_3d_geometry() {
        Some(geometry) =>
          geometry.vertex_count() == 4 &&
          geometry.indices_or_sequential().length() == 6 &&
          geometry.primitive_topology() ==
          @mesh.Mesh3dPrimitiveTopology::TriangleList
        None => false
      }
      geometry_ok &&
      approx_eq(material.color.r, expected_color.r) &&
      approx_eq(material.color.g, expected_color.g) &&
      approx_eq(material.color.b, expected_color.b) &&
      material.alpha_mode is @sprite_render_mesh2d_material.AlphaMode2d::Opaque
    } else {
      false
    }
  } else {
    false
  }
  debug_inspect(ok, content="true")
}
