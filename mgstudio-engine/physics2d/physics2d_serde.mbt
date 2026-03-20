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
const ACTIVE_COLLISION_TYPES_ALL_BITS : Int = 0xEE2F

///|
fn json_get(parts : Array[Json], index : Int, fallback : Json) -> Json {
  if parts.length() > index {
    parts[index]
  } else {
    fallback
  }
}

///|
fn entity_to_json(entity : @core.Entity) -> Json {
  (entity.id, entity.generation).to_json()
}

///|
fn entity_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @core.Entity raise @json.JsonDecodeError {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  @core.Entity::new(id, generation)
}

///|
fn entity_option_to_json(entity : @core.Entity?) -> Json {
  match entity {
    Some(value) => (true, entity_to_json(value)).to_json()
    None => (false, (0).to_json()).to_json()
  }
}

///|
fn entity_option_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @core.Entity? raise @json.JsonDecodeError {
  let (present, payload) : (Bool, Json) = @json.from_json(json, path~)
  if present {
    Some(entity_from_json(payload, path))
  } else {
    None
  }
}

///|
fn rapier_vec2_to_json(v : @rapier_core.Vec2) -> Json {
  (v.x, v.y).to_json()
}

///|
fn rapier_vec2_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @rapier_core.Vec2 raise @json.JsonDecodeError {
  let (x, y) : (Float, Float) = @json.from_json(json, path~)
  @rapier_core.Vec2::new(x, y)
}

///|
fn rapier_rot2_to_json(rot : @rapier_core.Rot2) -> Json {
  rot.angle().to_json()
}

///|
fn rapier_rot2_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @rapier_core.Rot2 raise @json.JsonDecodeError {
  let angle : Float = @json.from_json(json, path~)
  @rapier_core.Rot2::from_angle(angle)
}

///|
fn rapier_iso2_to_json(iso : @rapier_core.Isometry2) -> Json {
  (rapier_vec2_to_json(iso.translation), rapier_rot2_to_json(iso.rotation)).to_json()
}

///|
fn rapier_iso2_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @rapier_core.Isometry2 raise @json.JsonDecodeError {
  let (translation_json, rotation_json) : (Json, Json) = @json.from_json(
    json,
    path~,
  )
  @rapier_core.Isometry2::new(
    rapier_vec2_from_json(translation_json, path),
    rapier_rot2_from_json(rotation_json, path),
  )
}

///|
fn rapier_mass_properties_to_json(props : @rapier_core.MassProperties) -> Json {
  (props.mass, props.inertia, rapier_vec2_to_json(props.center_of_mass)).to_json()
}

///|
fn rapier_mass_properties_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @rapier_core.MassProperties raise @json.JsonDecodeError {
  let (mass, inertia, center_of_mass_json) : (Float, Float, Json) = @json.from_json(
    json,
    path~,
  )
  @rapier_core.MassProperties::new(
    mass,
    inertia,
    rapier_vec2_from_json(center_of_mass_json, path),
  )
}

///|
fn rigid_body_type_to_json(body_type : @dynamics.RigidBodyType) -> Json {
  match body_type {
    @dynamics.RigidBodyType::Dynamic => "dynamic".to_json()
    @dynamics.RigidBodyType::Fixed => "fixed".to_json()
    @dynamics.RigidBodyType::KinematicPositionBased =>
      "kinematic_position_based".to_json()
    @dynamics.RigidBodyType::KinematicVelocityBased =>
      "kinematic_velocity_based".to_json()
  }
}

///|
fn rigid_body_type_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.RigidBodyType raise @json.JsonDecodeError {
  let tag : String = @json.from_json(json, path~)
  if tag == "fixed" {
    @dynamics.RigidBodyType::Fixed
  } else if tag == "kinematic_position_based" {
    @dynamics.RigidBodyType::KinematicPositionBased
  } else if tag == "kinematic_velocity_based" {
    @dynamics.RigidBodyType::KinematicVelocityBased
  } else {
    @dynamics.RigidBodyType::Dynamic
  }
}

///|
fn combine_rule_to_json(rule : @dynamics.CoefficientCombineRule) -> Json {
  match rule {
    @dynamics.CoefficientCombineRule::Average => "average".to_json()
    @dynamics.CoefficientCombineRule::Min => "min".to_json()
    @dynamics.CoefficientCombineRule::Multiply => "multiply".to_json()
    @dynamics.CoefficientCombineRule::Max => "max".to_json()
    @dynamics.CoefficientCombineRule::ClampedSum => "clamped_sum".to_json()
  }
}

///|
fn combine_rule_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.CoefficientCombineRule raise @json.JsonDecodeError {
  let tag : String = @json.from_json(json, path~)
  if tag == "min" {
    @dynamics.CoefficientCombineRule::Min
  } else if tag == "multiply" {
    @dynamics.CoefficientCombineRule::Multiply
  } else if tag == "max" {
    @dynamics.CoefficientCombineRule::Max
  } else if tag == "clamped_sum" {
    @dynamics.CoefficientCombineRule::ClampedSum
  } else {
    @dynamics.CoefficientCombineRule::Average
  }
}

///|
fn interaction_test_mode_to_json(mode : @dynamics.InteractionTestMode) -> Json {
  match mode {
    @dynamics.InteractionTestMode::And => "and".to_json()
    @dynamics.InteractionTestMode::Or => "or".to_json()
  }
}

///|
fn interaction_test_mode_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.InteractionTestMode raise @json.JsonDecodeError {
  let tag : String = @json.from_json(json, path~)
  if tag == "or" {
    @dynamics.InteractionTestMode::Or
  } else {
    @dynamics.InteractionTestMode::And
  }
}

///|
fn active_collision_types_to_json(
  types : @collision.ActiveCollisionTypes,
) -> Json {
  types.value.to_json()
}

///|
fn active_collision_types_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ActiveCollisionTypes raise @json.JsonDecodeError {
  let bits : Int = @json.from_json(json, path~)
  if bits == ACTIVE_COLLISION_TYPES_ALL_BITS {
    @collision.ActiveCollisionTypes::all()
  } else {
    @collision.ActiveCollisionTypes::default()
  }
}

