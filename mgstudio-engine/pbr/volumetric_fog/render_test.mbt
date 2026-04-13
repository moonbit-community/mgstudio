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
test "pbr volumetric fog: pipeline selection by density texture flag" {
  let pipelines = view_volumetric_fog_pipelines(11, 29)
  let key_without_texture = volumetric_fog_pipeline_key(false, 1, false)
  let key_with_texture = volumetric_fog_pipeline_key(true, 4, true)
  inspect(
    volumetric_fog_select_pipeline(pipelines, key_without_texture),
    content="11",
  )
  inspect(
    volumetric_fog_select_pipeline(pipelines, key_with_texture),
    content="29",
  )
}

///|
test "pbr volumetric fog: uniform buffer push and clear" {
  let buffer = VolumetricFogUniformBuffer::default()
  let offset0 = buffer.push(VolumetricFogUniform::default())
  let offset1 = buffer.push(VolumetricFogUniform::default().with_step_count(96))
  inspect(offset0, content="0")
  inspect(offset1, content="1")
  inspect(buffer.count(), content="2")
  buffer.clear()
  inspect(buffer.count(), content="0")
}
