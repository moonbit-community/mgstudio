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
/// Camera contact shadow settings aligned with Bevy's `ContactShadows`.
pub struct ContactShadows {
  linear_steps : Int
  thickness : Float
  length : Float
} derive(ToJson, FromJson)

///|
pub fn ContactShadows::default() -> ContactShadows {
  ContactShadows::{ linear_steps: 16, thickness: 0.1F, length: 0.3F }
}

///|
pub fn ContactShadows::new(
  linear_steps : Int,
  thickness : Float,
  length : Float,
) -> ContactShadows {
  ContactShadows::{
    linear_steps: if linear_steps <= 0 {
      1
    } else {
      linear_steps
    },
    thickness: if thickness < 0.0F {
      0.0F
    } else {
      thickness
    },
    length: if length < 0.0F {
      0.0F
    } else {
      length
    },
  }
}

///|
pub fn ContactShadows::with_linear_steps(
  self : ContactShadows,
  linear_steps : Int,
) -> ContactShadows {
  ContactShadows::new(linear_steps, self.thickness, self.length)
}

///|
pub fn ContactShadows::with_thickness(
  self : ContactShadows,
  thickness : Float,
) -> ContactShadows {
  ContactShadows::new(self.linear_steps, thickness, self.length)
}

///|
pub fn ContactShadows::with_length(
  self : ContactShadows,
  length : Float,
) -> ContactShadows {
  ContactShadows::new(self.linear_steps, self.thickness, length)
}