///|
fn active_events_to_json(events : @collision.ActiveEvents) -> Json {
  let mut bits = 0
  if events.contains(@collision.ActiveEvents::collision_events()) {
    bits = bits | (1 << 0)
  }
  if events.contains(@collision.ActiveEvents::contact_force_events()) {
    bits = bits | (1 << 1)
  }
  if events.contains(@collision.ActiveEvents::intersection_events()) {
    bits = bits | (1 << 2)
  }
  bits.to_json()
}

///|
fn active_events_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ActiveEvents raise @json.JsonDecodeError {
  let bits : Int = @json.from_json(json, path~)
  @collision.ActiveEvents::from_bits_retain(bits)
}

///|
fn active_hooks_to_json(hooks : @collision.ActiveHooks) -> Json {
  let mut bits = 0
  if hooks.contains(@collision.ActiveHooks::filter_contact_pairs()) {
    bits = bits | (1 << 0)
  }
  if hooks.contains(@collision.ActiveHooks::filter_intersection_pair()) {
    bits = bits | (1 << 1)
  }
  if hooks.contains(@collision.ActiveHooks::modify_solver_contacts()) {
    bits = bits | (1 << 2)
  }
  bits.to_json()
}

///|
fn active_hooks_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ActiveHooks raise @json.JsonDecodeError {
  let bits : Int = @json.from_json(json, path~)
  @collision.ActiveHooks::from_bits_retain(bits)
}

///|
fn rigid_body_handle_to_json(handle : @dynamics.RigidBodyHandle) -> Json {
  handle.into_raw_parts().to_json()
}

///|
fn rigid_body_handle_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.RigidBodyHandle raise @json.JsonDecodeError {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  @dynamics.RigidBodyHandle::from_raw_parts(id, generation)
}

///|
fn collider_handle_to_json(handle : @collision.ColliderHandle) -> Json {
  handle.into_raw_parts().to_json()
}

///|
fn collider_handle_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.ColliderHandle raise @json.JsonDecodeError {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  @collision.ColliderHandle::from_raw_parts(id, generation)
}

///|
fn impulse_joint_handle_to_json(handle : @dynamics.ImpulseJointHandle) -> Json {
  handle.into_raw_parts().to_json()
}

///|
fn impulse_joint_handle_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.ImpulseJointHandle raise @json.JsonDecodeError {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  @dynamics.ImpulseJointHandle::from_raw_parts(id, generation)
}

///|
fn multibody_joint_handle_to_json(
  handle : @dynamics.MultibodyJointHandle,
) -> Json {
  handle.into_raw_parts().to_json()
}

///|
fn multibody_joint_handle_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.MultibodyJointHandle raise @json.JsonDecodeError {
  let (id, generation) : (Int, Int) = @json.from_json(json, path~)
  @dynamics.MultibodyJointHandle::from_raw_parts(id, generation)
}

///|
fn joint_axes_mask_to_json(mask : @dynamics.JointAxesMask) -> Json {
  mask.bits().to_json()
}

///|
fn joint_axes_mask_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.JointAxesMask raise @json.JsonDecodeError {
  let bits : Int = @json.from_json(json, path~)
  @dynamics.JointAxesMask::new(bits)
}

///|
fn spring_coefficients_to_json(coeff : @dynamics.SpringCoefficients) -> Json {
  (coeff.natural_frequency, coeff.damping_ratio).to_json()
}

///|
fn spring_coefficients_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.SpringCoefficients raise @json.JsonDecodeError {
  let (natural_frequency, damping_ratio) : (Float, Float) = @json.from_json(
    json,
    path~,
  )
  @dynamics.SpringCoefficients::new(natural_frequency, damping_ratio)
}

///|
fn motor_model_to_json(model : @dynamics.MotorModel) -> Json {
  match model {
    @dynamics.MotorModel::AccelerationBased => "acceleration_based".to_json()
    @dynamics.MotorModel::ForceBased => "force_based".to_json()
  }
}

///|
fn motor_model_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.MotorModel raise @json.JsonDecodeError {
  let tag : String = @json.from_json(json, path~)
  if tag == "force_based" {
    @dynamics.MotorModel::ForceBased
  } else {
    @dynamics.MotorModel::AccelerationBased
  }
}

///|
fn joint_enabled_to_json(enabled : @dynamics.JointEnabled) -> Json {
  match enabled {
    @dynamics.JointEnabled::Enabled => "enabled".to_json()
    @dynamics.JointEnabled::Disabled => "disabled".to_json()
    @dynamics.JointEnabled::DisabledByAttachedBody =>
      "disabled_by_attached_body".to_json()
  }
}

///|
fn joint_enabled_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.JointEnabled raise @json.JsonDecodeError {
  let tag : String = @json.from_json(json, path~)
  if tag == "disabled" {
    @dynamics.JointEnabled::Disabled
  } else if tag == "disabled_by_attached_body" {
    @dynamics.JointEnabled::DisabledByAttachedBody
  } else {
    @dynamics.JointEnabled::Enabled
  }
}

///|
fn joint_limits_to_json(limit : @dynamics.JointLimits) -> Json {
  (limit.min(), limit.max(), limit.impulse()).to_json()
}

///|
fn joint_limits_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.JointLimits raise @json.JsonDecodeError {
  let (min, max, impulse) : (Float, Float, Float) = @json.from_json(json, path~)
  @dynamics.JointLimits::new(min, max).set_impulse(impulse)
}

///|
fn joint_motor_to_json(motor : @dynamics.JointMotor) -> Json {
  (
    motor.target_vel,
    motor.target_pos,
    motor.stiffness,
    motor.damping,
    motor.max_force,
    motor.impulse(),
    motor_model_to_json(motor.model),
  ).to_json()
}

///|
fn joint_motor_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.JointMotor raise @json.JsonDecodeError {
  let (
    target_vel,
    target_pos,
    stiffness,
    damping,
    max_force,
    impulse,
    model_json,
  ) : (Float, Float, Float, Float, Float, Float, Json) = @json.from_json(
    json,
    path~,
  )
  @dynamics.JointMotor::default()
  .set_target_vel(target_vel)
  .set_target_pos(target_pos)
  .set_stiffness(stiffness)
  .set_damping(damping)
  .set_max_force(max_force)
  .set_impulse(impulse)
  .set_model(motor_model_from_json(model_json, path))
}

