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
pub(all) struct WindowWrapper {
  window : HostWindow
} derive(Eq, Show)

///|
pub fn WindowWrapper::new(window : HostWindow) -> WindowWrapper {
  WindowWrapper::{ window, }
}

///|
pub(all) struct RawHandleWrapper {
  window : HostWindow
} derive(Eq, Show)

///|
pub fn RawHandleWrapper::new(window : WindowWrapper) -> RawHandleWrapper {
  RawHandleWrapper::{ window: window.window }
}

///|
pub fn RawHandleWrapper::window(self : RawHandleWrapper) -> HostWindow {
  self.window
}

///|
pub(all) struct RawHandleWrapperHolder {
  handle : Ref[RawHandleWrapper?]
}

///|
pub fn RawHandleWrapperHolder::new() -> RawHandleWrapperHolder {
  RawHandleWrapperHolder::{ handle: Ref::new(None) }
}

///|
pub let ecs_key_raw_handle_wrapper : @ecs.ComponentKey[RawHandleWrapper] = @ecs.register_component(
  debug_name="bevy_window::RawHandleWrapper",
)

///|
pub let ecs_key_raw_handle_wrapper_holder : @ecs.ComponentKey[
  RawHandleWrapperHolder,
] = @ecs.register_component(debug_name="bevy_window::RawHandleWrapperHolder")

///|
pub impl @ecs.Component for RawHandleWrapper with component() {
  ecs_key_raw_handle_wrapper
}

///|
pub impl @ecs.Component for RawHandleWrapperHolder with component() {
  ecs_key_raw_handle_wrapper_holder
}
