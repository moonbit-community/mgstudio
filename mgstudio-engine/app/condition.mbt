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
pub fn[S : States] state_exists(state : S) -> RunConditionFn[@ecs.World] {
  fn(world : @ecs.World) { world_state(world, state) is Some(_) }
}

///|
pub fn[W] run_condition_and(
  left : RunConditionFn[W],
  right : RunConditionFn[W],
) -> RunConditionFn[W] {
  fn(world : W) { left(world) && right(world) }
}

///|
pub fn[W] run_condition_or(
  left : RunConditionFn[W],
  right : RunConditionFn[W],
) -> RunConditionFn[W] {
  fn(world : W) { left(world) || right(world) }
}

///|
pub fn[W] run_condition_not(cond : RunConditionFn[W]) -> RunConditionFn[W] {
  fn(world : W) { !cond(world) }
}

///|
pub fn[T] resource_exists(
  key : @ecs.ResourceKey[T],
) -> RunConditionFn[@ecs.World] {
  fn(world : @ecs.World) { world.resource(key).is_present() }
}

///|
pub fn[T] resource_added(
  key : @ecs.ResourceKey[T],
) -> RunConditionFn[@ecs.World] {
  resource_exists(key)
}

///|
pub fn[T] resource_changed(
  key : @ecs.ResourceKey[T],
) -> RunConditionFn[@ecs.World] {
  resource_exists(key)
}

///|
pub fn[T] resource_exists_and_changed(
  key : @ecs.ResourceKey[T],
) -> RunConditionFn[@ecs.World] {
  resource_exists(key)
}

///|
pub fn[S : States] in_state(state : S) -> RunConditionFn[@ecs.World] {
  fn(world : @ecs.World) {
    match world_state(world, state) {
      Some(current) => current.get() == state
      None => false
    }
  }
}

///|
pub fn[S : States] state_changed(state : S) -> RunConditionFn[@ecs.World] {
  let key = state_resource_key(state)
  let previous = Ref::new(None)
  fn(world : @ecs.World) {
    match world_state(world, state) {
      Some(current) => {
        let changed = match previous.val {
          Some(last) => last != current.get()
          None => true
        }
        previous.val = Some(current.get())
        changed
      }
      None => {
        ignore(key)
        false
      }
    }
  }
}