///|
fn joint_motor_option_to_json(motor : @dynamics.JointMotor?) -> Json {
  match motor {
    Some(value) => (true, joint_motor_to_json(value)).to_json()
    None => (false, (0).to_json()).to_json()
  }
}

///|
fn joint_motor_option_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.JointMotor? raise @json.JsonDecodeError {
  let (present, payload) : (Bool, Json) = @json.from_json(json, path~)
  if present {
    Some(joint_motor_from_json(payload, path))
  } else {
    None
  }
}

///|
fn joint_limits_option_to_json(limit : @dynamics.JointLimits?) -> Json {
  match limit {
    Some(value) => (true, joint_limits_to_json(value)).to_json()
    None => (false, (0).to_json()).to_json()
  }
}

///|
fn joint_limits_option_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.JointLimits? raise @json.JsonDecodeError {
  let (present, payload) : (Bool, Json) = @json.from_json(json, path~)
  if present {
    Some(joint_limits_from_json(payload, path))
  } else {
    None
  }
}

///|
fn character_length_to_json(length : @control.CharacterLength) -> Json {
  match length {
    @control.CharacterLength::Absolute(value) => ("absolute", value).to_json()
    @control.CharacterLength::Relative(value) => ("relative", value).to_json()
  }
}

///|
fn character_length_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @control.CharacterLength raise @json.JsonDecodeError {
  let (tag, value) : (String, Float) = @json.from_json(json, path~)
  if tag == "absolute" {
    @control.CharacterLength::absolute(value)
  } else {
    @control.CharacterLength::relative(value)
  }
}

///|
fn character_length_option_to_json(length : @control.CharacterLength?) -> Json {
  match length {
    Some(value) => (true, character_length_to_json(value)).to_json()
    None => (false, (0).to_json()).to_json()
  }
}

///|
fn character_length_option_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @control.CharacterLength? raise @json.JsonDecodeError {
  let (present, payload) : (Bool, Json) = @json.from_json(json, path~)
  if present {
    Some(character_length_from_json(payload, path))
  } else {
    None
  }
}

///|
fn character_autostep_to_json(autostep : @control.CharacterAutostep) -> Json {
  (
    character_length_to_json(autostep.max_height()),
    character_length_to_json(autostep.min_width()),
    autostep.include_dynamic_bodies(),
  ).to_json()
}

///|
fn character_autostep_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @control.CharacterAutostep raise @json.JsonDecodeError {
  let (max_height_json, min_width_json, include_dynamic_bodies) : (
    Json,
    Json,
    Bool,
  ) = @json.from_json(json, path~)
  @control.CharacterAutostep::new(
    character_length_from_json(max_height_json, path),
    character_length_from_json(min_width_json, path),
  ).with_include_dynamic_bodies(include_dynamic_bodies)
}

///|
fn character_autostep_option_to_json(
  autostep : @control.CharacterAutostep?,
) -> Json {
  match autostep {
    Some(value) => (true, character_autostep_to_json(value)).to_json()
    None => (false, (0).to_json()).to_json()
  }
}

///|
fn character_autostep_option_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @control.CharacterAutostep? raise @json.JsonDecodeError {
  let (present, payload) : (Bool, Json) = @json.from_json(json, path~)
  if present {
    Some(character_autostep_from_json(payload, path))
  } else {
    None
  }
}

///|
fn kinematic_controller_to_json(
  controller : @control.KinematicCharacterController,
) -> Json {
  (
    rapier_vec2_to_json(controller.up),
    character_length_to_json(controller.offset),
    controller.slide,
    controller.max_slope_climb_angle,
    controller.min_slope_slide_angle,
    character_length_option_to_json(controller.snap_to_ground),
    character_autostep_option_to_json(controller.autostep),
    controller.normal_nudge_factor,
  ).to_json()
}

///|
fn kinematic_controller_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @control.KinematicCharacterController raise @json.JsonDecodeError {
  let (
    up_json,
    offset_json,
    slide,
    max_slope_climb_angle,
    min_slope_slide_angle,
    snap_to_ground_json,
    autostep_json,
    normal_nudge_factor,
  ) : (Json, Json, Bool, Float, Float, Json, Json, Float) = @json.from_json(
    json,
    path~,
  )
  @control.KinematicCharacterController::default()
  .with_up(rapier_vec2_from_json(up_json, path))
  .with_offset(character_length_from_json(offset_json, path))
  .with_slide(slide)
  .with_max_slope_climb_angle(max_slope_climb_angle)
  .with_min_slope_slide_angle(min_slope_slide_angle)
  .with_snap_to_ground(
    character_length_option_from_json(snap_to_ground_json, path),
  )
  .with_autostep(character_autostep_option_from_json(autostep_json, path))
  .with_normal_nudge_factor(normal_nudge_factor)
}

///|
fn rigid_body_additional_mass_props_to_json(
  props : @dynamics.RigidBodyAdditionalMassProps,
) -> Json {
  match props {
    @dynamics.RigidBodyAdditionalMassProps::Mass(mass) =>
      ("mass", mass.to_json()).to_json()
    @dynamics.RigidBodyAdditionalMassProps::MassProps(mass_props) =>
      ("mass_props", rapier_mass_properties_to_json(mass_props)).to_json()
    @dynamics.RigidBodyAdditionalMassProps::MassProperties(mass_properties) =>
      ("mass_properties", rapier_mass_properties_to_json(mass_properties)).to_json()
  }
}

///|
fn rigid_body_additional_mass_props_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.RigidBodyAdditionalMassProps raise @json.JsonDecodeError {
  let (tag, payload) : (String, Json) = @json.from_json(json, path~)
  match tag {
    "mass" => {
      let mass : Float = @json.from_json(payload, path~)
      @dynamics.RigidBodyAdditionalMassProps::mass(mass)
    }
    "mass_props" =>
      @dynamics.RigidBodyAdditionalMassProps::mass_props(
        rapier_mass_properties_from_json(payload, path),
      )
    "mass_properties" =>
      @dynamics.RigidBodyAdditionalMassProps::mass_properties(
        rapier_mass_properties_from_json(payload, path),
      )
    _ => @dynamics.RigidBodyAdditionalMassProps::mass(0.0F)
  }
}

///|
fn shape_vertices_to_json(vertices : Array[@rapier_core.Vec2]) -> Json {
  let result : Array[Json] = []
  for v in vertices {
    result.push(rapier_vec2_to_json(v))
  }
  result.to_json()
}

