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
// Bevy source: `bevy/crates/bevy_dev_tools/src/ci_testing/config.rs`.

///|
pub struct CiTestingSetup {
  fixed_frame_time : @core.Duration?
}

///|
pub fn CiTestingSetup::default() -> CiTestingSetup {
  CiTestingSetup::{ fixed_frame_time: None }
}

///|
pub fn CiTestingSetup::with_fixed_frame_time(
  self : CiTestingSetup,
  fixed_frame_time : @core.Duration,
) -> CiTestingSetup {
  self |> ignore
  CiTestingSetup::{ fixed_frame_time: Some(fixed_frame_time) }
}

///|
pub(all) enum CiTestingEvent {
  Screenshot
  ScreenshotAndExit
  NamedScreenshot(String)
  AppExit
  MoveCamera(@math.Vec3, @math.Quat)
  Custom(String)
}

///|
pub struct CiTestingEventOnFrame {
  frame : Int
  event : CiTestingEvent
}

///|
pub fn CiTestingEventOnFrame::new(
  frame : Int,
  event : CiTestingEvent,
) -> CiTestingEventOnFrame {
  CiTestingEventOnFrame::{ frame, event }
}

///|
pub struct CiTestingConfig {
  setup : CiTestingSetup
  mut events : Array[CiTestingEventOnFrame]
}

///|
pub fn CiTestingConfig::default() -> CiTestingConfig {
  CiTestingConfig::{ setup: CiTestingSetup::default(), events: [] }
}

///|
pub fn CiTestingConfig::with_setup(
  self : CiTestingConfig,
  setup : CiTestingSetup,
) -> CiTestingConfig {
  CiTestingConfig::{ ..self, setup, }
}

///|
pub fn CiTestingConfig::with_event(
  self : CiTestingConfig,
  frame : Int,
  event : CiTestingEvent,
) -> CiTestingConfig {
  let events = self.events
  events.push(CiTestingEventOnFrame::new(frame, event))
  CiTestingConfig::{ ..self, events, }
}

///|
pub struct CiTestingCustomEvent {
  value : String
}

///|
pub fn CiTestingCustomEvent::new(value : String) -> CiTestingCustomEvent {
  CiTestingCustomEvent::{ value, }
}

///|
pub fn CiTestingCustomEvent::value(self : CiTestingCustomEvent) -> String {
  self.value
}

///|
let ci_testing_config_resource_key : @ecs.ResourceKey[CiTestingConfig] = @ecs.register_resource(
  debug_name="mgstudio_dev_tools::CiTestingConfig",
)

///|
let ci_testing_custom_event_message_key : @ecs.MessageKey[CiTestingCustomEvent] = @ecs.register_message(
  debug_name="mgstudio_dev_tools::CiTestingCustomEvent",
)

///|
pub impl @app.Resource for CiTestingConfig with resource() {
  ci_testing_config_resource_key
}

///|
pub impl @ecs.Message for CiTestingCustomEvent with message() {
  ci_testing_custom_event_message_key
}
