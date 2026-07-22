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
pub struct RawHandleWrapper {
  window : HostWindow
  window_handle_ : @raw_windowing.WindowHandle
  display_handle_ : @raw_windowing.DisplayHandle
} derive(Debug)

///|
pub fn RawHandleWrapper::new(
  window : HostWindow,
  window_handle : @raw_windowing.WindowHandle,
  display_handle : @raw_windowing.DisplayHandle,
) -> RawHandleWrapper {
  RawHandleWrapper::{
    window,
    window_handle_: window_handle,
    display_handle_: display_handle,
  }
}

///|
pub fn RawHandleWrapper::window(self : RawHandleWrapper) -> HostWindow {
  self.window
}

///|
pub fn RawHandleWrapper::window_handle(
  self : RawHandleWrapper,
) -> @raw_windowing.WindowHandle {
  self.window_handle_
}

///|
pub fn RawHandleWrapper::display_handle(
  self : RawHandleWrapper,
) -> @raw_windowing.DisplayHandle {
  self.display_handle_
}

///|
pub impl @raw_windowing.HasWindowHandle for RawHandleWrapper with fn window_handle(
  self,
) {
  self.window_handle()
}

///|
pub impl @raw_windowing.HasDisplayHandle for RawHandleWrapper with fn display_handle(
  self,
) {
  self.display_handle()
}

///|
pub(all) struct RawHandleWrapperHolder {
  handle : Ref[RawHandleWrapper?]
}

///|
pub fn RawHandleWrapperHolder::new() -> RawHandleWrapperHolder {
  RawHandleWrapperHolder::{ handle: Ref(None) }
}

///|
pub let ecs_key_raw_handle_wrapper : @ecs.ComponentKey[RawHandleWrapper] = @ecs.register_component(
  debug_name="mgstudio_window::RawHandleWrapper",
)

///|
pub let ecs_key_raw_handle_wrapper_holder : @ecs.ComponentKey[
  RawHandleWrapperHolder,
] = @ecs.register_component(
  debug_name="mgstudio_window::RawHandleWrapperHolder",
)

///|
pub impl @ecs.Component for RawHandleWrapper with fn component() {
  ecs_key_raw_handle_wrapper
}

///|
pub impl @ecs.Component for RawHandleWrapperHolder with fn component() {
  ecs_key_raw_handle_wrapper_holder
}
