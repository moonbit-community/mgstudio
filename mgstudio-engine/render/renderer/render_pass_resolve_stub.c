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

#include <moonbit.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#include "../../.mooncakes/Milky2018/wgpu_mbt/src/c/webgpu.h"

typedef struct {
  WGPURenderPassDescriptor desc;
  WGPURenderPassColorAttachment color;
  WGPURenderPassDepthStencilAttachment depth;
} mgstudio_render_pass_desc_color_depth_t;

MOONBIT_FFI_EXPORT WGPURenderPassDescriptor *
mgstudio_render_pass_descriptor_color_depth_resolve_u32_new(
    WGPUTextureView color_view, WGPUTextureView color_resolve_view,
    uint32_t color_load_op_u32, uint32_t color_store_op_u32,
    float color_clear_r_f32, float color_clear_g_f32,
    float color_clear_b_f32, float color_clear_a_f32,
    WGPUTextureView depth_view, uint32_t depth_load_op_u32,
    uint32_t depth_store_op_u32, float depth_clear_value_f32,
    uint32_t stencil_load_op_u32, uint32_t stencil_store_op_u32,
    uint32_t stencil_clear_value_u32, bool depth_read_only,
    bool stencil_read_only) {
  mgstudio_render_pass_desc_color_depth_t *out =
      (mgstudio_render_pass_desc_color_depth_t *)malloc(
          sizeof(mgstudio_render_pass_desc_color_depth_t));
  if (out == NULL) {
    return NULL;
  }
  out->color = (WGPURenderPassColorAttachment){
      .nextInChain = NULL,
      .view = color_view,
      .depthSlice = WGPU_DEPTH_SLICE_UNDEFINED,
      .resolveTarget = color_resolve_view,
      .loadOp = (WGPULoadOp)color_load_op_u32,
      .storeOp = (WGPUStoreOp)color_store_op_u32,
      .clearValue = (WGPUColor){.r = color_clear_r_f32,
                                .g = color_clear_g_f32,
                                .b = color_clear_b_f32,
                                .a = color_clear_a_f32},
  };
  out->depth = (WGPURenderPassDepthStencilAttachment){
      .view = depth_view,
      .depthLoadOp = (WGPULoadOp)depth_load_op_u32,
      .depthStoreOp = (WGPUStoreOp)depth_store_op_u32,
      .depthClearValue = depth_clear_value_f32,
      .depthReadOnly = depth_read_only ? 1u : 0u,
      .stencilLoadOp = (WGPULoadOp)stencil_load_op_u32,
      .stencilStoreOp = (WGPUStoreOp)stencil_store_op_u32,
      .stencilClearValue = stencil_clear_value_u32,
      .stencilReadOnly = stencil_read_only ? 1u : 0u,
  };
  out->desc = (WGPURenderPassDescriptor){
      .nextInChain = NULL,
      .label = (WGPUStringView){.data = NULL, .length = 0},
      .colorAttachmentCount = 1u,
      .colorAttachments = &out->color,
      .depthStencilAttachment = &out->depth,
      .occlusionQuerySet = NULL,
      .timestampWrites = NULL,
  };
  return &out->desc;
}