///|
fn shape_vertices_from_json(
  json : Json,
  path : @json.JsonPath,
) -> Array[@rapier_core.Vec2] raise @json.JsonDecodeError {
  let values : Array[Json] = @json.from_json(json, path~)
  let result : Array[@rapier_core.Vec2] = []
  for value in values {
    result.push(rapier_vec2_from_json(value, path))
  }
  result
}

///|
fn shape_compound_parts_to_json(
  parts : Array[(@rapier_core.Isometry2, @collision.Shape)],
) -> Json {
  let result : Array[Json] = []
  for part in parts {
    let (iso, shape) = part
    result.push((rapier_iso2_to_json(iso), shape_to_json(shape)).to_json())
  }
  result.to_json()
}

///|
fn shape_compound_parts_from_json(
  json : Json,
  path : @json.JsonPath,
) -> Array[(@rapier_core.Isometry2, @collision.Shape)] raise @json.JsonDecodeError {
  let values : Array[Json] = @json.from_json(json, path~)
  let result : Array[(@rapier_core.Isometry2, @collision.Shape)] = []
  for value in values {
    let (iso_json, shape_json) : (Json, Json) = @json.from_json(value, path~)
    result.push(
      (rapier_iso2_from_json(iso_json, path), shape_from_json(shape_json, path)),
    )
  }
  result
}

///|
fn shape_to_json(shape : @collision.Shape) -> Json {
  match shape {
    @collision.Shape::Ball(radius) => ("Ball", radius.to_json()).to_json()
    @collision.Shape::Cuboid(hx, hy) => ("Cuboid", (hx, hy).to_json()).to_json()
    @collision.Shape::HalfSpace(normal) =>
      ("HalfSpace", rapier_vec2_to_json(normal)).to_json()
    @collision.Shape::CapsuleX(half_height, radius) =>
      ("CapsuleX", (half_height, radius).to_json()).to_json()
    @collision.Shape::CapsuleY(half_height, radius) =>
      ("CapsuleY", (half_height, radius).to_json()).to_json()
    @collision.Shape::Segment(a, b) =>
      ("Segment", (rapier_vec2_to_json(a), rapier_vec2_to_json(b)).to_json()).to_json()
    @collision.Shape::Polyline(vertices, indices) =>
      ("Polyline", (shape_vertices_to_json(vertices), indices).to_json()).to_json()
    @collision.Shape::HeightField(heights, scale) =>
      ("HeightField", (heights, rapier_vec2_to_json(scale)).to_json()).to_json()
    @collision.Shape::ConvexPolygon(vertices) =>
      ("ConvexPolygon", shape_vertices_to_json(vertices)).to_json()
    @collision.Shape::TriMesh(vertices, indices) =>
      ("TriMesh", (shape_vertices_to_json(vertices), indices).to_json()).to_json()
    @collision.Shape::Compound(parts) =>
      ("Compound", shape_compound_parts_to_json(parts)).to_json()
    @collision.Shape::Round(inner, border_radius) =>
      ("Round", (shape_to_json(inner.val), border_radius).to_json()).to_json()
  }
}

///|
fn shape_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @collision.Shape raise @json.JsonDecodeError {
  let (tag, payload) : (String, Json) = @json.from_json(json, path~)
  match tag {
    "Ball" => {
      let radius : Float = @json.from_json(payload, path~)
      @collision.Shape::Ball(radius)
    }
    "Cuboid" => {
      let (hx, hy) : (Float, Float) = @json.from_json(payload, path~)
      @collision.Shape::Cuboid(hx, hy)
    }
    "HalfSpace" =>
      @collision.Shape::HalfSpace(rapier_vec2_from_json(payload, path))
    "CapsuleX" => {
      let (half_height, radius) : (Float, Float) = @json.from_json(
        payload,
        path~,
      )
      @collision.Shape::CapsuleX(half_height, radius)
    }
    "CapsuleY" => {
      let (half_height, radius) : (Float, Float) = @json.from_json(
        payload,
        path~,
      )
      @collision.Shape::CapsuleY(half_height, radius)
    }
    "Segment" => {
      let (a_json, b_json) : (Json, Json) = @json.from_json(payload, path~)
      @collision.Shape::Segment(
        rapier_vec2_from_json(a_json, path),
        rapier_vec2_from_json(b_json, path),
      )
    }
    "Polyline" => {
      let (vertices_json, indices) : (Json, Array[(Int, Int)]?) = @json.from_json(
        payload,
        path~,
      )
      @collision.Shape::Polyline(
        shape_vertices_from_json(vertices_json, path),
        indices,
      )
    }
    "HeightField" => {
      let (heights, scale_json) : (Array[Float], Json) = @json.from_json(
        payload,
        path~,
      )
      @collision.Shape::HeightField(
        heights,
        rapier_vec2_from_json(scale_json, path),
      )
    }
    "ConvexPolygon" =>
      @collision.Shape::ConvexPolygon(shape_vertices_from_json(payload, path))
    "TriMesh" => {
      let (vertices_json, indices) : (Json, Array[(Int, Int, Int)]) = @json.from_json(
        payload,
        path~,
      )
      @collision.Shape::TriMesh(
        shape_vertices_from_json(vertices_json, path),
        indices,
      )
    }
    "Compound" =>
      @collision.Shape::Compound(shape_compound_parts_from_json(payload, path))
    "Round" => {
      let (inner_json, border_radius) : (Json, Float) = @json.from_json(
        payload,
        path~,
      )
      @collision.Shape::Round(
        Ref::new(shape_from_json(inner_json, path)),
        border_radius,
      )
    }
    _ => @collision.Shape::Ball(0.0F)
  }
}

