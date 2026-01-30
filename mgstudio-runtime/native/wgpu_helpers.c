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

// Extra native helpers for mgstudio runtime on top of wgpu_mbt.
//
// wgpu_mbt 0.2.x ships:
//   - mbt_wgpu_render_pipeline_descriptor_color_format_new (NO blending)
//   - mbt_wgpu_render_pipeline_descriptor_rgba8_alpha_blend_new (RGBA8 only)
//
// mgstudio needs "alpha blending + arbitrary surface format". We implement it
// by reusing the alpha-blend descriptor and overriding the target format.

#include <stdint.h>

#include "webgpu.h"

// Provided by Milky2018/wgpu_mbt (wgpu_stub_descs_pipelines.c).
WGPURenderPipelineDescriptor *mbt_wgpu_render_pipeline_descriptor_rgba8_alpha_blend_new(
    WGPUPipelineLayout layout,
    WGPUShaderModule shader_module);

// Exported for MoonBit FFI.
WGPURenderPipelineDescriptor *mgstudio_wgpu_render_pipeline_descriptor_color_format_alpha_blend_new(
    WGPUPipelineLayout layout,
    WGPUShaderModule shader_module,
    uint32_t format_u32) {
  WGPURenderPipelineDescriptor *desc =
      mbt_wgpu_render_pipeline_descriptor_rgba8_alpha_blend_new(layout, shader_module);
  if (!desc || !desc->fragment || !desc->fragment->targets) {
    return NULL;
  }
  desc->fragment->targets[0].format = (WGPUTextureFormat)format_u32;
  return desc;
}

