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
extenum @ecs.EcsPayload += {
  EcsPayload_sprite_ClearColor(ClearColor)
  EcsPayload_sprite_ColorMaterialAsset(ColorMaterialAsset)
  EcsPayload_sprite_SpriteMaterial(SpriteMaterial)
  EcsPayload_sprite_RenderMaterial2dInstances(RenderMaterial2dInstancesPayload)
  EcsPayload_sprite_Material2dPipeline(Material2dPipelinePayload)
  EcsPayload_sprite_PreparedMaterial2d(PreparedMaterial2dPayload)
  EcsPayload_sprite_MeshMaterial2d(MeshMaterial2dPayload)
  EcsPayload_sprite_GizmoStorage(GizmoStoragePayload)
  EcsPayload_sprite_GizmoConfigStore(GizmoConfigStore)
  EcsPayload_sprite_Material2dRuntimeRegistry(Material2dRuntimeRegistry)
  EcsPayload_sprite_Sprite(Sprite)
  EcsPayload_sprite_SpriteMesh(SpriteMesh)
  EcsPayload_sprite_Anchor(Anchor)
  EcsPayload_sprite_RenderLayers(RenderLayers)
  EcsPayload_sprite_Camera2d(Camera2d)
  EcsPayload_sprite_Camera(Camera)
  EcsPayload_sprite_Projection(Projection)
  EcsPayload_sprite_PanCamera(PanCamera)
  EcsPayload_sprite_RenderTarget(RenderTarget)
  EcsPayload_sprite_ColorMaterial(ColorMaterial)
  EcsPayload_sprite_ScissorRect(ScissorRect)
  EcsPayload_sprite_Wireframe2d(Wireframe2d)
  EcsPayload_sprite_NoWireframe2d(NoWireframe2d)
  EcsPayload_sprite_Wireframe2dColor(Wireframe2dColor)
  EcsPayload_sprite_ClearColorConfig(ClearColorConfig)
  EcsPayload_sprite_TilemapChunk(TilemapChunk)
  EcsPayload_sprite_TilemapChunkTileData(TilemapChunkTileData)
  EcsPayload_sprite_RenderState(RenderState)
  EcsPayload_sprite_Wireframe2dConfig(Wireframe2dConfig)
}

///|
pub(all) struct RenderMaterial2dInstancesPayload {
  instances : Array[((Int, Int), Int)]
}

///|
pub(all) struct Material2dPipelinePayload {
  vertex_shader : String?
  fragment_shader : String?
}

///|
pub(all) struct PreparedMaterial2dPayload {
  source : Int
  bind_group : Material2dBindGroup
  host_bind_group : @render.HostMaterial2dBindGroup
  key_mesh : Int
  key_layout : String
  key_data : String
  properties : Material2dProperties
}

///|
pub(all) struct MeshMaterial2dPayload {
  handle : Int
}

///|
pub(all) struct GizmoStoragePayload {
  state : GizmoState
}

///|
pub impl @ecs.EcsPayloadCodec for ColorMaterialAsset with to_ecs_payload(self) {
  EcsPayload_sprite_ColorMaterialAsset(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColorMaterialAsset with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_ColorMaterialAsset(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpriteMaterial with to_ecs_payload(self) {
  EcsPayload_sprite_SpriteMaterial(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpriteMaterial with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_SpriteMaterial(value) => Some(value)
    _ => None
  }
}

///|
pub impl[M] @ecs.EcsPayloadCodec for RenderMaterial2dInstances[M] with to_ecs_payload(
  self,
) {
  let instances : Array[((Int, Int), Int)] = []
  for entry in self.instances.to_array() {
    instances.push((entry.0, entry.1.id()))
  }
  EcsPayload_sprite_RenderMaterial2dInstances(RenderMaterial2dInstancesPayload::{
    instances,
  })
}

///|
pub impl[M] @ecs.EcsPayloadCodec for RenderMaterial2dInstances[M] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_RenderMaterial2dInstances(value) => {
      let instances : RenderMaterial2dInstances[M] = RenderMaterial2dInstances::new()
      for entry in value.instances {
        instances.instances.set(entry.0, @asset.Handle::new(entry.1))
      }
      Some(instances)
    }
    _ => None
  }
}

///|
pub impl[M] @ecs.EcsPayloadCodec for Material2dPipeline[M] with to_ecs_payload(
  self,
) {
  EcsPayload_sprite_Material2dPipeline(Material2dPipelinePayload::{
    vertex_shader: self.vertex_shader,
    fragment_shader: self.fragment_shader,
  })
}

///|
pub impl[M] @ecs.EcsPayloadCodec for Material2dPipeline[M] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_Material2dPipeline(value) =>
      Some(Material2dPipeline::{
        vertex_shader: value.vertex_shader,
        fragment_shader: value.fragment_shader,
      })
    _ => None
  }
}

///|
pub impl[M] @ecs.EcsPayloadCodec for PreparedMaterial2d[M] with to_ecs_payload(
  self,
) {
  EcsPayload_sprite_PreparedMaterial2d(PreparedMaterial2dPayload::{
    source: self.source.id(),
    bind_group: self.bind_group,
    host_bind_group: self.host_bind_group,
    key_mesh: self.key.mesh_key,
    key_layout: self.key.bind_group_layout_key,
    key_data: self.key.bind_group_data,
    properties: self.properties,
  })
}

