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
// Bevy source: `bevy/crates/bevy_pbr/src/render/light.rs`.
// This is the mgstudio-side shadow-view model used while migrating manual
// shadow execution toward Bevy's per-shadow-view `Shadow` render phases.

///|
priv enum Render3dLightEntity {
  Directional(light_entity~ : @core.Entity, cascade_index~ : Int)
  Point(light_entity~ : @core.Entity, face_index~ : Int)
}

///|
priv struct Render3dShadowView {
  target_id : Int
  target_layer : Int
  width : Int
  height : Int
  transform : @transform.Transform
  projection : @pbr_render.Render3dPassProjection
  clip_from_world : @pbr_render.ProjectionMatrix3d?
  light_entity : Render3dLightEntity
  pass_name : String
}

///|
priv struct Render3dPointShadowBinding {
  texture_id : Int
  enabled : Float
  depth_bias : Float
}

///|
priv struct Render3dDirectionalShadowBinding {
  texture_id : Int
  enabled : Float
  cascade_data : Array[Float]
  cascade_count : Int
}

///|
priv struct Render3dViewShadowBindings {
  point : Render3dPointShadowBinding
  directional : Render3dDirectionalShadowBinding
}

///|
fn render3d_point_shadow_binding_none() -> Render3dPointShadowBinding {
  { texture_id: -1, enabled: 0.0F, depth_bias: 0.0F }
}

///|
fn render3d_directional_shadow_binding_none() -> Render3dDirectionalShadowBinding {
  { texture_id: -1, enabled: 0.0F, cascade_data: [], cascade_count: 0 }
}

///|
fn render3d_view_shadow_bindings_none() -> Render3dViewShadowBindings {
  {
    point: render3d_point_shadow_binding_none(),
    directional: render3d_directional_shadow_binding_none(),
  }
}

///|
fn render3d_shadow_light_entity_debug_key(entity : Render3dLightEntity) -> Int {
  match entity {
    Directional(light_entity~, cascade_index~) =>
      light_entity.id * 31 + light_entity.generation * 17 + cascade_index
    Point(light_entity~, face_index~) =>
      light_entity.id * 31 + light_entity.generation * 17 + face_index
  }
}

///|
fn render3d_shadow_view_begin_pass(
  shadow_view : Render3dShadowView,
  lighting : Render3dLightingState,
  pass_kind : Int,
  point_shadow_near : Float,
) -> Unit {
  ignore(render3d_shadow_light_entity_debug_key(shadow_view.light_entity))
  ignore(shadow_view.pass_name)
  @pbr_render.render3d_begin_pass_3d(
    target_id=shadow_view.target_id,
    target_layer=shadow_view.target_layer,
    width=shadow_view.width,
    height=shadow_view.height,
    clear_r=1.0F,
    clear_g=1.0F,
    clear_b=1.0F,
    clear_a=1.0F,
    shadow_view.transform,
    shadow_view.projection,
    viewport_x=0,
    viewport_y=0,
    viewport_width=shadow_view.width,
    viewport_height=shadow_view.height,
    lighting,
    previous_clip_from_world=None,
    point_shadow_near~,
    clip_from_world_override=shadow_view.clip_from_world,
    pass_kind~,
    clear_enabled=1,
  )
}
