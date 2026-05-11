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
  EcsPayload_ldtk_LdtkEntityMap(LdtkEntityMap)
  EcsPayload_ldtk_LdtkIntCellMap(LdtkIntCellMap)
  EcsPayload_ldtk_EntityIid(EntityIid)
  EcsPayload_ldtk_LevelIid(LevelIid)
  EcsPayload_ldtk_LevelSet(LevelSet)
  EcsPayload_ldtk_IntGridCell(IntGridCell)
  EcsPayload_ldtk_Worldly(Worldly)
  EcsPayload_ldtk_GridCoords(GridCoords)
  EcsPayload_ldtk_TileMetadata(TileMetadata)
  EcsPayload_ldtk_TileEnumTags(TileEnumTags)
  EcsPayload_ldtk_LayerMetadata(LayerMetadata)
  EcsPayload_ldtk_Respawn(Respawn)
  EcsPayload_ldtk_LdtkProjectHandle(LdtkProjectHandle)
  EcsPayload_ldtk_LevelSelection(LevelSelection)
  EcsPayload_ldtk_LdtkProject(LdtkProject)
  EcsPayload_ldtk_LdtkSettings(LdtkSettings)
  EcsPayload_ldtk_LdtkRuntimeState(LdtkRuntimeState)
  EcsPayload_ldtk_LdtkSpawnedLevelIids(LdtkSpawnedLevelIids)
  EcsPayload_ldtk_LevelEvent(LevelEvent)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkEntityMap with to_ecs_payload(self) {
  EcsPayload_ldtk_LdtkEntityMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkEntityMap with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LdtkEntityMap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkIntCellMap with to_ecs_payload(self) {
  EcsPayload_ldtk_LdtkIntCellMap(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkIntCellMap with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LdtkIntCellMap(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for EntityIid with to_ecs_payload(self) {
  EcsPayload_ldtk_EntityIid(self)
}

///|
pub impl @ecs.EcsPayloadCodec for EntityIid with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_EntityIid(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LevelIid with to_ecs_payload(self) {
  EcsPayload_ldtk_LevelIid(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LevelIid with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LevelIid(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LevelSet with to_ecs_payload(self) {
  EcsPayload_ldtk_LevelSet(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LevelSet with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LevelSet(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for IntGridCell with to_ecs_payload(self) {
  EcsPayload_ldtk_IntGridCell(self)
}

///|
pub impl @ecs.EcsPayloadCodec for IntGridCell with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_IntGridCell(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Worldly with to_ecs_payload(self) {
  EcsPayload_ldtk_Worldly(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Worldly with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_Worldly(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for GridCoords with to_ecs_payload(self) {
  EcsPayload_ldtk_GridCoords(self)
}

///|
pub impl @ecs.EcsPayloadCodec for GridCoords with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_GridCoords(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TileMetadata with to_ecs_payload(self) {
  EcsPayload_ldtk_TileMetadata(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TileMetadata with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_TileMetadata(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for TileEnumTags with to_ecs_payload(self) {
  EcsPayload_ldtk_TileEnumTags(self)
}

///|
pub impl @ecs.EcsPayloadCodec for TileEnumTags with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_TileEnumTags(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LayerMetadata with to_ecs_payload(self) {
  EcsPayload_ldtk_LayerMetadata(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LayerMetadata with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LayerMetadata(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for Respawn with to_ecs_payload(self) {
  EcsPayload_ldtk_Respawn(self)
}

///|
pub impl @ecs.EcsPayloadCodec for Respawn with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_Respawn(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkProjectHandle with to_ecs_payload(self) {
  EcsPayload_ldtk_LdtkProjectHandle(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkProjectHandle with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ldtk_LdtkProjectHandle(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LevelSelection with to_ecs_payload(self) {
  EcsPayload_ldtk_LevelSelection(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LevelSelection with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LevelSelection(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkProject with to_ecs_payload(self) {
  EcsPayload_ldtk_LdtkProject(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkProject with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LdtkProject(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkSettings with to_ecs_payload(self) {
  EcsPayload_ldtk_LdtkSettings(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkSettings with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LdtkSettings(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkRuntimeState with to_ecs_payload(self) {
  EcsPayload_ldtk_LdtkRuntimeState(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkRuntimeState with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ldtk_LdtkRuntimeState(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkSpawnedLevelIids with to_ecs_payload(self) {
  EcsPayload_ldtk_LdtkSpawnedLevelIids(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LdtkSpawnedLevelIids with from_ecs_payload(
  payload,
) {
  match payload {
    EcsPayload_ldtk_LdtkSpawnedLevelIids(value) => Some(value)
    _ => None
  }
}

///|
pub impl @ecs.EcsPayloadCodec for LevelEvent with to_ecs_payload(self) {
  EcsPayload_ldtk_LevelEvent(self)
}

///|
pub impl @ecs.EcsPayloadCodec for LevelEvent with from_ecs_payload(payload) {
  match payload {
    EcsPayload_ldtk_LevelEvent(value) => Some(value)
    _ => None
  }
}
