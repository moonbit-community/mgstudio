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

#include "../../.mooncakes/Milky2018/wgpu_mbt/src/c/wgpu_stub.h"

#include <stdlib.h>

typedef struct {
  WGPUPipelineLayoutDescriptor desc;
  WGPUBindGroupLayout layouts[3];
} mgstudio_pipeline_layout_desc_3_t;

typedef struct {
  WGPUPipelineLayoutDescriptor desc;
  WGPUBindGroupLayout layouts[4];
} mgstudio_pipeline_layout_desc_4_t;

typedef struct {
  WGPURenderPassDescriptor desc;
  WGPURenderPassDepthStencilAttachment depth;
} mgstudio_render_pass_depth_desc_t;

WGPUPipelineLayoutDescriptor *
mgstudio_pipeline_layout_descriptor_3_new(WGPUBindGroupLayout bind_group_layout0,
                                          WGPUBindGroupLayout bind_group_layout1,
                                          WGPUBindGroupLayout bind_group_layout2) {
  mgstudio_pipeline_layout_desc_3_t *out =
      (mgstudio_pipeline_layout_desc_3_t *)malloc(sizeof(mgstudio_pipeline_layout_desc_3_t));
  if (!out) {
    return NULL;
  }
  out->layouts[0] = bind_group_layout0;
  out->layouts[1] = bind_group_layout1;
  out->layouts[2] = bind_group_layout2;
  out->desc = (WGPUPipelineLayoutDescriptor){
      .nextInChain = NULL,
      .label = (WGPUStringView){.data = NULL, .length = 0},
      .bindGroupLayoutCount = 3u,
      .bindGroupLayouts = out->layouts,
  };
  return &out->desc;
}

WGPUPipelineLayoutDescriptor *
mgstudio_pipeline_layout_descriptor_4_new(WGPUBindGroupLayout bind_group_layout0,
                                          WGPUBindGroupLayout bind_group_layout1,
                                          WGPUBindGroupLayout bind_group_layout2,
                                          WGPUBindGroupLayout bind_group_layout3) {
  mgstudio_pipeline_layout_desc_4_t *out =
      (mgstudio_pipeline_layout_desc_4_t *)malloc(sizeof(mgstudio_pipeline_layout_desc_4_t));
  if (!out) {
    return NULL;
  }
  out->layouts[0] = bind_group_layout0;
  out->layouts[1] = bind_group_layout1;
  out->layouts[2] = bind_group_layout2;
  out->layouts[3] = bind_group_layout3;
  out->desc = (WGPUPipelineLayoutDescriptor){
      .nextInChain = NULL,
      .label = (WGPUStringView){.data = NULL, .length = 0},
      .bindGroupLayoutCount = 4u,
      .bindGroupLayouts = out->layouts,
  };
  return &out->desc;
}

uint32_t mgstudio_render_pipeline_descriptor_set_cull_mode(
    WGPURenderPipelineDescriptor *descriptor, uint32_t cull_mode) {
  if (!descriptor) {
    return 1u;
  }
  descriptor->primitive.cullMode = (WGPUCullMode)cull_mode;
  return 0u;
}

uint32_t mgstudio_render_pipeline_descriptor_set_vertex_module(
    WGPURenderPipelineDescriptor *descriptor, WGPUShaderModule vertex_module) {
  if (!descriptor || !vertex_module) {
    return 1u;
  }
  descriptor->vertex.module = vertex_module;
  return 0u;
}

uint32_t mgstudio_render_pipeline_descriptor_set_fragment_module(
    WGPURenderPipelineDescriptor *descriptor, WGPUShaderModule fragment_module) {
  if (!descriptor || !descriptor->fragment || !fragment_module) {
    return 1u;
  }
  // `fragment` is const in the WebGPU descriptor ABI, but the wgpu_mbt
  // descriptor builder stores it in the same mutable arena as the descriptor.
  // This setter is only used before wgpuDeviceCreateRenderPipeline consumes it.
  WGPUFragmentState *fragment = (WGPUFragmentState *)descriptor->fragment;
  fragment->module = fragment_module;
  return 0u;
}

uint32_t mgstudio_render_pipeline_descriptor_clear_fragment(
    WGPURenderPipelineDescriptor *descriptor) {
  if (!descriptor) {
    return 1u;
  }
  descriptor->fragment = NULL;
  return 0u;
}

uint32_t mgstudio_render_pipeline_descriptor_set_fragment_target_count_zero(
    WGPURenderPipelineDescriptor *descriptor) {
  if (!descriptor || !descriptor->fragment) {
    return 1u;
  }
  WGPUFragmentState *fragment = (WGPUFragmentState *)descriptor->fragment;
  fragment->targetCount = 0u;
  fragment->targets = NULL;
  return 0u;
}

WGPURenderPassDescriptor *mgstudio_render_pass_descriptor_depth_new(
    WGPUTextureView depth_view, uint32_t depth_load_op_u32,
    uint32_t depth_store_op_u32, float depth_clear_value_f32,
    uint32_t stencil_load_op_u32, uint32_t stencil_store_op_u32,
    uint32_t stencil_clear_value_u32, bool depth_read_only, bool stencil_read_only) {
  mgstudio_render_pass_depth_desc_t *out =
      (mgstudio_render_pass_depth_desc_t *)malloc(sizeof(mgstudio_render_pass_depth_desc_t));
  if (!out) {
    return NULL;
  }
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
      .colorAttachmentCount = 0u,
      .colorAttachments = NULL,
      .depthStencilAttachment = &out->depth,
      .occlusionQuerySet = NULL,
      .timestampWrites = NULL,
  };
  return &out->desc;
}

WGPUBindGroupDescriptor *
mgstudio_bind_group_descriptor_empty_new(WGPUBindGroupLayout bind_group_layout) {
  WGPUBindGroupDescriptor *out =
      (WGPUBindGroupDescriptor *)malloc(sizeof(WGPUBindGroupDescriptor));
  if (!out) {
    return NULL;
  }
  *out = (WGPUBindGroupDescriptor){
      .nextInChain = NULL,
      .label = (WGPUStringView){.data = NULL, .length = 0},
      .layout = bind_group_layout,
      .entryCount = 0u,
      .entries = NULL,
  };
  return out;
}
