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
