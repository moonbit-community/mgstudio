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
struct Mesh3dRegisteredMaterialPipelineDescriptor {
  material_pipeline_id : UInt64
  descriptor : @render_resource.RenderPipelineDescriptor
}

///|
fn mesh3d_material_pipeline_descriptor_find(
  backend : GpuBackend,
  material_pipeline_id : UInt64,
) -> @render_resource.RenderPipelineDescriptor? {
  for entry in backend.mesh3d_material_pipeline_descriptors {
    if entry.material_pipeline_id == material_pipeline_id {
      return Some(entry.descriptor)
    }
  }
  None
}

///|
fn GpuBackend::register_mesh3d_material_pipeline_descriptor(
  self : GpuBackend,
  material_pipeline_id : UInt64,
  descriptor : @render_resource.RenderPipelineDescriptor,
) -> Unit {
  for index in 0..<self.mesh3d_material_pipeline_descriptors.length() {
    let entry = self.mesh3d_material_pipeline_descriptors[index]
    if entry.material_pipeline_id == material_pipeline_id {
      self.mesh3d_material_pipeline_descriptors[index] = Mesh3dRegisteredMaterialPipelineDescriptor::{
        material_pipeline_id,
        descriptor,
      }
      @app.timeline_trace_emit_counter_int(
        "render_3d_material_pipeline_descriptor_updates", 1,
      )
      return
    }
  }
  self.mesh3d_material_pipeline_descriptors.push({
    material_pipeline_id,
    descriptor,
  })
  @app.timeline_trace_emit_counter_int(
    "render_3d_material_pipeline_descriptor_inserts", 1,
  )
}

///|
pub fn register_mesh3d_material_pipeline_descriptor(
  material_pipeline_id~ : UInt64,
  descriptor~ : @render_resource.RenderPipelineDescriptor,
) -> Unit {
  if material_pipeline_id == MESH3D_DEFAULT_MATERIAL_PIPELINE_ID {
    return
  }
  @app.timeline_trace_emit_counter_int(
    "render_3d_material_pipeline_descriptor_registrations", 1,
  )
  if ensure_backend() is Some(backend) {
    backend.register_mesh3d_material_pipeline_descriptor(
      material_pipeline_id, descriptor,
    )
  }
}
