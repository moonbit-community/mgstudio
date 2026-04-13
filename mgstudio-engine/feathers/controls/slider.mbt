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
// Bevy source: `bevy/crates/bevy_feathers/src/controls/slider.rs`.

///|
pub struct SliderProps {
  value : Float
  min : Float
  max : Float
}

///|
pub fn SliderProps::default() -> SliderProps {
  SliderProps::{ value: 0.0, min: 0.0, max: 1.0 }
}

///|
pub struct Slider {
  props : SliderProps
}

///|
pub fn slider(props : SliderProps) -> Slider {
  Slider::{ props, }
}

///|
pub struct SliderPlugin {}

///|
pub fn SliderPlugin::default() -> SliderPlugin {
  SliderPlugin::{  }
}

///|
pub fn slider_plugin(app : @app.App[@ecs.World]) -> @app.App[@ecs.World] {
  ensure_controls_runtime(app)
}
