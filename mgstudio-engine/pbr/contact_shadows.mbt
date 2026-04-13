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

///|
pub struct ContactShadowsUniform {
  linear_steps : UInt
  thickness : Float
  length : Float
} derive(ToJson, FromJson)

///|
pub fn ContactShadowsUniform::default() -> ContactShadowsUniform {
  ContactShadowsUniform::{ linear_steps: 0U, thickness: 0.0F, length: 0.0F }
}

///|
pub fn ContactShadowsUniform::from_settings(
  settings : ContactShadows,
) -> ContactShadowsUniform {
  ContactShadowsUniform::{
    linear_steps: if settings.linear_steps <= 0 {
      0U
    } else {
      settings.linear_steps.reinterpret_as_uint()
    },
    thickness: if settings.thickness < 0.0F {
      0.0F
    } else {
      settings.thickness
    },
    length: if settings.length < 0.0F {
      0.0F
    } else {
      settings.length
    },
  }
}

///|
pub fn ContactShadowsUniform::disabled() -> ContactShadowsUniform {
  ContactShadowsUniform::default()
}

///|
pub fn ContactShadowsUniform::linear_steps(
  self : ContactShadowsUniform,
) -> UInt {
  self.linear_steps
}

///|
pub fn ContactShadowsUniform::thickness(self : ContactShadowsUniform) -> Float {
  self.thickness
}

///|
pub fn ContactShadowsUniform::length(self : ContactShadowsUniform) -> Float {
  self.length
}

///|
pub struct ViewContactShadowsUniformOffset {
  offset : UInt
} derive(ToJson, FromJson)

///|
pub fn ViewContactShadowsUniformOffset::new(
  offset : UInt,
) -> ViewContactShadowsUniformOffset {
  ViewContactShadowsUniformOffset::{ offset, }
}

///|
pub fn ViewContactShadowsUniformOffset::offset(
  self : ViewContactShadowsUniformOffset,
) -> UInt {
  self.offset
}

///|
pub struct ContactShadowsBuffer {
  uniforms : Array[ContactShadowsUniform]
}

///|
pub fn ContactShadowsBuffer::default() -> ContactShadowsBuffer {
  ContactShadowsBuffer::{ uniforms: [] }
}

///|
pub fn ContactShadowsBuffer::clear(self : ContactShadowsBuffer) -> Unit {
  self.uniforms.clear()
}

///|
pub fn ContactShadowsBuffer::push(
  self : ContactShadowsBuffer,
  uniform : ContactShadowsUniform,
) -> UInt {
  let offset = self.uniforms.length().reinterpret_as_uint()
  self.uniforms.push(uniform)
  offset
}

///|
pub fn ContactShadowsBuffer::len(self : ContactShadowsBuffer) -> Int {
  self.uniforms.length()
}

///|
pub fn ContactShadowsBuffer::uniform_at(
  self : ContactShadowsBuffer,
  offset : UInt,
) -> ContactShadowsUniform? {
  let index = offset.reinterpret_as_int()
  if index < 0 || index >= self.uniforms.length() {
    None
  } else {
    Some(self.uniforms[index])
  }
}

///|
pub fn render3d_prepare_contact_shadows_settings(
  world : @ecs.World,
  view_entities : Array[@core.Entity],
  buffer : ContactShadowsBuffer,
) -> Array[(@core.Entity, ViewContactShadowsUniformOffset)] {
  buffer.clear()
  let offsets = []
  for entity in view_entities {
    let maybe_settings = try! world.get_by_key(entity, ecs_key_contact_shadows)
    let uniform = match maybe_settings {
      Some(settings) => ContactShadowsUniform::from_settings(settings)
      None => ContactShadowsUniform::disabled()
    }
    let offset = buffer.push(uniform)
    offsets.push((entity, ViewContactShadowsUniformOffset::new(offset)))
  }
  offsets
}
