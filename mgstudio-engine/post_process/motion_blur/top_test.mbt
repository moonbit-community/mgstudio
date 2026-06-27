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
test "motion blur: mod owner exposes Bevy default component and uniform extract" {
  let settings = MotionBlur::MotionBlur()
  inspect(settings.shutter_angle == 0.5F, content="true")
  inspect(settings.samples, content="1")
  let uniform = settings.extract_uniform()
  inspect(uniform.shutter_angle == 0.5F, content="true")
  inspect(uniform.samples, content="1")
  inspect(motion_blur_uniform_is_active(uniform), content="true")
}

///|
test "motion blur: uniform extract clamps invalid local constructor inputs" {
  let settings = MotionBlur::new(-2.0F, -3)
  let uniform = motion_blur_extract_uniform(settings)
  inspect(uniform.shutter_angle == 0.0F, content="true")
  inspect(uniform.samples, content="0")
  inspect(motion_blur_uniform_is_active(uniform), content="false")
}

///|
test "motion blur: sample helper stays tied to component settings" {
  let disabled = motion_blur_generate_samples(MotionBlur::new(0.0F, 8))
  inspect(disabled.length(), content="0")
  let single = motion_blur_generate_samples(MotionBlur::MotionBlur())
  inspect(single.length(), content="1")
  inspect(single[0].offset == 0.0F, content="true")
  inspect(single[0].weight == 1.0F, content="true")
  let multi = motion_blur_generate_samples(MotionBlur::new(1.0F, 3))
  inspect(multi.length(), content="3")
  inspect(multi[0].offset == -0.5F, content="true")
  inspect(multi[1].offset == 0.0F, content="true")
  inspect(multi[2].offset == 0.5F, content="true")
}
