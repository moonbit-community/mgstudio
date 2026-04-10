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
// Bridge surface is provided by `top.mbt` in this package.
pub type TextureSliceScaleMode = @sprite.SliceScaleMode

///|
pub type TextureSliceSlicer = @sprite.TextureSlicer

///|
pub fn texture_slice_slicer(border : @sprite.BorderRect) -> TextureSliceSlicer {
  TextureSliceSlicer::new(border)
}

///|
pub fn texture_slice_default_slicer() -> TextureSliceSlicer {
  TextureSliceSlicer::default()
}
