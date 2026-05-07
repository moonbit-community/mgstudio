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
// Bevy source: `bevy/crates/bevy_app/src/terminal_ctrl_c_handler.rs`.

///|
pub struct TerminalCtrlCHandlerPlugin {}

///|
const TERMINAL_CTRL_C_EXIT_CODE : Int = 130

///|
let terminal_ctrl_c_close_count_ref : Ref[Int] = Ref(0)

///|
pub fn TerminalCtrlCHandlerPlugin::default() -> TerminalCtrlCHandlerPlugin {
  TerminalCtrlCHandlerPlugin::{  }
}

///|
pub fn terminal_ctrl_c_gracefully_exit() -> Unit {
  terminal_ctrl_c_close_count_ref.val = terminal_ctrl_c_close_count_ref.val + 1
  host_app_request_close()
}

///|
pub fn terminal_ctrl_c_exit_on_flag(world : @ecs.World) -> Unit {
  if terminal_ctrl_c_close_count_ref.val <= 0 {
    return
  }
  let key = app_exit_message_key()
  if !world.contains_message(key) {
    world.init_message(key)
  }
  ignore(world.send_message(key, AppExit::from_code(TERMINAL_CTRL_C_EXIT_CODE)))
}

///|
pub fn terminal_ctrl_c_handler_plugin(app : App[@ecs.World]) -> App[@ecs.World] {
  app.add_systems(Update, system(terminal_ctrl_c_exit_on_flag))
}

///|
pub fn terminal_ctrl_c_request_close() -> Unit {
  terminal_ctrl_c_gracefully_exit()
}

///|
pub fn terminal_ctrl_c_reset() -> Unit {
  terminal_ctrl_c_close_count_ref.val = 0
  host_app_reset_close()
}

///|
pub fn terminal_ctrl_c_request_close_and_reset() -> Unit {
  terminal_ctrl_c_gracefully_exit()
  host_app_reset_close()
  terminal_ctrl_c_close_count_ref.val = 0
}
