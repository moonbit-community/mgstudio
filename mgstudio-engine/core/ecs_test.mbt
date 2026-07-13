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
test "ecs: Entities generation prevents ABA" {
  let entities = Entities::new()
  let allocator = EntityAllocator::new()
  let e0 = allocator.alloc()
  try! entities.spawn_at(e0)
  debug_inspect(entities.is_alive(e0), content="true")
  let freed = try! entities.despawn(e0)
  allocator.free(freed)
  debug_inspect(entities.is_alive(e0), content="false")

  // Reuse the same id with a bumped generation.
  let e1 = allocator.alloc()
  try! entities.spawn_at(e1)
  debug_inspect(e1.id == e0.id, content="true")
  debug_inspect(e1.generation != e0.generation, content="true")
  debug_inspect(entities.is_alive(e1), content="true")
}

///|
test "ecs: SparseSet insert/get/remove swap-remove" {
  let allocator = EntityAllocator::new()
  let e0 = allocator.alloc()
  let e1 = allocator.alloc()
  let set = SparseSet::new()
  set.insert(e0, 10)
  set.insert(e1, 20)
  debug_inspect(set.len(), content="2")
  debug_inspect(set.get(e0).unwrap(), content="10")
  debug_inspect(set.get(e1).unwrap(), content="20")

  // Removing the first element should keep the set packed.
  debug_inspect(set.remove(e0).unwrap(), content="10")
  debug_inspect(set.len(), content="1")
  debug_inspect(set.contains(e0), content="false")
  debug_inspect(set.contains(e1), content="true")
  debug_inspect(set.get(e1).unwrap(), content="20")
}
