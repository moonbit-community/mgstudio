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

// Bevy source: `bevy/crates/bevy_tasks/src/usages.rs`.

///|
pub struct AsyncComputeTaskPool {
  pool : TaskPool
}

///|
pub struct ComputeTaskPool {
  pool : TaskPool
}

///|
pub struct IoTaskPool {
  pool : TaskPool
}

///|
priv struct TaskPoolRuntimeState {
  mut compute_task_pool : ComputeTaskPool?
  mut async_compute_task_pool : AsyncComputeTaskPool?
  mut io_task_pool : IoTaskPool?
}

///|
let task_pool_runtime_state : TaskPoolRuntimeState = {
  compute_task_pool: None,
  async_compute_task_pool: None,
  io_task_pool: None,
}

///|
pub fn ComputeTaskPool::get_or_init(init : () -> TaskPool) -> ComputeTaskPool {
  if task_pool_runtime_state.compute_task_pool is None {
    task_pool_runtime_state.compute_task_pool = Some({ pool: init() })
  }
  task_pool_runtime_state.compute_task_pool.unwrap()
}

///|
pub fn ComputeTaskPool::try_get() -> ComputeTaskPool? {
  task_pool_runtime_state.compute_task_pool
}

///|
pub fn ComputeTaskPool::get() -> ComputeTaskPool {
  match task_pool_runtime_state.compute_task_pool {
    Some(pool) => pool
    None => abort("ComputeTaskPool is not initialized")
  }
}

///|
pub fn ComputeTaskPool::task_pool(self : ComputeTaskPool) -> TaskPool {
  self.pool
}

///|
pub fn AsyncComputeTaskPool::get_or_init(
  init : () -> TaskPool,
) -> AsyncComputeTaskPool {
  if task_pool_runtime_state.async_compute_task_pool is None {
    task_pool_runtime_state.async_compute_task_pool = Some({ pool: init() })
  }
  task_pool_runtime_state.async_compute_task_pool.unwrap()
}

///|
pub fn AsyncComputeTaskPool::try_get() -> AsyncComputeTaskPool? {
  task_pool_runtime_state.async_compute_task_pool
}

///|
pub fn AsyncComputeTaskPool::get() -> AsyncComputeTaskPool {
  match task_pool_runtime_state.async_compute_task_pool {
    Some(pool) => pool
    None => abort("AsyncComputeTaskPool is not initialized")
  }
}

///|
pub fn AsyncComputeTaskPool::task_pool(self : AsyncComputeTaskPool) -> TaskPool {
  self.pool
}

///|
pub fn IoTaskPool::get_or_init(init : () -> TaskPool) -> IoTaskPool {
  if task_pool_runtime_state.io_task_pool is None {
    task_pool_runtime_state.io_task_pool = Some({ pool: init() })
  }
  task_pool_runtime_state.io_task_pool.unwrap()
}

///|
pub fn IoTaskPool::try_get() -> IoTaskPool? {
  task_pool_runtime_state.io_task_pool
}

///|
pub fn IoTaskPool::get() -> IoTaskPool {
  match task_pool_runtime_state.io_task_pool {
    Some(pool) => pool
    None => abort("IoTaskPool is not initialized")
  }
}

///|
pub fn IoTaskPool::task_pool(self : IoTaskPool) -> TaskPool {
  self.pool
}

///|
pub fn tick_global_task_pools_on_main_thread() -> Unit {
  ignore(ComputeTaskPool::try_get())
  ignore(AsyncComputeTaskPool::try_get())
  ignore(IoTaskPool::try_get())
}
