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
test "sync_world: MainEntity preserves the source-owner newtype boundary" {
  let entity = @core.Entity::new(17, 3)
  let main_entity = MainEntity::new(entity)
  debug_inspect(main_entity.id(), content="{ id: 17, generation: 3 }")
  debug_inspect(
    MainEntity::component().id() == ecs_key_main_entity.id(),
    content="true",
  )
}
