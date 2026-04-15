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
// Bevy source: `bevy/crates/bevy_render/src/occlusion_culling/mod.rs`.

///|
const OCCLUSION_CULLING_PLUGIN_NAME : String = "mgstudio.render.occlusion_culling.OcclusionCullingPlugin"

///|
pub struct OcclusionCullingPlugin {}

///|
pub fn OcclusionCullingPlugin::default() -> OcclusionCullingPlugin {
  OcclusionCullingPlugin::{  }
}

///|
pub fn occlusion_culling_plugin(
  app : @app.App[@ecs.World],
) -> @app.App[@ecs.World] {
  occlusion_culling_plugin_with(app, OcclusionCullingPlugin::default())
}

///|
pub impl @app.Plugin for OcclusionCullingPlugin with name(_self) {
  OCCLUSION_CULLING_PLUGIN_NAME
}

///|
pub impl @app.Plugin for OcclusionCullingPlugin with build(self, app) {
  occlusion_culling_plugin_with(app, self)
}

///|
pub fn occlusion_culling_plugin_with(
  app : @app.App[@ecs.World],
  plugin : OcclusionCullingPlugin,
) -> @app.App[@ecs.World] {
  ignore(plugin)
  app
}

///|
pub struct OcclusionCulling {} derive(Eq, Debug)

///|
pub fn OcclusionCulling::default() -> OcclusionCulling {
  OcclusionCulling::{  }
}

///|
pub let ecs_key_occlusion_culling : @ecs.ComponentKey[OcclusionCulling] = @ecs.register_component(
  debug_name="render.occlusion_culling",
)

///|
pub impl @ecs.Component for OcclusionCulling with component() {
  ecs_key_occlusion_culling
}

///|
pub struct OcclusionCullingSubview {
  depth_texture_view_id : Int
  depth_texture_size : Int
} derive(Eq, Debug)

///|
pub fn OcclusionCullingSubview::new(
  depth_texture_view_id~ : Int,
  depth_texture_size~ : Int,
) -> OcclusionCullingSubview {
  OcclusionCullingSubview::{
    depth_texture_view_id,
    depth_texture_size: if depth_texture_size <= 0 {
      1
    } else {
      depth_texture_size
    },
  }
}

///|
pub fn OcclusionCullingSubview::depth_texture_view_id(
  self : OcclusionCullingSubview,
) -> Int {
  self.depth_texture_view_id
}

///|
pub fn OcclusionCullingSubview::depth_texture_size(
  self : OcclusionCullingSubview,
) -> Int {
  self.depth_texture_size
}

///|
pub struct OcclusionCullingSubviewEntities {
  entity_ids : Array[Int]
} derive(Eq, Debug)

///|
pub fn OcclusionCullingSubviewEntities::new(
  entity_ids : Array[Int],
) -> OcclusionCullingSubviewEntities {
  OcclusionCullingSubviewEntities::{ entity_ids, }
}

///|
pub fn OcclusionCullingSubviewEntities::iter(
  self : OcclusionCullingSubviewEntities,
) -> Iter[Int] {
  self.entity_ids.iter()
}

///|
pub fn OcclusionCullingSubviewEntities::is_empty(
  self : OcclusionCullingSubviewEntities,
) -> Bool {
  self.entity_ids.is_empty()
}

///|
pub fn occlusion_culling_set_mesh3d_gpu_instance_builder_enabled(
  enabled : Bool,
) -> Unit {
  @render.host_gpu_set_mesh3d_gpu_instance_builder_enabled(enabled)
}

///|
pub fn occlusion_culling_mesh3d_gpu_culling_supported() -> Bool {
  @render.host_gpu_mesh3d_gpu_culling_supported()
}

///|
pub fn occlusion_culling_mesh3d_preprocess_disabled() -> Bool {
  @render.host_gpu_mesh3d_preprocess_disabled()
}

///|
pub fn occlusion_culling_mesh3d_indirect_first_instance_supported() -> Bool {
  @render.host_gpu_mesh3d_indirect_first_instance_supported()
}
