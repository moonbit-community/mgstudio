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
test "tasks boundary re-exports task pool plugin surface" {
  let options = @tasks.TaskPoolOptions::with_num_threads(2)
  let plugin = @tasks.TaskPoolPlugin::new(options)
  let _apply : @app.Plugin[Unit] = @tasks.task_pool_plugin(plugin)
  inspect("ok", content="ok")
}

///|
test "tasks: background channel receives value from worker thread" {
  let channel : (@tasks.BackgroundSender[Int], @tasks.BackgroundReceiver[Int]) = @tasks.background_channel(
    capacity=2,
  )
  let (sender, receiver) = channel
  let task = @tasks.AsyncComputeTaskPool::get().spawn(() => {
    if !sender.try_send(7) {
      abort("background channel should accept the first value")
    }
    11
  })

  inspect(receiver.recv(), content="7")
  inspect(task.get(), content="11")
}

///|
test "tasks: background signal wakes waiting worker thread" {
  let signal = @tasks.BackgroundSignal::new()
  let channel : (
    @tasks.BackgroundSender[String],
    @tasks.BackgroundReceiver[String],
  ) = @tasks.background_channel(capacity=1)
  let (sender, receiver) = channel
  let task = @tasks.AsyncComputeTaskPool::get().spawn(() => {
    signal.wait() |> ignore
    sender.try_send("ready") |> ignore
  })
  task.detach()

  signal.wake()
  inspect(receiver.recv(), content="ready")
}