///|
pub impl[M] @ecs.EcsPayloadCodec for PreparedMaterial2d[M] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_PreparedMaterial2d(value) =>
      Some(PreparedMaterial2d::{
        source: @asset.Handle::new(value.source),
        bind_group: value.bind_group,
        host_bind_group: value.host_bind_group,
        key: Material2dKey::new(
          value.key_mesh,
          value.key_layout,
          value.key_data,
        ),
        properties: value.properties,
      })
    _ => None
  }
}

///|
pub impl[M] @ecs.EcsPayloadCodec for MeshMaterial2d[M] with to_ecs_payload(self) {
  EcsPayload_sprite_MeshMaterial2d(MeshMaterial2dPayload::{
    handle: self.handle.id(),
  })
}

///|
pub impl[M] @ecs.EcsPayloadCodec for MeshMaterial2d[M] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_MeshMaterial2d(value) =>
      Some(MeshMaterial2d::{ handle: @asset.Handle::new(value.handle) })
    _ => None
  }
}

///|
pub impl[Config] @ecs.EcsPayloadCodec for GizmoStorage[Config] with to_ecs_payload(
  self,
) {
  EcsPayload_sprite_GizmoStorage(GizmoStoragePayload::{ state: self.state })
}

///|
pub impl[Config] @ecs.EcsPayloadCodec for GizmoStorage[Config] with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_GizmoStorage(value) =>
      Some(GizmoStorage::{ state: value.state, phantom: None })
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ClearColor with to_ecs_payload(self) {
  EcsPayload_sprite_ClearColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ClearColor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_ClearColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GizmoConfigStore with to_ecs_payload(self) {
  EcsPayload_sprite_GizmoConfigStore(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GizmoConfigStore with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_GizmoConfigStore(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Material2dRuntimeRegistry with to_ecs_payload(
  self,
) {
  EcsPayload_sprite_Material2dRuntimeRegistry(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Material2dRuntimeRegistry with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_Material2dRuntimeRegistry(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Sprite with to_ecs_payload(self) {
  EcsPayload_sprite_Sprite(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Sprite with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_Sprite(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for SpriteMesh with to_ecs_payload(self) {
  EcsPayload_sprite_SpriteMesh(self)
}

///|
pub impl @ecs.EcsPayloadCodec for SpriteMesh with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_SpriteMesh(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Anchor with to_ecs_payload(self) {
  EcsPayload_sprite_Anchor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Anchor with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_Anchor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderLayers with to_ecs_payload(self) {
  EcsPayload_sprite_RenderLayers(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderLayers with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_RenderLayers(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Camera2d with to_ecs_payload(self) {
  EcsPayload_sprite_Camera2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Camera2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_Camera2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Camera with to_ecs_payload(self) {
  EcsPayload_sprite_Camera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Camera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_Camera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Projection with to_ecs_payload(self) {
  EcsPayload_sprite_Projection(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Projection with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_Projection(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for PanCamera with to_ecs_payload(self) {
  EcsPayload_sprite_PanCamera(self)
}

///|
pub impl @ecs.EcsPayloadCodec for PanCamera with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_PanCamera(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderTarget with to_ecs_payload(self) {
  EcsPayload_sprite_RenderTarget(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderTarget with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_RenderTarget(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ColorMaterial with to_ecs_payload(self) {
  EcsPayload_sprite_ColorMaterial(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ColorMaterial with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_ColorMaterial(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ScissorRect with to_ecs_payload(self) {
  EcsPayload_sprite_ScissorRect(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ScissorRect with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_ScissorRect(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe2d with to_ecs_payload(self) {
  EcsPayload_sprite_Wireframe2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_Wireframe2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for NoWireframe2d with to_ecs_payload(self) {
  EcsPayload_sprite_NoWireframe2d(self)
}

///|
pub impl @ecs.EcsPayloadCodec for NoWireframe2d with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_NoWireframe2d(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe2dColor with to_ecs_payload(self) {
  EcsPayload_sprite_Wireframe2dColor(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe2dColor with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_Wireframe2dColor(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ClearColorConfig with to_ecs_payload(self) {
  EcsPayload_sprite_ClearColorConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ClearColorConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_ClearColorConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TilemapChunk with to_ecs_payload(self) {
  EcsPayload_sprite_TilemapChunk(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TilemapChunk with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_TilemapChunk(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TilemapChunkTileData with to_ecs_payload(self) {
  EcsPayload_sprite_TilemapChunkTileData(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TilemapChunkTileData with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_TilemapChunkTileData(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for RenderState with to_ecs_payload(self) {
  EcsPayload_sprite_RenderState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for RenderState with from_ecs_payload(payload) {
  match payload {
    EcsPayload_sprite_RenderState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe2dConfig with to_ecs_payload(self) {
  EcsPayload_sprite_Wireframe2dConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Wireframe2dConfig with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_sprite_Wireframe2dConfig(value) => Some(value)
    _ => None
  }
}
