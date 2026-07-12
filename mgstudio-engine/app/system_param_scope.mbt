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
pub struct SystemParamScope {
  priv world_id : Int
  priv epoch : Int
  priv mut active : Bool
  priv lease : @ecs.WorldLease
}

///|
fn SystemParamScope::new(world : @ecs.World) -> SystemParamScope {
  {
    world_id: world.world_id(),
    epoch: world.lifecycle_epoch(),
    active: true,
    lease: @ecs.WorldLease::new(world),
  }
}

///|
pub fn SystemParamScope::is_active(self : SystemParamScope) -> Bool {
  self.active && self.lease.is_active()
}

///|
pub fn SystemParamScope::world_or_abort(self : SystemParamScope) -> @ecs.World {
  guard self.active else {
    abort("system parameter used outside its active system invocation")
  }
  let world = self.lease.world_or_abort()
  guard world.world_id() == self.world_id &&
    world.lifecycle_epoch() == self.epoch else {
    abort("system parameter World lifecycle changed during its invocation")
  }
  world
}

///|
pub fn SystemParamScope::world_lease(
  self : SystemParamScope,
) -> @ecs.WorldLease {
  self.lease
}

///|
fn SystemParamScope::invalidate(self : SystemParamScope) -> Unit {
  guard self.active else { return }
  self.active = false
  self.lease.invalidate()
}

///|
fn current_system_param_scope_or_abort() -> SystemParamScope {
  match app_execution_context_state.current_system_param_scope {
    Some(scope) => scope
    None => abort("Missing current SystemParamScope")
  }
}

///|
fn[R] with_system_param_scope(world : @ecs.World, run : () -> R) -> R {
  let previous = app_execution_context_state.current_system_param_scope
  let scope = SystemParamScope::new(world)
  app_execution_context_state.current_system_param_scope = Some(scope)
  defer {
    scope.invalidate()
    app_execution_context_state.current_system_param_scope = previous
  }
  run()
}
