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
fn render3d_default_lighting_state() -> Render3dLightingState {
  Render3dLightingState::{
    ambient_color: @sprite.Color::white(),
    ambient_brightness: 80.0F,
    directional_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    directional_color: @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    directional_illuminance: 0.0F,
    point_entity: @core.Entity::placeholder(),
    point_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    point_color: @sprite.Color::white(),
    point_intensity: 0.0F,
    point_range: 1.0F,
    point_shadow_maps_enabled: false,
    point_shadow_depth_bias: 0.08F,
    point_shadow_map_near_z: 0.1F,
    spot_pos: @math.Vec3::new(0.0F, 0.0F, 0.0F),
    spot_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    spot_color: @sprite.Color::white(),
    spot_intensity: 0.0F,
    spot_range: 1.0F,
    spot_inner_angle: 0.6F,
    spot_outer_angle: 0.8F,
  }
}
