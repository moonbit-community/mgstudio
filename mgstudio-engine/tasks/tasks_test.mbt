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
fn single_thread_pool() -> @tasks.TaskPool {
  @tasks.TaskPoolBuilder::new().num_threads(1).build()
}

///|
test "tasks: global pool accessors return initialized pools" {
  let pool = @tasks.AsyncComputeTaskPool::get_or_init(single_thread_pool)
  inspect(@tasks.AsyncComputeTaskPool::try_get() is Some(_), content="true")
  inspect(pool.thread_num(), content="1")
  inspect(@tasks.AsyncComputeTaskPool::get().thread_num(), content="1")
}

///|
async test "tasks: task wait and try_wait follow Bevy-shaped handle semantics" {
  let pool = single_thread_pool()
  let task = pool.spawn(fn() { 11 })

  let value = task.wait()
  inspect(value, content="11")
  inspect(task.is_finished(), content="true")
  inspect(try? task.try_wait(), content="Ok(Some(11))")
}

///|
test "tasks: cancel marks task as cancelled before the worker starts it" {
  let pool = single_thread_pool()
  let release = Ref::new(false)
  let blocker_started = Ref::new(false)
  pool
  .spawn(fn() {
    blocker_started.val = true
    while !release.val {

    }
    0
  })
  .detach()
  while !blocker_started.val {

  }

  let task = pool.spawn(fn() { 99 })
  task.cancel()
  release.val = true
  while !task.is_finished() {

  }
  let wait_result : Result[Int?, @tasks.TaskError] = try? task.try_wait()

  inspect(wait_result, content="Err(TaskCancelled)")
  inspect(task.is_finished(), content="true")
}

///|
test "tasks: detach keeps task running in background" {
  let pool = single_thread_pool()
  let completed = Ref::new(false)
  let task = pool.spawn(fn() {
    completed.val = true
    7
  })

  task.detach()
  while !completed.val {

  }

  inspect(completed.val, content="true")
}

///|
test "tasks: app owns the task pool plugin surface" {
  let options = @app.TaskPoolOptions::with_num_threads(2)
  let plugin = @app.TaskPoolPlugin::new(options)
  let _apply : @app.Plugin[Unit] = @app.task_pool_plugin(plugin)
  inspect("ok", content="ok")
}
