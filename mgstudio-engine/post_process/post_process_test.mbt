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
test "post_process boundary re-exports bloom and tonemapping APIs" {
  let bloom = @post_process.Bloom::default()
  inspect(bloom.max_mip_dimension, content="512")
  let tonemapping = @post_process.Tonemapping::default()
  inspect(
    tonemapping.to_json().to_string(),
    content="String(\"TonyMcMapface\")",
  )
  inspect(@post_process.DebandDither::default() == Disabled, content="true")
}

///|
test "post_process boundary re-exports fxaa and ssao APIs" {
  let fxaa = @post_process.Fxaa::default()
  inspect(fxaa.enabled, content="true")
  let ssao = @post_process.ScreenSpaceAmbientOcclusion::default()
  inspect(ssao.constant_object_thickness.to_double(), content="0.25")
}
