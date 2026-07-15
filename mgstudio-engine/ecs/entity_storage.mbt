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
priv struct WorldEntityStorageState {
  archetype_entities : Map[Int, Array[@core.Entity]]
  entity_archetype_ids : Array[Int]
  entity_table_ids : Array[Int]
  entity_table_rows : Array[Int]
  entity_archetype_rows : Array[Int]
}

///|
fn world_entity_storage_state_new() -> WorldEntityStorageState {
  {
    archetype_entities: { 0: [] },
    entity_archetype_ids: [],
    entity_table_ids: [],
    entity_table_rows: [],
    entity_archetype_rows: [],
  }
}
