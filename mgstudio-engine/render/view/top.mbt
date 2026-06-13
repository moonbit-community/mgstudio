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
// Bevy source: `bevy/crates/bevy_render/src/view/mod.rs`.

///|
// Bevy source: `bevy/crates/bevy_render/src/view/mod.rs`.
pub(all) enum Msaa {
  Off
  Sample2
  Sample4
  Sample8
} derive(Eq, Debug, ToJson, FromJson)

///|
pub fn Msaa::default() -> Msaa {
  Msaa::Sample4
}

///|
pub fn Msaa::samples(self : Msaa) -> Int {
  match self {
    Off => 1
    Sample2 => 2
    Sample4 => 4
    Sample8 => 8
  }
}

///|
pub fn Msaa::from_samples(samples : Int) -> Msaa {
  match samples {
    1 => Msaa::Off
    2 => Msaa::Sample2
    4 => Msaa::Sample4
    8 => Msaa::Sample8
    _ => abort("Unsupported MSAA sample count: \{samples}")
  }
}

///|
pub let ecs_key_msaa : @ecs.ComponentKey[Msaa] = @ecs.register_component(
  debug_name="render.view.msaa",
)

///|
pub impl @ecs.Component for Msaa with fn component() {
  ecs_key_msaa
}

///|
pub struct RetainedViewEntity {
  main_entity : @core.Entity
  auxiliary_entity : @core.Entity
  subview_index : Int
} derive(Eq, Debug)

///|
pub fn RetainedViewEntity::new(
  main_entity : @core.Entity,
  auxiliary_entity? : @core.Entity? = None,
  subview_index? : Int = 0,
) -> RetainedViewEntity {
  RetainedViewEntity::{
    main_entity,
    auxiliary_entity: auxiliary_entity.unwrap_or(@core.Entity::placeholder()),
    subview_index,
  }
}

///|
pub fn RetainedViewEntity::main_entity(
  self : RetainedViewEntity,
) -> @core.Entity {
  self.main_entity
}

///|
pub fn RetainedViewEntity::auxiliary_entity(
  self : RetainedViewEntity,
) -> @core.Entity {
  self.auxiliary_entity
}

///|
pub fn RetainedViewEntity::subview_index(self : RetainedViewEntity) -> Int {
  self.subview_index
}

///|
pub fn retained_view_entity_equals(
  lhs : RetainedViewEntity,
  rhs : RetainedViewEntity,
) -> Bool {
  lhs.main_entity == rhs.main_entity &&
  lhs.auxiliary_entity == rhs.auxiliary_entity &&
  lhs.subview_index == rhs.subview_index
}

///|
pub fn retained_view_entity_contains(
  views : Array[RetainedViewEntity],
  view : RetainedViewEntity,
) -> Bool {
  for current in views {
    if retained_view_entity_equals(current, view) {
      return true
    }
  }
  false
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs::normalize_bgra8`.
pub fn normalize_bgra8_for_render_target(
  target_is_window~ : Bool,
  format_raw : UInt,
) -> UInt {
  if target_is_window && format_raw == @wgpu.TEXTURE_FORMAT_BGRA8_UNORM_SRGB {
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB
  } else {
    format_raw
  }
}

///|
// Bevy source: `bevy/crates/bevy_render/src/camera.rs::extract_cameras`.
pub fn extracted_view_target_format_raw(
  output_texture_format_raw? : UInt = @wgpu.TEXTURE_FORMAT_RGBA8_UNORM_SRGB,
  hdr? : Bool = false,
  compositing_space? : @camera_compositing_space.CompositingSpace? = None,
) -> UInt {
  if hdr {
    @wgpu.TEXTURE_FORMAT_RGBA16_FLOAT
  } else {
    match compositing_space {
      Some(@camera_compositing_space.CompositingSpace::Srgb) =>
        @wgpu.TEXTURE_FORMAT_RGBA8_UNORM
      _ => output_texture_format_raw
    }
  }
}

///|
pub fn view_visibility_range_always_visible() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::always_visible()
}

///|
pub fn view_visibility_range_invisible() -> @visibility.VisibilityRange {
  @visibility.VisibilityRange::invisible()
}