///|
fn collider_shape2d_from_rapier_shape(
  shape : @collision.Shape,
) -> ColliderShape2d {
  match shape {
    @collision.Shape::Ball(radius) => ColliderShape2d::ball(radius)
    @collision.Shape::Cuboid(hx, hy) => ColliderShape2d::cuboid(hx, hy)
    @collision.Shape::CapsuleX(half_height, radius) =>
      ColliderShape2d::capsule_x(half_height, radius)
    @collision.Shape::CapsuleY(half_height, radius) =>
      ColliderShape2d::capsule_y(half_height, radius)
    @collision.Shape::Segment(a, b) =>
      ColliderShape2d::segment(rapier_vec2_to_mg(a), rapier_vec2_to_mg(b))
    @collision.Shape::Polyline(vertices, indices) => {
      let out_vertices : Array[@math.Vec2] = []
      for v in vertices {
        out_vertices.push(rapier_vec2_to_mg(v))
      }
      ColliderShape2d::polyline(out_vertices, indices~)
    }
    @collision.Shape::ConvexPolygon(vertices) => {
      let out_vertices : Array[@math.Vec2] = []
      for v in vertices {
        out_vertices.push(rapier_vec2_to_mg(v))
      }
      ColliderShape2d::convex_polygon(out_vertices)
    }
    @collision.Shape::TriMesh(vertices, indices) => {
      let out_vertices : Array[@math.Vec2] = []
      for v in vertices {
        out_vertices.push(rapier_vec2_to_mg(v))
      }
      ColliderShape2d::trimesh(out_vertices, indices)
    }
    @collision.Shape::Compound(parts) => {
      let out_parts : Array[(@transform.Transform, ColliderShape2d)] = []
      for part in parts {
        let (iso, part_shape) = part
        out_parts.push(
          (
            iso2_to_mg_transform(iso, 0.0F),
            collider_shape2d_from_rapier_shape(part_shape),
          ),
        )
      }
      ColliderShape2d::compound(out_parts)
    }
    _ => ColliderShape2d::raw(shape)
  }
}

///|
fn generic_joint_to_json(joint : @dynamics.GenericJoint) -> Json {
  let limits = joint.limits()
  let motors = joint.motors()
  (
    rapier_iso2_to_json(joint.local_frame1()),
    rapier_iso2_to_json(joint.local_frame2()),
    joint_axes_mask_to_json(joint.locked_axes()),
    joint_axes_mask_to_json(joint.limit_axes()),
    joint_axes_mask_to_json(joint.motor_axes()),
    joint_axes_mask_to_json(joint.coupled_axes()),
    joint_limits_to_json(limits.lin_x),
    joint_limits_to_json(limits.lin_y),
    joint_limits_to_json(limits.ang_z),
    joint_motor_to_json(motors.lin_x),
    joint_motor_to_json(motors.lin_y),
    joint_motor_to_json(motors.ang_z),
    spring_coefficients_to_json(joint.softness()),
    joint.contacts_enabled().to_json(),
    joint_enabled_to_json(joint.enabled),
    joint.user_data.to_json(),
  ).to_json()
}

///|
fn generic_joint_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.GenericJoint raise @json.JsonDecodeError {
  let parts : Array[Json] = @json.from_json(json, path~)
  let mut joint = @dynamics.GenericJoint::new(
    joint_axes_mask_from_json(json_get(parts, 2, (0).to_json()), path),
  )
  joint = joint.set_local_frame1(
    rapier_iso2_from_json(json_get(parts, 0, (0).to_json()), path),
  )
  joint = joint.set_local_frame2(
    rapier_iso2_from_json(json_get(parts, 1, (0).to_json()), path),
  )
  joint = joint.set_locked_axes(
    joint_axes_mask_from_json(json_get(parts, 2, (0).to_json()), path),
  )
  joint = joint.set_limit_axes(
    joint_axes_mask_from_json(json_get(parts, 3, (0).to_json()), path),
  )
  joint = joint.set_motor_axes(
    joint_axes_mask_from_json(json_get(parts, 4, (0).to_json()), path),
  )
  joint = joint.set_coupled_axes(
    joint_axes_mask_from_json(json_get(parts, 5, (0).to_json()), path),
  )

  let lin_x_limit = joint_limits_from_json(
    json_get(parts, 6, (0).to_json()),
    path,
  )
  let lin_y_limit = joint_limits_from_json(
    json_get(parts, 7, (0).to_json()),
    path,
  )
  let ang_z_limit = joint_limits_from_json(
    json_get(parts, 8, (0).to_json()),
    path,
  )
  joint = joint.set_limits_axis(
    @dynamics.JointAxis::LinX,
    lin_x_limit.min(),
    lin_x_limit.max(),
  )
  joint = joint.set_limits_axis(
    @dynamics.JointAxis::LinY,
    lin_y_limit.min(),
    lin_y_limit.max(),
  )
  joint = joint.set_limits_axis(
    @dynamics.JointAxis::AngZ,
    ang_z_limit.min(),
    ang_z_limit.max(),
  )

  let lin_x_motor = joint_motor_from_json(
    json_get(parts, 9, (0).to_json()),
    path,
  )
  let lin_y_motor = joint_motor_from_json(
    json_get(parts, 10, (0).to_json()),
    path,
  )
  let ang_z_motor = joint_motor_from_json(
    json_get(parts, 11, (0).to_json()),
    path,
  )
  joint = joint
    .set_motor_position(
      @dynamics.JointAxis::LinX,
      lin_x_motor.target_pos,
      lin_x_motor.stiffness,
      lin_x_motor.damping,
    )
    .set_motor_velocity(
      @dynamics.JointAxis::LinX,
      lin_x_motor.target_vel,
      lin_x_motor.damping,
    )
    .set_motor_max_force(@dynamics.JointAxis::LinX, lin_x_motor.max_force)
    .set_motor_model(@dynamics.JointAxis::LinX, lin_x_motor.model)

  joint = joint
    .set_motor_position(
      @dynamics.JointAxis::LinY,
      lin_y_motor.target_pos,
      lin_y_motor.stiffness,
      lin_y_motor.damping,
    )
    .set_motor_velocity(
      @dynamics.JointAxis::LinY,
      lin_y_motor.target_vel,
      lin_y_motor.damping,
    )
    .set_motor_max_force(@dynamics.JointAxis::LinY, lin_y_motor.max_force)
    .set_motor_model(@dynamics.JointAxis::LinY, lin_y_motor.model)

  joint = joint
    .set_motor_position(
      @dynamics.JointAxis::AngZ,
      ang_z_motor.target_pos,
      ang_z_motor.stiffness,
      ang_z_motor.damping,
    )
    .set_motor_velocity(
      @dynamics.JointAxis::AngZ,
      ang_z_motor.target_vel,
      ang_z_motor.damping,
    )
    .set_motor_max_force(@dynamics.JointAxis::AngZ, ang_z_motor.max_force)
    .set_motor_model(@dynamics.JointAxis::AngZ, ang_z_motor.model)

  joint = joint.set_softness(
    spring_coefficients_from_json(json_get(parts, 12, (0).to_json()), path),
  )
  let contacts_enabled : Bool = @json.from_json(
    json_get(parts, 13, true.to_json()),
    path~,
  )
  joint = joint.set_contacts_enabled(contacts_enabled)

  let enabled = joint_enabled_from_json(
    json_get(parts, 14, "enabled".to_json()),
    path,
  )
  match enabled {
    @dynamics.JointEnabled::Enabled => joint = joint.set_enabled(true)
    @dynamics.JointEnabled::Disabled => joint = joint.set_enabled(false)
    @dynamics.JointEnabled::DisabledByAttachedBody => {
      joint = joint.set_enabled(true)
      joint = joint.set_enabled_by_attached_body(false)
    }
  }
  joint
}

