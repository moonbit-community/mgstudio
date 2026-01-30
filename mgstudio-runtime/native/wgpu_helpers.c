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
// by constructing a descriptor with alpha blending and the requested target
// format.

#include <stdbool.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

// wgpu_mbt vendors the canonical webgpu.h under .mooncakes/.
// We include it via a relative path so building this module as a dependency
// (e.g. from mgstudio-cli) does not require extra C include flags.
#include ".mooncakes/Milky2018/wgpu_mbt/src/c/webgpu.h"

typedef struct {
  WGPURenderPipelineDescriptor desc;
  WGPUVertexState vertex;
  WGPUFragmentState fragment;
  WGPUColorTargetState color_target;
  WGPUPrimitiveState primitive;
  WGPUMultisampleState multisample;

  WGPUBlendState blend;
  WGPUBlendComponent blend_color;
  WGPUBlendComponent blend_alpha;

  char vs_entry[7];
  char fs_entry[7];
} mgstudio_render_pipeline_desc_t;

// Exported for MoonBit FFI.
WGPURenderPipelineDescriptor *mgstudio_wgpu_render_pipeline_descriptor_color_format_alpha_blend_new(
    WGPUPipelineLayout layout,
    WGPUShaderModule shader_module,
    uint32_t format_u32) {
  mgstudio_render_pipeline_desc_t *out =
      (mgstudio_render_pipeline_desc_t *)malloc(sizeof(mgstudio_render_pipeline_desc_t));
  if (!out) {
    return NULL;
  }

  memcpy(out->vs_entry, "vs_main", 7);
  memcpy(out->fs_entry, "fs_main", 7);

  out->blend_color = (WGPUBlendComponent){
      .operation = WGPUBlendOperation_Add,
      .srcFactor = WGPUBlendFactor_SrcAlpha,
      .dstFactor = WGPUBlendFactor_OneMinusSrcAlpha,
  };
  out->blend_alpha = (WGPUBlendComponent){
      .operation = WGPUBlendOperation_Add,
      .srcFactor = WGPUBlendFactor_One,
      .dstFactor = WGPUBlendFactor_OneMinusSrcAlpha,
  };
  out->blend = (WGPUBlendState){
      .color = out->blend_color,
      .alpha = out->blend_alpha,
  };

  out->vertex = (WGPUVertexState){
      .nextInChain = NULL,
      .module = shader_module,
      .entryPoint = (WGPUStringView){.data = out->vs_entry, .length = 7},
      .constantCount = 0u,
      .constants = NULL,
      .bufferCount = 0u,
      .buffers = NULL,
  };

  out->color_target = (WGPUColorTargetState){
      .nextInChain = NULL,
      .format = (WGPUTextureFormat)format_u32,
      .blend = &out->blend,
      .writeMask = WGPUColorWriteMask_All,
  };

  out->fragment = (WGPUFragmentState){
      .nextInChain = NULL,
      .module = shader_module,
      .entryPoint = (WGPUStringView){.data = out->fs_entry, .length = 7},
      .constantCount = 0u,
      .constants = NULL,
      .targetCount = 1u,
      .targets = &out->color_target,
  };

  out->primitive = (WGPUPrimitiveState){
      .nextInChain = NULL,
      .topology = WGPUPrimitiveTopology_TriangleList,
      .stripIndexFormat = WGPUIndexFormat_Undefined,
      .frontFace = WGPUFrontFace_CCW,
      .cullMode = WGPUCullMode_None,
      .unclippedDepth = 0u,
  };

  out->multisample = (WGPUMultisampleState){
      .nextInChain = NULL,
      .count = 1u,
      .mask = 0xFFFFFFFFu,
      .alphaToCoverageEnabled = 0u,
  };

  out->desc = (WGPURenderPipelineDescriptor){
      .nextInChain = NULL,
      .label = (WGPUStringView){.data = NULL, .length = 0},
      .layout = layout,
      .vertex = out->vertex,
      .primitive = out->primitive,
      .depthStencil = NULL,
      .multisample = out->multisample,
      .fragment = &out->fragment,
  };

  return &out->desc;
}
