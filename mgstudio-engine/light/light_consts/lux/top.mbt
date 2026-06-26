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
// Bevy source: `bevy/crates/bevy_light/src/lib.rs`, `light_consts::lux`.

///|
/// The amount of light in a moonless, overcast night sky.
pub const MOONLESS_NIGHT : Float = 0.0001F

///|
/// The amount of light during a full moon on a clear night.
pub const FULL_MOON_NIGHT : Float = 0.05F

///|
/// The amount of light during the dark limit of civil twilight under a clear sky.
pub const CIVIL_TWILIGHT : Float = 3.4F

///|
/// The amount of light in family living room lights.
pub const LIVING_ROOM : Float = 50.0F

///|
/// The amount of light in an office building's hallway or toilet lighting.
pub const HALLWAY : Float = 80.0F

///|
/// The amount of light in a very dark overcast day.
pub const DARK_OVERCAST_DAY : Float = 100.0F

///|
/// The amount of light in an office.
pub const OFFICE : Float = 320.0F

///|
/// The amount of light during sunrise or sunset on a clear day.
pub const CLEAR_SUNRISE : Float = 400.0F

///|
/// The amount of light on an overcast day; typical TV studio lighting.
pub const OVERCAST_DAY : Float = 1000.0F

///|
/// The amount of light from ambient daylight, not direct sunlight.
pub const AMBIENT_DAYLIGHT : Float = 10_000.0F

///|
/// The amount of light in full daylight, not direct sun.
pub const FULL_DAYLIGHT : Float = 20_000.0F

///|
/// The amount of light in direct sunlight.
pub const DIRECT_SUNLIGHT : Float = 100_000.0F

///|
/// The amount of raw sunlight, not filtered by the atmosphere.
pub const RAW_SUNLIGHT : Float = 130_000.0F