///|
fn revolute_joint_to_json(joint : @dynamics.RevoluteJoint) -> Json {
  (
    rapier_vec2_to_json(joint.local_anchor1()),
    rapier_vec2_to_json(joint.local_anchor2()),
    spring_coefficients_to_json(joint.softness()),
    joint_motor_option_to_json(joint.motor()),
    joint_limits_option_to_json(joint.limits()),
  ).to_json()
}

///|
fn revolute_joint_from_json(
  json : Json,
  path : @json.JsonPath,
) -> @dynamics.RevoluteJoint raise @json.JsonDecodeError {
  let (anchor1_json, anchor2_json, softness_json, motor_json, limits_json) : (
    Json,
    Json,
    Json,
    Json,
    Json,
  ) = @json.from_json(json, path~)
  let mut builder = @dynamics.RevoluteJointBuilder::new()
    .local_anchor1(rapier_vec2_from_json(anchor1_json, path))
    .local_anchor2(rapier_vec2_from_json(anchor2_json, path))
    .softness(spring_coefficients_from_json(softness_json, path))

  if joint_motor_option_from_json(motor_json, path) is Some(motor_data) {
    builder = builder
      .motor_model(motor_data.model)
      .motor_position(
        motor_data.target_pos,
        motor_data.stiffness,
        motor_data.damping,
      )
      .motor_velocity(motor_data.target_vel, motor_data.damping)
      .motor_max_force(motor_data.max_force)
  }

  if joint_limits_option_from_json(limits_json, path) is Some(limits_data) {
    builder = builder.limits(limits_data.min(), limits_data.max())
  }

  builder.build()
}

///|
pub impl ToJson for RigidBody2d with to_json(self) {
  rigid_body_type_to_json(self.body_type)
}

///|
pub impl @json.FromJson for RigidBody2d with from_json(json, path) {
  RigidBody2d::{ body_type: rigid_body_type_from_json(json, path) }
}

///|
pub impl ToJson for ColliderShape2d with to_json(self) {
  shape_to_json(collider_shape2d_to_rapier(self))
}

///|
pub impl @json.FromJson for ColliderShape2d with from_json(json, path) {
  collider_shape2d_from_rapier_shape(shape_from_json(json, path))
}

///|
pub impl ToJson for Collider2d with to_json(self) {
  (self.shape.to_json(), self.sensor).to_json()
}

///|
pub impl @json.FromJson for Collider2d with from_json(json, path) {
  let (shape_json, sensor) : (Json, Bool) = @json.from_json(json, path~)
  Collider2d::{ shape: @json.from_json(shape_json, path~), sensor }
}

///|
pub impl ToJson for ColliderParent2d with to_json(self) {
  entity_to_json(self.parent)
}

///|
pub impl @json.FromJson for ColliderParent2d with from_json(json, path) {
  ColliderParent2d::{ parent: entity_from_json(json, path) }
}

///|
pub impl ToJson for Velocity2d with to_json(self) {
  (self.linvel, self.angvel).to_json()
}

///|
pub impl @json.FromJson for Velocity2d with from_json(json, path) {
  let (linvel, angvel) : (@math.Vec2, Float) = @json.from_json(json, path~)
  Velocity2d::{ linvel, angvel }
}

///|
pub impl ToJson for Damping2d with to_json(self) {
  (self.linear, self.angular).to_json()
}

///|
pub impl @json.FromJson for Damping2d with from_json(json, path) {
  let (linear, angular) : (Float, Float) = @json.from_json(json, path~)
  Damping2d::{ linear, angular }
}

///|
pub impl ToJson for GravityScale2d with to_json(self) {
  self.scale.to_json()
}

///|
pub impl @json.FromJson for GravityScale2d with from_json(json, path) {
  GravityScale2d::{ scale: @json.from_json(json, path~) }
}

///|
pub impl ToJson for LockedAxes2d with to_json(self) {
  (self.lock_translations, self.lock_rotations).to_json()
}

///|
pub impl @json.FromJson for LockedAxes2d with from_json(json, path) {
  let (lock_translations, lock_rotations) : (Bool, Bool) = @json.from_json(
    json,
    path~,
  )
  LockedAxes2d::{ lock_translations, lock_rotations }
}

///|
pub impl ToJson for Ccd2d with to_json(self) {
  (self.enabled, self.soft_prediction).to_json()
}

///|
pub impl @json.FromJson for Ccd2d with from_json(json, path) {
  let (enabled, soft_prediction) : (Bool, Float) = @json.from_json(json, path~)
  Ccd2d::{ enabled, soft_prediction }
}

///|
pub impl ToJson for Dominance2d with to_json(self) {
  self.group.to_json()
}

///|
pub impl @json.FromJson for Dominance2d with from_json(json, path) {
  Dominance2d::{ group: @json.from_json(json, path~) }
}

///|
pub impl ToJson for Sleeping2d with to_json(self) {
  self.sleeping.to_json()
}

///|
pub impl @json.FromJson for Sleeping2d with from_json(json, path) {
  Sleeping2d::{ sleeping: @json.from_json(json, path~) }
}

///|
pub impl ToJson for ExternalForce2d with to_json(self) {
  (self.force, self.torque).to_json()
}

///|
pub impl @json.FromJson for ExternalForce2d with from_json(json, path) {
  let (force, torque) : (@math.Vec2, Float) = @json.from_json(json, path~)
  ExternalForce2d::{ force, torque }
}

