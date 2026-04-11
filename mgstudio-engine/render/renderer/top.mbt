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
/// Minimal native GPU backend for `mgstudio_host` built on `Milky2018/wgpu_mbt`.
///
/// This is intentionally small and incremental:
/// - supports surface frame begin/end + a single render pass
/// - supports textured sprite quads (alpha blending)
/// - supports solid-color mesh draw for rectangle/capsule meshes
///
/// Missing capabilities should be tracked in project issues and reported upstream.
