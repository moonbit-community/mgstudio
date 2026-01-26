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
test "app: run_if skips system execution" {
  let log : Array[Int] = []
  let app = App::new().add_system_config(
    system(fn() { log.push(1) }).run_if(fn() { false }),
  )
  app.run_once() |> ignore
  inspect(log.length(), content="0")
}

///|
test "app: schedule sets order and preserve insertion within a set" {
  let log : Array[Int] = []
  let set_a = system_set("A")
  let set_b = system_set("B")
  let app = App::new()
  app
  .add_system_config(system(fn() { log.push(1) }).in_set(set_a))
  .add_system_config(system(fn() { log.push(2) }).in_set(set_a))
  .add_system_config(system(fn() { log.push(3) }).in_set(set_b))
  .configure_set(Update, set_a, before=[set_b])
  .run_once()
  |> ignore
  inspect(
    log.length() == 3 && log[0] == 1 && log[1] == 2 && log[2] == 3,
    content="true",
  )
}
