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
test "color target state carries bevy-shaped blend state" {
  let blend = BlendState::BlendState(
    color=BlendComponent::BlendComponent(
      src_factor=@wgpu.BLEND_FACTOR_DST,
      dst_factor=@wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
      operation=@wgpu.BLEND_OPERATION_ADD,
    ),
    alpha=BlendComponent::over(),
  )
  let target = ColorTargetState::new(
    @wgpu.TEXTURE_FORMAT_RGBA8_UNORM,
    @wgpu.COLOR_WRITE_MASK_ALL,
    blend=Some(blend),
  )
  guard target.blend() is Some(state) else {
    abort("expected color target blend state")
  }
  debug_inspect(
    state.color().src_factor() == @wgpu.BLEND_FACTOR_DST,
    content="true",
  )
  debug_inspect(
    state.color().dst_factor() == @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
    content="true",
  )
  debug_inspect(
    state.alpha().src_factor() == @wgpu.BLEND_FACTOR_ONE,
    content="true",
  )
  debug_inspect(
    state.alpha().dst_factor() == @wgpu.BLEND_FACTOR_ONE_MINUS_SRC_ALPHA,
    content="true",
  )
}
