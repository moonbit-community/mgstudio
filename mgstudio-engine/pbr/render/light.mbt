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
pub(all) struct Render3dLightingState {
  ambient_color : @sprite.Color
  ambient_brightness : Float
  directional_dir : @math.Vec3
  directional_color : @sprite.Color
  directional_illuminance : Float
  point_entity : @core.Entity?
  point_pos : @math.Vec3
  point_color : @sprite.Color
  point_intensity : Float
  point_range : Float
  point_shadow_maps_enabled : Bool
  point_shadow_depth_bias : Float
  point_shadow_map_near_z : Float
  spot_pos : @math.Vec3
  spot_dir : @math.Vec3
  spot_color : @sprite.Color
  spot_intensity : Float
  spot_range : Float
  spot_inner_angle : Float
  spot_outer_angle : Float
}

///|
pub fn render3d_default_lighting_state() -> Render3dLightingState {
  Render3dLightingState::{
    ambient_color: @sprite.Color::white(),
    ambient_brightness: 80.0F,
    directional_dir: @math.Vec3::new(0.0F, -1.0F, 0.0F),
    directional_color: @sprite.Color::new(1.0F, 1.0F, 1.0F, 1.0F),
    directional_illuminance: 0.0F,
    point_entity: None,
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

///|
pub fn render3d_collect_lighting(world : @ecs.World) -> Render3dLightingState {
  let mut lighting = render3d_default_lighting_state()
  let point_luminous_power_to_intensity = 4.0F * @math.pi()
  if (try! world.get_resource(@light.ecs_key_global_ambient_light))
    is Some(ambient) {
    lighting = Render3dLightingState::{
      ..lighting,
      ambient_color: ambient.color,
      ambient_brightness: ambient.brightness,
    }
  }
  let mut directional_found = false
  world.for_each_component(@light.ecs_key_directional_light, fn(entity, light) {
    if directional_found {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    directional_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      directional_dir: render3d_transform_forward(transform),
      directional_color: light.color,
      directional_illuminance: light.illuminance,
    }
  })
  let mut point_found = false
  world.for_each_component(@light.ecs_key_point_light, fn(entity, light) {
    if point_found {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    point_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      point_entity: Some(entity),
      point_pos: transform.translation,
      point_color: light.color,
      point_intensity: if point_luminous_power_to_intensity <= 0.0F {
        light.intensity
      } else {
        light.intensity / point_luminous_power_to_intensity
      },
      point_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
      point_shadow_maps_enabled: light.shadow_maps_enabled,
      point_shadow_depth_bias: light.shadow_depth_bias,
      point_shadow_map_near_z: if light.shadow_map_near_z > 0.0001F {
        light.shadow_map_near_z
      } else {
        0.0001F
      },
    }
  })
  let mut spot_found = false
  world.for_each_component(@light.ecs_key_spot_light, fn(entity, light) {
    if spot_found {
      return
    }
    let transform = match
      (try! world.get_by_key(entity, @transform.ecs_key_transform)) {
      Some(value) => value
      None => @transform.Transform::identity()
    }
    let inner = light.inner_angle
    let mut outer = light.outer_angle
    if outer < inner {
      outer = inner
    }
    spot_found = true
    lighting = Render3dLightingState::{
      ..lighting,
      spot_pos: transform.translation,
      spot_dir: render3d_transform_forward(transform),
      spot_color: light.color,
      spot_intensity: if point_luminous_power_to_intensity <= 0.0F {
        light.intensity
      } else {
        light.intensity / point_luminous_power_to_intensity
      },
      spot_range: if light.range > 0.0F {
        light.range
      } else {
        1.0F
      },
      spot_inner_angle: inner,
      spot_outer_angle: outer,
    }
  })
  lighting
}

///|
pub fn render3d_point_shadow_face_transform(
  light_position : @math.Vec3,
  face_index : Int,
) -> @transform.Transform {
  let (forward, up) = match face_index {
    // Match Bevy's `CUBE_MAP_FACES` exactly:
    // [+X, -X, +Y, -Y, +Z, -Z] face order with left-handed cubemap conventions.
    0 => (@math.Vec3::new(1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    1 => (@math.Vec3::new(-1.0F, 0.0F, 0.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    2 => (@math.Vec3::new(0.0F, 1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, 1.0F))
    3 =>
      (@math.Vec3::new(0.0F, -1.0F, 0.0F), @math.Vec3::new(0.0F, 0.0F, -1.0F))
    4 => (@math.Vec3::new(0.0F, 0.0F, -1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
    _ => (@math.Vec3::new(0.0F, 0.0F, 1.0F), @math.Vec3::new(0.0F, 1.0F, 0.0F))
  }
  @transform.Transform::from_xyz(
    light_position.x,
    light_position.y,
    light_position.z,
  ).looking_at(light_position.add(forward), up)
}
