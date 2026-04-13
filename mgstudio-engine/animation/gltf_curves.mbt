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
// Bevy source: `bevy/crates/bevy_animation/src/gltf_curves.rs`.
// Concrete glTF keyframe curves and interpolation decoding helpers.

///|
pub enum GltfInterpolation {
  Linear
  Step
  CubicSpline
}

///|
pub fn gltf_interpolation_from_name(
  interpolation : String?,
) -> GltfInterpolation {
  match interpolation {
    Some("STEP") => GltfInterpolation::Step
    Some("CUBICSPLINE") => GltfInterpolation::CubicSpline
    _ => GltfInterpolation::Linear
  }
}

///|
pub fn gltf_interpolation_is_step(interpolation : GltfInterpolation) -> Bool {
  match interpolation {
    GltfInterpolation::Step => true
    _ => false
  }
}

///|
pub fn gltf_interpolation_is_cubic_spline(
  interpolation : GltfInterpolation,
) -> Bool {
  match interpolation {
    GltfInterpolation::CubicSpline => true
    _ => false
  }
}

///|
fn gltf_quat_from_vec4(value : @math.Vec4) -> @math.Quat {
  @math.Quat::new(value.x, value.y, value.z, value.w).normalize()
}

///|
pub fn gltf_translation_keyframes_from_samples(
  timestamps : Array[Float],
  samples : Array[@math.Vec3],
  interpolation : GltfInterpolation,
) -> Array[KeyframeVec3]? {
  let keyframe_count = timestamps.length()
  guard keyframe_count > 0 else { return None }
  let keyframes : Array[KeyframeVec3] = []
  match interpolation {
    GltfInterpolation::Linear => {
      guard samples.length() == keyframe_count else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(KeyframeVec3::new(timestamps[i], samples[i]))
      }
      Some(keyframes)
    }
    GltfInterpolation::Step => {
      guard samples.length() == keyframe_count else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(KeyframeVec3::new_stepped(timestamps[i], samples[i]))
      }
      Some(keyframes)
    }
    GltfInterpolation::CubicSpline => {
      guard samples.length() == keyframe_count * 3 else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(
          KeyframeVec3::new_cubic(
            timestamps[i],
            samples[i * 3 + 1],
            samples[i * 3],
            samples[i * 3 + 2],
          ),
        )
      }
      Some(keyframes)
    }
  }
}

///|
pub fn gltf_rotation_keyframes_from_samples(
  timestamps : Array[Float],
  samples : Array[@math.Vec4],
  interpolation : GltfInterpolation,
) -> Array[KeyframeQuat]? {
  let keyframe_count = timestamps.length()
  guard keyframe_count > 0 else { return None }
  let keyframes : Array[KeyframeQuat] = []
  match interpolation {
    GltfInterpolation::Linear => {
      guard samples.length() == keyframe_count else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(
          KeyframeQuat::new(timestamps[i], gltf_quat_from_vec4(samples[i])),
        )
      }
      Some(keyframes)
    }
    GltfInterpolation::Step => {
      guard samples.length() == keyframe_count else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(
          KeyframeQuat::new_stepped(
            timestamps[i],
            gltf_quat_from_vec4(samples[i]),
          ),
        )
      }
      Some(keyframes)
    }
    GltfInterpolation::CubicSpline => {
      guard samples.length() == keyframe_count * 3 else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(
          KeyframeQuat::new_cubic(
            timestamps[i],
            gltf_quat_from_vec4(samples[i * 3 + 1]),
            samples[i * 3],
            samples[i * 3 + 2],
          ),
        )
      }
      Some(keyframes)
    }
  }
}

///|
fn gltf_weight_frame(
  flat_samples : Array[Float],
  base : Int,
  width : Int,
) -> Array[Float] {
  let frame : Array[Float] = []
  for i in 0..<width {
    frame.push(flat_samples[base + i])
  }
  frame
}

///|
pub fn gltf_weight_keyframes_from_flat_samples(
  timestamps : Array[Float],
  flat_samples : Array[Float],
  interpolation : GltfInterpolation,
) -> Array[KeyframeWeights]? {
  let keyframe_count = timestamps.length()
  guard keyframe_count > 0 else { return None }
  let keyframes : Array[KeyframeWeights] = []
  match interpolation {
    GltfInterpolation::Linear => {
      guard flat_samples.length() % keyframe_count == 0 else { return None }
      let width = flat_samples.length() / keyframe_count
      guard width > 0 else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(
          KeyframeWeights::new(
            timestamps[i],
            gltf_weight_frame(flat_samples, i * width, width),
          ),
        )
      }
      Some(keyframes)
    }
    GltfInterpolation::Step => {
      guard flat_samples.length() % keyframe_count == 0 else { return None }
      let width = flat_samples.length() / keyframe_count
      guard width > 0 else { return None }
      for i in 0..<keyframe_count {
        keyframes.push(
          KeyframeWeights::new_stepped(
            timestamps[i],
            gltf_weight_frame(flat_samples, i * width, width),
          ),
        )
      }
      Some(keyframes)
    }
    GltfInterpolation::CubicSpline => {
      guard flat_samples.length() % (keyframe_count * 3) == 0 else {
        return None
      }
      let width = flat_samples.length() / (keyframe_count * 3)
      guard width > 0 else { return None }
      for i in 0..<keyframe_count {
        let in_tangent_base = i * width * 3
        let value_base = in_tangent_base + width
        let out_tangent_base = in_tangent_base + width * 2
        keyframes.push(
          KeyframeWeights::new_cubic(
            timestamps[i],
            gltf_weight_frame(flat_samples, value_base, width),
            gltf_weight_frame(flat_samples, in_tangent_base, width),
            gltf_weight_frame(flat_samples, out_tangent_base, width),
          ),
        )
      }
      Some(keyframes)
    }
  }
}

///|
pub fn animation_clip_add_translation_track(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeVec3],
) -> AnimationClip {
  clip.add_translation_curve(target_id, keyframes)
}

///|
pub fn animation_clip_add_rotation_track(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeQuat],
) -> AnimationClip {
  clip.add_rotation_curve(target_id, keyframes)
}

///|
pub fn animation_clip_add_scale_track(
  clip : AnimationClip,
  target_id : AnimationTargetId,
  keyframes : Array[KeyframeVec3],
) -> AnimationClip {
  clip.add_scale_curve(target_id, keyframes)
}
