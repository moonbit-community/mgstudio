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
type Wireframe2dConfig = @sprite_render_mesh2d_wireframe2d.Wireframe2dConfig

///|
type Mesh2dWireframe = @sprite_render_mesh2d_wireframe2d.Mesh2dWireframe

///|
fn wireframe2d_material_color(
  world : @ecs.World,
  wireframe : Mesh2dWireframe,
) -> Color {
  @sprite_render_mesh2d_wireframe2d.wireframe2d_material_color(world, wireframe)
}
