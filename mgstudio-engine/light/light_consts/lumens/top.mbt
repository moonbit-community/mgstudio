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
// Bevy source: `bevy/crates/bevy_light/src/lib.rs`, `light_consts::lumens`.

///|
/// The conversion factor used to determine how many lumens a typical LED light
/// of a given wattage produces.
pub const LUMENS_PER_LED_WATTS : Float = 90.0F

///|
/// The conversion factor used to determine how many lumens a typical
/// incandescent light of a given wattage produces.
pub const LUMENS_PER_INCANDESCENT_WATTS : Float = 13.8F

///|
/// The conversion factor used to determine how many lumens a typical halogen
/// light of a given wattage produces.
pub const LUMENS_PER_HALOGEN_WATTS : Float = 19.8F

///|
/// A very large cinema light at Bevy's default exposure level.
pub const VERY_LARGE_CINEMA_LIGHT : Float = 1_000_000.0F