///|
pub impl ToJson for ExternalImpulse2d with to_json(self) {
  (self.impulse, self.torque_impulse).to_json()
}

///|
pub impl @json.FromJson for ExternalImpulse2d with from_json(json, path) {
  let (impulse, torque_impulse) : (@math.Vec2, Float) = @json.from_json(
    json,
    path~,
  )
  ExternalImpulse2d::{ impulse, torque_impulse }
}

///|
pub impl ToJson for ContactForceEventThreshold2d with to_json(self) {
  self.threshold.to_json()
}

///|
pub impl @json.FromJson for ContactForceEventThreshold2d with from_json(
  json,
  path,
) {
  ContactForceEventThreshold2d::{ threshold: @json.from_json(json, path~) }
}

///|
pub impl ToJson for ColliderDensity2d with to_json(self) {
  self.density.to_json()
}

///|
pub impl @json.FromJson for ColliderDensity2d with from_json(json, path) {
  ColliderDensity2d::{ density: @json.from_json(json, path~) }
}

///|
pub impl ToJson for Friction2d with to_json(self) {
  self.coefficient.to_json()
}

///|
pub impl @json.FromJson for Friction2d with from_json(json, path) {
  Friction2d::{ coefficient: @json.from_json(json, path~) }
}

///|
pub impl ToJson for FrictionCombineRule2d with to_json(self) {
  combine_rule_to_json(self.rule)
}

///|
pub impl @json.FromJson for FrictionCombineRule2d with from_json(json, path) {
  FrictionCombineRule2d::{ rule: combine_rule_from_json(json, path) }
}

///|
pub impl ToJson for Restitution2d with to_json(self) {
  self.coefficient.to_json()
}

///|
pub impl @json.FromJson for Restitution2d with from_json(json, path) {
  Restitution2d::{ coefficient: @json.from_json(json, path~) }
}

///|
pub impl ToJson for RestitutionCombineRule2d with to_json(self) {
  combine_rule_to_json(self.rule)
}

///|
pub impl @json.FromJson for RestitutionCombineRule2d with from_json(json, path) {
  RestitutionCombineRule2d::{ rule: combine_rule_from_json(json, path) }
}

///|
pub impl ToJson for CollisionGroups2d with to_json(self) {
  (self.memberships, self.filter, interaction_test_mode_to_json(self.test_mode)).to_json()
}

///|
pub impl @json.FromJson for CollisionGroups2d with from_json(json, path) {
  let (memberships, filter, test_mode_json) : (Int, Int, Json) = @json.from_json(
    json,
    path~,
  )
  CollisionGroups2d::{
    memberships,
    filter,
    test_mode: interaction_test_mode_from_json(test_mode_json, path),
  }
}

///|
pub impl ToJson for SolverGroups2d with to_json(self) {
  (self.memberships, self.filter, interaction_test_mode_to_json(self.test_mode)).to_json()
}

///|
pub impl @json.FromJson for SolverGroups2d with from_json(json, path) {
  let (memberships, filter, test_mode_json) : (Int, Int, Json) = @json.from_json(
    json,
    path~,
  )
  SolverGroups2d::{
    memberships,
    filter,
    test_mode: interaction_test_mode_from_json(test_mode_json, path),
  }
}

///|
pub impl ToJson for ColliderEnabled2d with to_json(self) {
  self.enabled.to_json()
}

///|
pub impl @json.FromJson for ColliderEnabled2d with from_json(json, path) {
  ColliderEnabled2d::{ enabled: @json.from_json(json, path~) }
}

///|
pub impl ToJson for ActiveCollisionTypes2d with to_json(self) {
  active_collision_types_to_json(self.types)
}

///|
pub impl @json.FromJson for ActiveCollisionTypes2d with from_json(json, path) {
  ActiveCollisionTypes2d::{
    types: active_collision_types_from_json(json, path),
  }
}

///|
pub impl ToJson for ActiveEvents2d with to_json(self) {
  active_events_to_json(self.events)
}

///|
pub impl @json.FromJson for ActiveEvents2d with from_json(json, path) {
  ActiveEvents2d::{ events: active_events_from_json(json, path) }
}

///|
pub impl ToJson for ActiveHooks2d with to_json(self) {
  active_hooks_to_json(self.hooks)
}

///|
pub impl @json.FromJson for ActiveHooks2d with from_json(json, path) {
  ActiveHooks2d::{ hooks: active_hooks_from_json(json, path) }
}

///|
pub impl ToJson for ContactSkin2d with to_json(self) {
  self.skin.to_json()
}

///|
pub impl @json.FromJson for ContactSkin2d with from_json(json, path) {
  ContactSkin2d::{ skin: @json.from_json(json, path~) }
}

///|
pub impl ToJson for ColliderMassProperties2d with to_json(self) {
  rapier_mass_properties_to_json(self.mass_properties)
}

///|
pub impl @json.FromJson for ColliderMassProperties2d with from_json(json, path) {
  ColliderMassProperties2d::{
    mass_properties: rapier_mass_properties_from_json(json, path),
  }
}

///|
pub impl ToJson for RigidBodyEnabled2d with to_json(self) {
  self.enabled.to_json()
}

///|
pub impl @json.FromJson for RigidBodyEnabled2d with from_json(json, path) {
  RigidBodyEnabled2d::{ enabled: @json.from_json(json, path~) }
}

///|
pub impl ToJson for AdditionalMassProperties2d with to_json(self) {
  rigid_body_additional_mass_props_to_json(self.props)
}

///|
pub impl @json.FromJson for AdditionalMassProperties2d with from_json(
  json,
  path,
) {
  AdditionalMassProperties2d::{
    props: rigid_body_additional_mass_props_from_json(json, path),
  }
}

///|
pub impl ToJson for AdditionalSolverIterations2d with to_json(self) {
  self.iterations.to_json()
}

///|
pub impl @json.FromJson for AdditionalSolverIterations2d with from_json(
  json,
  path,
) {
  AdditionalSolverIterations2d::{ iterations: @json.from_json(json, path~) }
}

///|
pub impl ToJson for RapierBodyHandle2d with to_json(self) {
  rigid_body_handle_to_json(self.handle)
}

///|
pub impl @json.FromJson for RapierBodyHandle2d with from_json(json, path) {
  RapierBodyHandle2d::{ handle: rigid_body_handle_from_json(json, path) }
}

