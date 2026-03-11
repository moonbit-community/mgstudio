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
priv struct RuntimeState {
  mut close_requested : Bool
  stdin_line : String?
}

///|
let runtime_state_ref : Ref[RuntimeState] = Ref::new(RuntimeState::{
  close_requested: false,
  stdin_line: None,
})

///|
fn host_app_run_loop(step : FuncRef[() -> Unit], interval_ms~ : Int) -> Unit {
  interval_ms |> ignore
  let mut safety_limit = 0
  while !runtime_state_ref.val.close_requested && safety_limit < 1000000 {
    step()
    safety_limit = safety_limit + 1
  }
}

///|
fn host_app_request_close() -> Unit {
  runtime_state_ref.val.close_requested = true
}

///|
fn host_app_reset_close() -> Unit {
  runtime_state_ref.val.close_requested = false
}

///|
fn host_app_stdin_read_line_len() -> Int {
  match runtime_state_ref.val.stdin_line {
    Some(line) => line.length()
    None => -1
  }
}

///|
fn host_app_stdin_read_line_code_unit(offset~ : Int) -> Int {
  match runtime_state_ref.val.stdin_line {
    Some(line) =>
      if offset < 0 || offset >= line.length() {
        0
      } else {
        line.code_unit_at(offset).to_int()
      }
    None => 0
  }
}

///|
fn host_task_pool_set_num_threads(num_threads~ : Int) -> Unit {
  num_threads |> ignore
}
