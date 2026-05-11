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
  EcsPayload_light_cluster_GlobalClusterSettings(GlobalClusterSettings)
  EcsPayload_light_cluster_ClusterConfig(ClusterConfig)
  EcsPayload_light_cluster_Clusters(Clusters)
  EcsPayload_light_cluster_VisibleClusterableObjects(VisibleClusterableObjects)
  EcsPayload_light_cluster_ClusterCameraProjection(ClusterCameraProjection)
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalClusterSettings with to_ecs_payload(
  self,
) {
  EcsPayload_light_cluster_GlobalClusterSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GlobalClusterSettings with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_cluster_GlobalClusterSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ClusterConfig with to_ecs_payload(self) {
  EcsPayload_light_cluster_ClusterConfig(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ClusterConfig with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_cluster_ClusterConfig(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Clusters with to_ecs_payload(self) {
  EcsPayload_light_cluster_Clusters(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Clusters with from_ecs_payload(payload) {
  match payload {
    EcsPayload_light_cluster_Clusters(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for VisibleClusterableObjects with to_ecs_payload(
  self,
) {
  EcsPayload_light_cluster_VisibleClusterableObjects(self)
}

///|
pub impl @ecs.EcsPayloadCodec for VisibleClusterableObjects with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_cluster_VisibleClusterableObjects(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for ClusterCameraProjection with to_ecs_payload(
  self,
) {
  EcsPayload_light_cluster_ClusterCameraProjection(self)
}

///|
pub impl @ecs.EcsPayloadCodec for ClusterCameraProjection with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_light_cluster_ClusterCameraProjection(value) => Some(value)
    _ => None
  }
}
