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
fn medium_wbtest_approx_eq(a : Float, b : Float) -> Bool {
  (a - b).abs() < 0.000001F
}

///|
fn medium_wbtest_push_u32_le(out : Array[Byte], value : UInt) -> Unit {
  out.push((value & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 8) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 16) & 0xFFU).reinterpret_as_int().to_byte())
  out.push(((value >> 24) & 0xFFU).reinterpret_as_int().to_byte())
}

///|
fn medium_wbtest_push_f32_le(out : Array[Byte], value : Float) -> Unit {
  medium_wbtest_push_u32_le(out, value.reinterpret_as_uint())
}

///|
fn medium_wbtest_rgba32f_pixels(values : Array[@math.Vec4]) -> Bytes {
  let out : Array[Byte] = []
  for value in values {
    medium_wbtest_push_f32_le(out, value.x)
    medium_wbtest_push_f32_le(out, value.y)
    medium_wbtest_push_f32_le(out, value.z)
    medium_wbtest_push_f32_le(out, value.w)
  }
  Bytes::from_array(out)
}

///|
test "pbr medium: chromatic texture image resolves to chromatic curve" {
  let image_handle : @asset.Handle[@asset.Image] = @asset.Handle::new(0)
  let image = @asset.Image::new(
    2,
    1,
    medium_wbtest_rgba32f_pixels([
      @math.Vec4::new(1.0F, 2.0F, 3.0F, 0.0F),
      @math.Vec4::new(4.0F, 5.0F, 6.0F, 0.0F),
    ]),
  ).with_format(Rgba32Float)
  guard pbr_scattering_medium_chromatic_curve_from_image(image) is Some(curve) else {
    abort("expected Rgba32Float image to produce chromatic curve")
  }
  guard curve.sample(-1.0F) is Some(first) else {
    abort("expected first curve sample")
  }
  guard curve.sample(1.0F) is Some(last) else {
    abort("expected last curve sample")
  }
  inspect(medium_wbtest_approx_eq(first.x, 1.0F), content="true")
  inspect(medium_wbtest_approx_eq(first.y, 2.0F), content="true")
  inspect(medium_wbtest_approx_eq(first.z, 3.0F), content="true")
  inspect(medium_wbtest_approx_eq(last.x, 4.0F), content="true")
  inspect(medium_wbtest_approx_eq(last.y, 5.0F), content="true")
  inspect(medium_wbtest_approx_eq(last.z, 6.0F), content="true")

  let media : @asset.Assets[ScatteringMedium] = @asset.Assets::new()
  let medium_handle = media.add(
    ScatteringMedium::new(1, 2, [
      @light.ScatteringTerm::new(
        @math.Vec3::zero(),
        @math.Vec3::new(1.0F, 1.0F, 1.0F),
        @light.Falloff::linear(),
        @light.PhaseFunction::from_chromatic_texture(image_handle),
      ),
    ]),
  )
  pbr_scattering_medium_resolve_chromatic_texture(media, image_handle, curve)
  guard media.get(medium_handle) is Some(medium) else {
    abort("expected scattering medium")
  }
  guard medium.terms[0].phase is ChromaticCurve(resolved) else {
    abort("expected chromatic texture phase to resolve to chromatic curve")
  }
  guard resolved.sample(1.0F) is Some(resolved_last) else {
    abort("expected resolved curve sample")
  }
  inspect(medium_wbtest_approx_eq(resolved_last.x, 4.0F), content="true")
  inspect(medium_wbtest_approx_eq(resolved_last.y, 5.0F), content="true")
  inspect(medium_wbtest_approx_eq(resolved_last.z, 6.0F), content="true")
}
