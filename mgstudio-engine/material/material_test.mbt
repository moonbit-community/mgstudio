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
test "material boundary re-exports standard material APIs" {
  let material = @material.StandardMaterial::default()
    .with_metallic(0.25)
    .with_perceptual_roughness(0.75)
    .with_unlit(true)
    .with_alpha_mode(@material.AlphaMode::Blend)
  inspect(material.metallic.to_double(), content="0.25")
  inspect(material.perceptual_roughness.to_double(), content="0.75")
  inspect(material.unlit, content="true")
  inspect(material.alpha_mode is @material.AlphaMode::Blend, content="true")
}

///|
test "material boundary re-exports material metadata APIs" {
  let metadata = @material.ExtendedMaterialMetadata3d::new(7).with_disable_shadows(
    true,
  )
  let forward_ext = @material.ForwardDecalMaterialExt::new(0.5)
  let renderer_method = @material.DefaultOpaqueRendererMethod::forward()
  inspect(metadata.extension_tag, content="7")
  inspect(metadata.disable_shadows, content="true")
  inspect(forward_ext.depth_fade_factor.to_double(), content="0.5")
  inspect(
    renderer_method.renderer_method() is @material.OpaqueRendererMethod::Forward,
    content="true",
  )
}
