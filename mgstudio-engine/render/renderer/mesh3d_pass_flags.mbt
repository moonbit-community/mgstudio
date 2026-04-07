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
const COMPRESSED_IMAGE_FORMAT_ASTC_LDR : Int = 1

///|
const COMPRESSED_IMAGE_FORMAT_BC : Int = 2

///|
const COMPRESSED_IMAGE_FORMAT_ETC2 : Int = 4

///|
const MESH3D_TOPOLOGY_TRIANGLE_LIST : UInt = @wgpu.PRIMITIVE_TOPOLOGY_TRIANGLE_LIST

///|
const MESH3D_TOPOLOGY_LINE_LIST : UInt = @wgpu.PRIMITIVE_TOPOLOGY_LINE_LIST

///|
const MESH3D_TOPOLOGY_LINE_STRIP : UInt = @wgpu.PRIMITIVE_TOPOLOGY_LINE_STRIP

///|
fn mesh3d_topology_from_kind(kind : Int) -> UInt {
  match kind {
    1 => MESH3D_TOPOLOGY_LINE_LIST
    2 => MESH3D_TOPOLOGY_LINE_STRIP
    _ => MESH3D_TOPOLOGY_TRIANGLE_LIST
  }
}

///|
fn mesh3d_topology_suffix(topology : UInt) -> String {
  if topology == MESH3D_TOPOLOGY_LINE_LIST {
    "line_list"
  } else if topology == MESH3D_TOPOLOGY_LINE_STRIP {
    "line_strip"
  } else {
    "triangle_list"
  }
}

///|
const PASS_KIND_BASE_MASK : Int = 255

///|
const PASS_KIND_DISABLE_POSTPROCESS_FLAG : Int = 1 << 8

///|
const PASS_KIND_DISABLE_FOG_FLAG : Int = 1 << 9

///|
const PASS_KIND_DISABLE_DECAL_FLAG : Int = 1 << 10

///|
const PASS_KIND_BASE_MOTION_VECTOR : Int = 1

///|
const PASS_KIND_BASE_POINT_SHADOW : Int = 2

///|
const MESH3D_CULL_MODE_MASK : Int = 3

///|
const MESH3D_DRAW_FLAG_DECAL : Int = 1 << 8

///|
const MESH3D_DRAW_FLAG_FOG : Int = 1 << 9

///|
const MESH3D_DRAW_FLAG_POSTPROCESS_PROXY : Int = 1 << 10

///|
fn pass_kind_base_kind(pass_kind : Int) -> Int {
  pass_kind & PASS_KIND_BASE_MASK
}

///|
fn pass_kind_postprocess_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_POSTPROCESS_FLAG) == 0
}

///|
fn pass_kind_fog_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_FOG_FLAG) == 0
}

///|
fn pass_kind_decal_enabled(pass_kind : Int) -> Bool {
  (pass_kind & PASS_KIND_DISABLE_DECAL_FLAG) == 0
}

///|
fn mesh3d_draw_is_decal(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_DECAL) != 0
}

///|
fn mesh3d_draw_is_fog(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_FOG) != 0
}

///|
fn mesh3d_draw_is_postprocess_proxy(cull_mode : Int) -> Bool {
  (cull_mode & MESH3D_DRAW_FLAG_POSTPROCESS_PROXY) != 0
}

///|
fn mesh3d_cull_mode_sanitize(cull_mode : Int) -> Int {
  match cull_mode & MESH3D_CULL_MODE_MASK {
    1 => 1
    2 => 2
    _ => 0
  }
}

///|
fn mesh3d_cull_mode_wgpu(cull_mode : Int) -> UInt {
  match mesh3d_cull_mode_sanitize(cull_mode) {
    1 => @wgpu.CULL_MODE_FRONT
    2 => @wgpu.CULL_MODE_BACK
    _ => @wgpu.CULL_MODE_NONE
  }
}

///|
fn mesh3d_cull_mode_suffix(cull_mode : Int) -> String {
  match mesh3d_cull_mode_sanitize(cull_mode) {
    1 => "front"
    2 => "back"
    _ => "none"
  }
}
