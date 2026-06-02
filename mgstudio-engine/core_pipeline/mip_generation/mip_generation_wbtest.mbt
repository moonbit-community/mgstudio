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
test "mip_generation specializes downsample wgsl exactly before shader asset insertion" {
  let rgba8 = downsample_specialized_wgsl_source("rgba8unorm")
  debug_inspect(
    rgba8.contains("texture_storage_2d<rgba8unorm, write>"),
    content="true",
  )
  debug_inspect(rgba8.contains("##TEXTURE_FORMAT##"), content="false")
  let last = downsample_specialized_wgsl_source("rg11b10ufloat")
  debug_inspect(
    last.contains("texture_storage_2d<rg11b10ufloat, write>"),
    content="true",
  )
  debug_inspect(last.contains("##TEXTURE_FORMAT##"), content="false")
}
