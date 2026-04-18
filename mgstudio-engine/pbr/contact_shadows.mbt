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
const CONTACT_SHADOWS_PLUGIN_NAME : String = "mgstudio.pbr.ContactShadowsPlugin"

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
pub let ecs_key_view_contact_shadows_uniform_offset : @ecs.ComponentKey[
  ViewContactShadowsUniformOffset,
] = @ecs.register_component(
  debug_name="render3d.view_contact_shadows_uniform_offset",
)

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
pub impl @ecs.Component for ViewContactShadowsUniformOffset with component() {
  ecs_key_view_contact_shadows_uniform_offset
}

///|
pub struct ContactShadowsBuffer {
  uniforms : Array[ContactShadowsUniform]
}

///|
let contact_shadows_buffer_resource_key : @ecs.ResourceKey[ContactShadowsBuffer] = @ecs.register_resource(
  debug_name="render3d.contact_shadows_buffer",
)

///|
pub impl @app.Resource for ContactShadowsBuffer with resource() {
  contact_shadows_buffer_resource_key
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
pub struct ContactShadowsPlugin {}

///|
pub fn ContactShadowsPlugin::default() -> ContactShadowsPlugin {
  ContactShadowsPlugin::{  }
}

///|
pub impl @app.Plugin for ContactShadowsPlugin with name(_self) {
  CONTACT_SHADOWS_PLUGIN_NAME
}

///|
fn render3d_prepare_contact_shadows_system_in_render_app(
  world : @ecs.World,
) -> Unit {
  render3d_prepare_contact_shadows_system(world)
}

///|
pub impl @app.Plugin for ContactShadowsPlugin with build(self, app) {
  contact_shadows_plugin_install_with(app, self)
}

///|
pub fn contact_shadows_plugin_install(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  contact_shadows_plugin_install_with(app, ContactShadowsPlugin::default())
}

///|
pub fn contact_shadows_plugin_install_with(
  app : @app.App[@ecs.World],
  _plugin : ContactShadowsPlugin,
) -> @app.App[@ecs.World] {
  let next = app
  @render.with_render_app(next, fn(sub_app : @app.SubApp[@ecs.World]) {
    let world = sub_app.world()
    if (try! world.get_resource(ContactShadowsBuffer::resource())) is None {
      world.insert_resource(
        ContactShadowsBuffer::resource(),
        ContactShadowsBuffer::default(),
      )
    }
    sub_app.add_systems(
      @render.render_schedule_stage(),
      @app.system(render3d_prepare_contact_shadows_system_in_render_app).in_set(
        @render.render_system_set_prepare_resources,
      ),
    )
  })
}

///|
pub fn render3d_contact_shadows_buffer_ref(
  world : @ecs.World,
) -> Ref[ContactShadowsBuffer]? {
  try! world.get_resource_ref_mut(ContactShadowsBuffer::resource())
}

///|
pub fn render3d_contact_shadows_buffer_ref_or_init(
  world : @ecs.World,
) -> Ref[ContactShadowsBuffer] {
  if render3d_contact_shadows_buffer_ref(world) is None {
    world.insert_resource(
      ContactShadowsBuffer::resource(),
      ContactShadowsBuffer::default(),
    )
  }
  match render3d_contact_shadows_buffer_ref(world) {
    Some(buffer) => buffer
    None =>
      abort(
        "contact shadows buffer resource is missing after lazy initialization",
      )
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

///|
pub fn render3d_apply_view_contact_shadows_uniform_offsets(
  world : @ecs.World,
  offsets : Array[(@core.Entity, ViewContactShadowsUniformOffset)],
) -> Unit {
  for entry in offsets {
    let entity = entry.0
    let offset = entry.1
    try! world.set_by_key(
      entity, ecs_key_view_contact_shadows_uniform_offset, offset,
    )
  }
}

///|
pub fn render3d_prepare_contact_shadows_system(world : @ecs.World) -> Unit {
  let source_world = @render.render_source_world(world)
  let sorted_cameras = @render.sorted_cameras_or_default(world)
  let buffer_ref = render3d_contact_shadows_buffer_ref_or_init(world)
  let offsets = render3d_prepare_contact_shadows_settings(
    source_world,
    sorted_cameras.entities,
    buffer_ref.val,
  )
  render3d_apply_view_contact_shadows_uniform_offsets(world, offsets)
}