///|
pub impl ToJson for RapierColliderHandle2d with to_json(self) {
  collider_handle_to_json(self.handle)
}

///|
pub impl @json.FromJson for RapierColliderHandle2d with from_json(json, path) {
  RapierColliderHandle2d::{ handle: collider_handle_from_json(json, path) }
}

///|
pub impl ToJson for CharacterCollision2d with to_json(self) {
  (
    entity_option_to_json(self.other),
    self.toi,
    self.point,
    self.normal,
    self.translation_applied,
    self.translation_remaining,
  ).to_json()
}

///|
pub impl @json.FromJson for CharacterCollision2d with from_json(json, path) {
  let (
    other_json,
    toi,
    point,
    normal,
    translation_applied,
    translation_remaining,
  ) : (Json, Float, @math.Vec2, @math.Vec2, @math.Vec2, @math.Vec2) = @json.from_json(
    json,
    path~,
  )
  CharacterCollision2d::{
    other: entity_option_from_json(other_json, path),
    toi,
    point,
    normal,
    translation_applied,
    translation_remaining,
  }
}

///|
pub impl ToJson for KinematicCharacterController2d with to_json(self) {
  (self.translation, kinematic_controller_to_json(self.controller)).to_json()
}

///|
pub impl @json.FromJson for KinematicCharacterController2d with from_json(
  json,
  path,
) {
  let (translation, controller_json) : (@math.Vec2, Json) = @json.from_json(
    json,
    path~,
  )
  KinematicCharacterController2d::{
    translation,
    controller: kinematic_controller_from_json(controller_json, path),
  }
}

///|
pub impl ToJson for KinematicCharacterControllerOutput2d with to_json(self) {
  (
    self.effective_translation,
    self.grounded,
    self.sliding_down_slope,
    self.collisions,
  ).to_json()
}

///|
pub impl @json.FromJson for KinematicCharacterControllerOutput2d with from_json(
  json,
  path,
) {
  let (effective_translation, grounded, sliding_down_slope, collisions) : (
    @math.Vec2,
    Bool,
    Bool,
    Array[CharacterCollision2d],
  ) = @json.from_json(json, path~)
  KinematicCharacterControllerOutput2d::{
    effective_translation,
    grounded,
    sliding_down_slope,
    collisions,
  }
}

///|
pub impl ToJson for ImpulseJoint2d with to_json(self) {
  (entity_to_json(self.other), generic_joint_to_json(self.data), self.wake_up).to_json()
}

///|
pub impl @json.FromJson for ImpulseJoint2d with from_json(json, path) {
  let (other_json, data_json, wake_up) : (Json, Json, Bool) = @json.from_json(
    json,
    path~,
  )
  ImpulseJoint2d::{
    other: entity_from_json(other_json, path),
    data: generic_joint_from_json(data_json, path),
    wake_up,
  }
}

///|
pub impl ToJson for RapierImpulseJointHandle2d with to_json(self) {
  (impulse_joint_handle_to_json(self.handle), entity_to_json(self.other)).to_json()
}

///|
pub impl @json.FromJson for RapierImpulseJointHandle2d with from_json(
  json,
  path,
) {
  let (handle_json, other_json) : (Json, Json) = @json.from_json(json, path~)
  RapierImpulseJointHandle2d::{
    handle: impulse_joint_handle_from_json(handle_json, path),
    other: entity_from_json(other_json, path),
  }
}

///|
pub impl ToJson for MultibodyJoint2d with to_json(self) {
  (
    entity_to_json(self.other),
    revolute_joint_to_json(self.data),
    self.wake_up,
    self.kinematic,
  ).to_json()
}

///|
pub impl @json.FromJson for MultibodyJoint2d with from_json(json, path) {
  let (other_json, data_json, wake_up, kinematic) : (Json, Json, Bool, Bool) = @json.from_json(
    json,
    path~,
  )
  MultibodyJoint2d::{
    other: entity_from_json(other_json, path),
    data: revolute_joint_from_json(data_json, path),
    wake_up,
    kinematic,
  }
}

///|
pub impl ToJson for RapierMultibodyJointHandle2d with to_json(self) {
  (multibody_joint_handle_to_json(self.handle), entity_to_json(self.other)).to_json()
}

///|
pub impl @json.FromJson for RapierMultibodyJointHandle2d with from_json(
  json,
  path,
) {
  let (handle_json, other_json) : (Json, Json) = @json.from_json(json, path~)
  RapierMultibodyJointHandle2d::{
    handle: multibody_joint_handle_from_json(handle_json, path),
    other: entity_from_json(other_json, path),
  }
}

///|
let physics2d_config_serde_next_id : Ref[Int] = Ref::new(1)

///|
let physics2d_config_serde_values : Map[Int, Physics2dConfig] = {}

///|
pub impl ToJson for Physics2dConfig with to_json(self) {
  let id = physics2d_config_serde_next_id.val
  physics2d_config_serde_next_id.val = id + 1
  physics2d_config_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for Physics2dConfig with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  physics2d_config_serde_values.get(id).unwrap_or(Physics2dConfig::default())
}

///|
let physics2d_events_serde_next_id : Ref[Int] = Ref::new(1)

///|
let physics2d_events_serde_values : Map[Int, Physics2dEvents] = {}

///|
pub impl ToJson for Physics2dEvents with to_json(self) {
  let id = physics2d_events_serde_next_id.val
  physics2d_events_serde_next_id.val = id + 1
  physics2d_events_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for Physics2dEvents with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  physics2d_events_serde_values.get(id).unwrap_or(Physics2dEvents::new())
}

///|
let physics2d_context_serde_next_id : Ref[Int] = Ref::new(1)

///|
let physics2d_context_serde_values : Map[Int, Physics2dContext] = {}

///|
pub impl ToJson for Physics2dContext with to_json(self) {
  let id = physics2d_context_serde_next_id.val
  physics2d_context_serde_next_id.val = id + 1
  physics2d_context_serde_values.set(id, self)
  id.to_json()
}

///|
pub impl @json.FromJson for Physics2dContext with from_json(json, path) {
  let id : Int = @json.from_json(json, path~)
  physics2d_context_serde_values.get(id).unwrap_or(Physics2dContext::new())
}
