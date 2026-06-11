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
test "pbr: thin wireframe immediates carry only material color" {
  let material = RenderWireframeMaterial::from_material(
    WireframeMaterial::new(
      @color.Color::new(0.25F, 0.5F, 0.75F, 1.0F),
      7.0F,
      Quads,
    ),
  )
  let immediates = Wireframe3dThinImmediates::from_material(material)

  debug_inspect(immediates.float_count(), content="4")
  debug_inspect(immediates.color().r, content="0.25")
  debug_inspect(immediates.color().g, content="0.5")
  debug_inspect(immediates.color().b, content="0.75")
}

///|
test "pbr: wide wireframe immediates follow Bevy smoothing rule" {
  let thin_line = Wireframe3dWideImmediates::from_material(
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 1.0F, Triangles),
    ),
  )
  let thick_line = Wireframe3dWideImmediates::from_material(
    RenderWireframeMaterial::from_material(
      WireframeMaterial::new(@color.Color::white(), 2.0F, Triangles),
    ),
  )

  debug_inspect(thin_line.float_count(), content="8")
  debug_inspect(thin_line.line_width(), content="1")
  debug_inspect(thin_line.smoothing(), content="0.5")
  debug_inspect(thick_line.line_width(), content="2")
  debug_inspect(thick_line.smoothing(), content="1")
}

///|
test "pbr: wireframe vertex pull params preserve Bevy field order" {
  let params = WireframeVertexPullParams::new(3U, 8U, 1U)

  debug_inspect(
    params,
    content="{ index_offset: 3, vertex_stride_u32s: 8, position_offset_u32s: 1 }",
  )
  debug_inspect(params.index_offset(), content="3")
  debug_inspect(params.vertex_stride_u32s(), content="8")
  debug_inspect(params.position_offset_u32s(), content="1")
}
