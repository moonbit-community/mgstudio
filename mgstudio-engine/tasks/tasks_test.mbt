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
