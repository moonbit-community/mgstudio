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
type ColorMaterial = @sprite_render_mesh2d_color_material.ColorMaterial

///|
type ColorMaterialPlugin = @sprite_render_mesh2d_color_material.ColorMaterialPlugin

///|
fn prepared_color_materials_for_tests(
  materials : Array[(@asset.Handle[ColorMaterial], ColorMaterial)],
) -> @render.RenderAssets[PreparedMaterial2d[ColorMaterial]] {
  @sprite_render_mesh2d_color_material.prepared_color_materials_for_tests(
    materials,
  )
}
